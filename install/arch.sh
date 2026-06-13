# anshul333y's arch installer script

#part1
printf '\033c'

# configure pacman | update keyring | set keyboard layout to us | enable network time sync
sed -i "s/ParallelDownloads = 5/ParallelDownloads = 13/" /etc/pacman.conf
pacman --noconfirm -Sy archlinux-keyring
loadkeys us
timedatectl set-ntp true

# partition, format and mount partitions
boot=/dev/nvme0n1p1
root=/dev/nvme0n1p2
home=/dev/nvme0n1p3
swap=/dev/nvme0n1p4
encrypt_pass=your_encrypt_password

mkfs.fat -F 32 -n boot $boot

echo "$encrypt_pass" | cryptsetup -q luksFormat --batch-mode --type luks2 $root
echo "$encrypt_pass" | cryptsetup luksOpen --batch-mode $root cryptroot
mkfs.ext4 -F -L arch /dev/mapper/cryptroot

# echo "$encrypt_pass" | cryptsetup -q luksFormat --batch-mode --type luks2 $home
echo "$encrypt_pass" | cryptsetup luksOpen --batch-mode $home crypthome
# mkfs.ext4 -F -L anshul333y /dev/mapper/crypthome

echo "$encrypt_pass" | cryptsetup -q luksFormat --batch-mode --type luks2 $swap
echo "$encrypt_pass" | cryptsetup luksOpen --batch-mode $swap cryptswap
cryptsetup luksOpen $swap cryptswap
mkswap -L swap /dev/mapper/cryptswap

# mount
mount /dev/mapper/cryptroot /mnt
mkdir -p /mnt/boot /mnt/home
mount $boot /mnt/boot
mount /dev/mapper/crypthome /mnt/home
swapon /dev/mapper/cryptswap

# install base system | generate fstab
pacstrap -K /mnt base linux linux-headers linux-firmware \
  grub efibootmgr os-prober intel-ucode mesa vulkan-intel intel-media-driver thermald power-profiles-daemon \
  networkmanager dhcpcd bluez bluez-utils pipewire pipewire-pulse
genfstab -U /mnt >>/mnt/etc/fstab

# run second stage of installer inside chroot
sed '1,/^#part2$/d' $(basename $0) >/mnt/arch2.sh
chmod +x /mnt/arch2.sh
arch-chroot /mnt /arch2.sh
exit

#part2
printf '\033c'

# set system timezone | set hardware clock | enable english locale | set system-wide locale and keymap
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >>/etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >/etc/locale.conf
echo "KEYMAP=us" >/etc/vconsole.conf

# configure pacman and mkinitcpio | set hostname | configure hosts file | generate initramfs image
sed -i "s/ParallelDownloads = 5/ParallelDownloads = 13/" /etc/pacman.conf
sed -i "s/#Color/Color/" /etc/pacman.conf
sed -i "s/filesystems/sd-encrypt filesystems resume/" /etc/mkinitcpio.conf
hostname=archlinux
echo $hostname >/etc/hostname
echo "127.0.0.1       localhost" >>/etc/hosts
echo "::1             localhost" >>/etc/hosts
echo "127.0.1.1       $hostname.localdomain $hostname" >>/etc/hosts
mkinitcpio -P

# install and configure grub with custom boot params
root_uuid=$(blkid -s UUID -o value /dev/nvme0n1p2)
sed -i 's/GRUB_DEFAULT=0/GRUB_DEFAULT=saved/' /etc/default/grub
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/' /etc/default/grub
sed -i 's/quiet/pci=noaer/' /etc/default/grub
sed -i "s|GRUB_CMDLINE_LINUX=\"\"|GRUB_CMDLINE_LINUX=\"rd.luks.name=${root_uuid}=cryptroot\"|" /etc/default/grub
sed -i 's/GRUB_TIMEOUT_STYLE=menu/GRUB_TIMEOUT_STYLE=hidden/' /etc/default/grub
sed -i 's/#GRUB_SAVEDEFAULT=true/GRUB_SAVEDEFAULT=true/' /etc/default/grub
sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch
grub-mkconfig -o /boot/grub/grub.cfg

# installing pacman packages | installing flatpak packages | enabling systemd services
pacman -S --noconfirm reflector cronie dash zsh starship stow 7zip unzip man-db ffmpeg imagemagick \
  noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra zathura zathura-pdf-mupdf \
  hyprland hyprpaper hypridle hyprlock hyprshot hyprshutdown hyprpwcenter hyprpolkitagent \
  hyprland-qt-support nwg-look rofi-wayland waybar dunst gnome-keyring xorg-xrdb \
  qt5-wayland qt6-wayland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-user-dirs \
  firefox speech-dispatcher flatpak uwsm brightnessctl acpi pacman-contrib python-pywal \
  yazi poppler resvg mpv yt-dlp python-mutagen mpd timidity++ mpc ncmpcpp rmpc cava nsxiv rsync fastfetch \
  kitty wl-clipboard zoxide eza bat tmux neovim luarocks lazygit fzf ripgrep ast-grep fd htop btop \
  base-devel rust bun nodejs npm yarn pnpm pgcli openssh git github-cli docker docker-compose
flatpak install -y flathub com.github.wwmm.easyeffects org.telegram.desktop com.discordapp.Discord
systemctl enable thermald power-profiles-daemon NetworkManager.service bluetooth.service \
  reflector.timer cronie.service

# create a new user and add to wheel group | set root and user passwords
username=anshul333y
root_pass=your_root_password
user_pass=your_user_password
useradd -m -G wheel -s /bin/zsh $username
echo "root:$root_pass" | chpasswd
echo "$username:$user_pass" | chpasswd

# auto-unlock home and swap at boot using keyfiles
encrypt_pass=your_encrypt_password
mkdir -p /etc/cryptsetup-keys.d
dd if=/dev/urandom bs=512 count=1 of=/etc/cryptsetup-keys.d/crypthome.key
dd if=/dev/urandom bs=512 count=1 of=/etc/cryptsetup-keys.d/cryptswap.key
chmod 600 /etc/cryptsetup-keys.d/crypthome.key
chmod 600 /etc/cryptsetup-keys.d/cryptswap.key
echo "$encrypt_pass" | cryptsetup luksAddKey --batch-mode /dev/nvme0n1p3 /etc/cryptsetup-keys.d/crypthome.key
echo "$encrypt_pass" | cryptsetup luksAddKey --batch-mode /dev/nvme0n1p4 /etc/cryptsetup-keys.d/cryptswap.key
echo "crypthome  UUID=$(blkid -s UUID -o value /dev/nvme0n1p3)  /etc/cryptsetup-keys.d/crypthome.key  luks" >>/etc/crypttab
echo "cryptswap  UUID=$(blkid -s UUID -o value /dev/nvme0n1p4)  /etc/cryptsetup-keys.d/cryptswap.key  luks" >>/etc/crypttab

# configure sudo | configure zsh | configure reflector
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers
echo 'export ZDOTDIR="$HOME/.config/zsh"' >>/etc/zsh/zshenv
sed -i "s/5/13/" /etc/xdg/reflector/reflector.conf
sed -i "s/age/rate/" /etc/xdg/reflector/reflector.conf

# auto-login | unlock and auto-start the gnome keyring at login | charging and discharging notifications
sed -i "s/#HandlePowerKey=poweroff/HandlePowerKey=ignore/" /etc/systemd/logind.conf
mkdir -p /etc/systemd/system/getty@tty1.service.d
echo "[Service]" >>/etc/systemd/system/getty@tty1.service.d/autologin.conf
echo "ExecStart=" >>/etc/systemd/system/getty@tty1.service.d/autologin.conf
echo "ExecStart=-/sbin/agetty --autologin anshul333y --noclear %I $TERM" >>/etc/systemd/system/getty@tty1.service.d/autologin.conf
sed -i "/auth       include      system-local-login/a auth       optional     pam_gnome_keyring.so" /etc/pam.d/login
sed -i "/session    include      system-local-login/a session    optional     pam_gnome_keyring.so auto_start" /etc/pam.d/login
echo 'ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", ENV{DISPLAY}=":0", ENV{XAUTHORITY}="/home/anshul333y/.Xauthority" RUN+="/usr/bin/su anshul333y -c '\''/home/anshul333y/.local/bin/notify/notify-battery-charging discharging'\''"' >>/etc/udev/rules.d/power.rules
echo 'ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", ENV{DISPLAY}=":0", ENV{XAUTHORITY}="/home/anshul333y/.Xauthority" RUN+="/usr/bin/su anshul333y -c '\''/home/anshul333y/.local/bin/notify/notify-battery-charging charging'\''"' >>/etc/udev/rules.d/power.rules

# run third stage of installer as user
arch3_path=/home/$username/arch3.sh
sed '1,/^#part3$/d' /arch2.sh >$arch3_path
chown $username:$username $arch3_path
chmod +x $arch3_path
su -c $arch3_path -s /bin/sh $username
exit

#part3
printf '\033c'

# creating user-dirs | installing dotfiles
cd $HOME
mkdir -p ~/code ~/docs ~/dl ~/music ~/pics ~/pub ~/vids
mkdir -p ~/.config ~/.cache/zsh ~/.local/state/zsh ~/.local/share/mpd
git clone https://github.com/anshul333y/.dots.git ~/.dots
git clone https://github.com/anshul333y/scripts.git ~/.local/bin
rm -rf ~/.config/user-dirs.dirs && cd ~/.dots && stow --adopt . && cd
mkdir -p ~/.config/tmux/plugins && echo "*" >>~/.config/tmux/plugins/.gitignore
ln -s ~/.config/custom/user.js ~/.config/mozilla/firefox/*.default-release
echo "*/5 * * * * /home/anshul333y/.local/bin/notify/notify-battery-alert" | crontab -
dconf load / <~/.config/custom/gnome.dconf
powerprofilesctl set performance

# installing oh-my-zsh with plugins
export ZSH="$HOME/.config/oh-my-zsh"
export ZSH_CUSTOM="$HOME/.config/oh-my-zsh/custom"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM}/plugins/zsh-history-substring-search
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM}/plugins/you-should-use

# installing font | installing aur helper paru | installing aur packages
curl -Lo ~/dl/font1.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
curl -Lo ~/dl/font2.zip "https://github.com/subframe7536/maple-font/releases/download/v7.9/MapleMono-NF-CN-unhinted.zip"
7z x ~/dl/font1.zip -o$HOME/dl/fonts && 7z x ~/dl/font2.zip -o$HOME/dl/fonts && mv ~/dl/fonts ~/.local/share && fc-cache -fv && rm ~/dl/font1.zip ~/dl/font2.zip
git clone https://aur.archlinux.org/paru.git ~/dl/paru
cd ~/dl/paru && makepkg -si --noconfirm && cd && rm -rf ~/dl/paru
paru -S --noconfirm hyprqt6engine wlogout google-chrome brave-bin

# post install steps
mv ~/.gnupg ~/.local/share/gnupg
mv ~/.cargo ~/.local/share/cargo
rm -rf ~/.bash* ~/.zshrc
exit
