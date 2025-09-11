# anshul333y's arch installer script

#part1
printf '\033c'

# set parallel downloads to 15
sed -i "s/^ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf

# update keyring and sync package databases
pacman --noconfirm -Sy archlinux-keyring

# set keyboard layout to us
loadkeys us

# enable network time sync
timedatectl set-ntp true

# partitioning
efipartition=/dev/nvme0n1p5
partition=/dev/nvme0n1p6
home=/dev/nvme0n1p7

# format partitions
mkfs.fat -F 32 $efipartition
mkfs.ext4 -F $partition

# mount partitions
mount $partition /mnt
mkdir -p /mnt/boot/efi
mkdir -p /mnt/home
mount $efipartition /mnt/boot/efi
mount $home /mnt/home

# install base system
pacstrap -K /mnt base base-devel linux linux-firmware

# generate fstab
genfstab -U /mnt >>/mnt/etc/fstab

# run second stage of installer inside chroot
sed '1,/^#part2$/d' $(basename $0) >/mnt/arch_install2.sh
chmod +x /mnt/arch_install2.sh
arch-chroot /mnt ./arch_install2.sh
exit

#part2
printf '\033c'

# configure pacman
sed -i "s/^ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
sed -i "s/^#Color$/Color/" /etc/pacman.conf

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
pacman --noconfirm -S grub efibootmgr os-prober
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
sed -i 's|GRUB_DEFAULT=0|GRUB_DEFAULT=saved|' /etc/default/grub
sed -i 's|GRUB_TIMEOUT=5|GRUB_TIMEOUT=1|' /etc/default/grub
sed -i 's|quiet|pci=noaer|' /etc/default/grub
sed -i 's|#GRUB_SAVEDEFAULT=true|GRUB_SAVEDEFAULT=true|' /etc/default/grub
sed -i 's|#GRUB_DISABLE_OS_PROBER=false|GRUB_DISABLE_OS_PROBER=false|' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# installing pacman packages
pacman -S --noconfirm networkmanager dhcpcd bluez bluez-utils pipewire pipewire-pulse \
  dash zsh git openssh stow reflector cronie noto-fonts noto-fonts-cjk noto-fonts-emoji \
  hyprland hyprpaper hypridle hyprlock rofi-wayland waybar dunst polkit-gnome gnome-keyring \
  qt5-wayland qt6-wayland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-user-dirs \
  uwsm brightnessctl acpi pacman-contrib python-pywal xorg-xrdb unzip 7zip rsync \
  firefox flatpak sxiv yazi poppler mpv mpd ncmpcpp mpc \
  kitty wl-clipboard nvim lazygit fzf ripgrep fd tmux nodejs npm docker

# installing flatpak packages
flatpak install --noninteractive flathub com.github.wwmm.easyeffects

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

# unlock and auto-start the gnome keyring at login
sed -i "/auth       include      system-local-login/a auth       optional     pam_gnome_keyring.so" /etc/pam.d/login
sed -i "/session    include      system-local-login/a session    optional     pam_gnome_keyring.so auto_start" /etc/pam.d/login

# charging and discharging notifications
echo 'ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", ENV{DISPLAY}=":0", ENV{XAUTHORITY}="/home/anshul333y/.Xauthority" RUN+="/usr/bin/su anshul333y -c '\''/home/anshul333y/.local/bin/notify/notify-battery-charging discharging'\''"' >>/etc/udev/rules.d/power.rules
echo 'ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", ENV{DISPLAY}=":0", ENV{XAUTHORITY}="/home/anshul333y/.Xauthority" RUN+="/usr/bin/su anshul333y -c '\''/home/anshul333y/.local/bin/notify/notify-battery-charging charging'\''"' >>/etc/udev/rules.d/power.rules

# run third stage of installer as user
ai3_path=/home/$username/arch_install3.sh
sed '1,/^#part3$/d' arch_install2.sh >$ai3_path
chown $username:$username $ai3_path
chmod +x $ai3_path
su -c $ai3_path -s /bin/sh $username
exit

#part3
cd $HOME
# anshul333y's hyprland installer script

printf '\033c'

# creating user-dirs
mkdir -p code dl pub docs music pics vids ~/.local/share/mpd

# installing aur helper paru
git clone https://aur.archlinux.org/paru-bin.git ~/dl/paru
cd ~/dl/paru && makepkg -si --noconfirm && cd && rm -rf ~/dl/paru

# installing aur packages
paru -S --noconfirm hyprshot-git python-pywalfox visual-studio-code-bin

# installing LazyVim
git clone https://github.com/LazyVim/starter ~/.config/nvim

# installing dotfiles
git clone https://github.com/anshul333y/.dotfiles.git
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
unzip ~/dl/font.zip -d ~/dl/fonts && mv ~/dl/fonts ~/.local/share && fc-cache -fv && rm ~/dl/font.zip

# post install steps
rm .bash* .zshrc
