# anshul333y's arch installer script

#part1
printf '\033c'

# configure pacman
sed -i "s/ParallelDownloads = 5/ParallelDownloads = 15/" /etc/pacman.conf

# update keyring and sync package databases
pacman --noconfirm -Sy archlinux-keyring

# set keyboard layout to us
loadkeys us

# enable network time sync
timedatectl set-ntp true

# partition, format and mount partitions
boot=/dev/nvme0n1p1
root=/dev/nvme0n1p2
home=/dev/nvme0n1p3
swap=/dev/nvme0n1p4

mkfs.fat -F 32 -n boot $boot
mkfs.ext4 -F -L arch $root
mkfs.ext4 -F -L anshul333y $home
mkswap -L swap $swap

mount $root /mnt
mkdir -p /mnt/boot
mkdir -p /mnt/home
mount $boot /mnt/boot
mount $home /mnt/home
swapon $swap

# install base system
pacstrap -K /mnt base base-devel linux linux-firmware intel-ucode grub efibootmgr os-prober \
  networkmanager dhcpcd bluez bluez-utils pipewire pipewire-pulse

# generate fstab
genfstab -U /mnt >>/mnt/etc/fstab

# run second stage of installer inside chroot
sed '1,/^#part2$/d' $(basename $0) >/mnt/arch2.sh
chmod +x /mnt/arch2.sh
arch-chroot /mnt ./arch2.sh
exit

#part2
printf '\033c'

# configure pacman and mkinitcpio and AllowSuspendThenHibernate
sed -i "s/ParallelDownloads = 5/ParallelDownloads = 15/" /etc/pacman.conf
sed -i "s/#Color/Color/" /etc/pacman.conf
sed -i "s/filesystems/filesystems resume/" /etc/mkinitcpio.conf
sed -i "s/#HibernateDelaySec=/HibernateDelaySec=20min/" /etc/systemd/sleep.conf
sed -i "s/#AllowSuspendThenHibernate=yes/AllowSuspendThenHibernate=yes/" /etc/systemd/sleep.conf

# set system timezone
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime

# set hardware clock from system time
hwclock --systohc

# enable english locale
echo "en_US.UTF-8 UTF-8" >>/etc/locale.gen
locale-gen

# set system-wide locale and keymap
echo "LANG=en_US.UTF-8" >/etc/locale.conf
echo "KEYMAP=us" >/etc/vconsole.conf

# set hostname
hostname=archlinux
echo $hostname >/etc/hostname

# configure hosts file
echo "127.0.0.1       localhost" >>/etc/hosts
echo "::1             localhost" >>/etc/hosts
echo "127.0.1.1       $hostname.localdomain $hostname" >>/etc/hosts

# generate initramfs image
mkinitcpio -P

# install and configure grub with custom boot params
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
sed -i 's/GRUB_DEFAULT=0/GRUB_DEFAULT=saved/' /etc/default/grub
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/' /etc/default/grub
sed -i 's/quiet/pci=noaer/' /etc/default/grub
sed -i 's/#GRUB_SAVEDEFAULT=true/GRUB_SAVEDEFAULT=true/' /etc/default/grub
sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# installing pacman packages
pacman -S --noconfirm reflector cronie dash zsh starship git openssh stow 7zip \
  noto-fonts noto-fonts-cjk noto-fonts-emoji \
  hyprland hyprpaper hypridle hyprlock rofi-wayland waybar dunst polkit-gnome gnome-keyring \
  qt5-wayland qt6-wayland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  uwsm brightnessctl acpi pacman-contrib python-pywal xdg-user-dirs \
  yazi poppler mpv yt-dlp mpd timidity++ mpc ncmpcpp sxiv xorg-xrdb rsync htop btop \
  firefox flatpak kitty wl-clipboard nvim lazygit fzf ripgrep fd tmux nodejs npm docker

# installing flatpak packages
flatpak install --noninteractive flathub com.github.wwmm.easyeffects
flatpak install --noninteractive flathub org.telegram.desktop
flatpak install --noninteractive flathub com.discordapp.Discord

# enabling systemd services
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable reflector.timer
systemctl enable cronie.service

# replace default shell with dash
rm /bin/sh
ln -s dash /bin/sh

# allow wheel group to use sudo without a password
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers

# create a new user and add to wheel group
username=anshul333y
useradd -m -G wheel -s /bin/zsh $username

# set root and user passwords
root_pass=your_root_password
user_pass=your_user_password
echo "root:$root_pass" | chpasswd
echo "$username:$user_pass" | chpasswd

# configure reflector
sed -i "s/5/30/" /etc/xdg/reflector/reflector.conf
sed -i "s/age/rate/" /etc/xdg/reflector/reflector.conf

# unlock and auto-start the gnome keyring at login
sed -i "/auth       include      system-local-login/a auth       optional     pam_gnome_keyring.so" /etc/pam.d/login
sed -i "/session    include      system-local-login/a session    optional     pam_gnome_keyring.so auto_start" /etc/pam.d/login

# charging and discharging notifications
echo 'ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", ENV{DISPLAY}=":0", ENV{XAUTHORITY}="/home/anshul333y/.Xauthority" RUN+="/usr/bin/su anshul333y -c '\''/home/anshul333y/.local/bin/notify/notify-battery-charging discharging'\''"' >>/etc/udev/rules.d/power.rules
echo 'ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", ENV{DISPLAY}=":0", ENV{XAUTHORITY}="/home/anshul333y/.Xauthority" RUN+="/usr/bin/su anshul333y -c '\''/home/anshul333y/.local/bin/notify/notify-battery-charging charging'\''"' >>/etc/udev/rules.d/power.rules

# run third stage of installer as user
arch3_path=/home/$username/arch3.sh
sed '1,/^#part3$/d' arch2.sh >$arch3_path
chown $username:$username $arch3_path
chmod +x $arch3_path
su -c $arch3_path -s /bin/sh $username
exit

#part3
# anshul333y's hyprland installer script
printf '\033c'

# # installing pacman packages
# # installing flatpak packages
# # enabling systemd services
# # changing shell to zsh
# sudo chsh -s /bin/zsh

# creating user-dirs
cd $HOME
mkdir -p ~/code ~/docs ~/dl ~/music ~/pics ~/pub ~/vids ~/.local/share/mpd

# installing LazyVim
git clone https://github.com/LazyVim/starter ~/.config/nvim

# installing dotfiles
git clone https://github.com/anshul333y/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles && stow . && cd

# adding crontab
echo "*/5 * * * * /home/anshul333y/.local/bin/notify/notify-battery-alert" | crontab -

# installing oh-my-zsh with plugins
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use

# installing font
curl -Lo ~/dl/font.zip "https://github.com/subframe7536/maple-font/releases/download/v7.4/MapleMono-NF-CN-unhinted.zip"
7z x ~/dl/font.zip -o$HOME/dl/fonts && mv ~/dl/fonts ~/.local/share && fc-cache -fv && rm ~/dl/font.zip

# installing aur helper paru
git clone https://aur.archlinux.org/paru-bin.git ~/dl/paru
cd ~/dl/paru && makepkg -si --noconfirm && cd && rm -rf ~/dl/paru

# installing aur packages
paru -S --noconfirm hyprshot-git wlogout python-pywalfox brave-bin google-chrome visual-studio-code-bin

# post install steps
rm .bash* .zshrc
