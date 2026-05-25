# anshul333y's nixos installer script

#part1
printf '\033c'

# partition, format and mount partitions
efi=/dev/nvme0n1p1
root=/dev/nvme0n1p2
home=/dev/nvme0n1p3
swap=/dev/nvme0n1p4

mkfs.fat -F 32 -n boot $efi
mkfs.ext4 -F -L nixos $root
mkfs.ext4 -F -L anshul333y $home
mkswap -L swap $swap

mount $root /mnt
mkdir -p /mnt/boot/efi
mkdir -p /mnt/home
mount $efi /mnt/boot/efi
mount $home /mnt/home
swapon $swap

# nixos-generate-config
git clone https://github.com/anshul333y/.dots
mkdir -p /mnt/etc/nixos
mv .dots/.config/nixos/* /mnt/etc/nixos

# nixos-install
nixos-install --flake /mnt/etc/nixos#nixos --no-root-passwd

# run second stage of installer inside chroot
sed '1,/^#part2$/d' $(basename $0) >/mnt/nixos2.sh
chmod +x /mnt/nixos2.sh
nixos-enter --root /mnt --command "/nixos2.sh"
exit

#part2
printf '\033c'

# set root and user passwords
username=nixos
root_pass=your_root_password
user_pass=your_user_password
echo "root:$root_pass" | chpasswd
echo "$username:$user_pass" | chpasswd

# run third stage of installer as user
nixos3_path=/home/$username/nixos3.sh
sed '1,/^#part3$/d' /nixos2.sh >$nixos3_path
chown $username:$username $nixos3_path
chmod +x $nixos3_path
su -c $nixos3_path -s /bin/sh $username
exit

#part3
printf '\033c'

# creating user-dirs | installing dotfiles
cd $HOME
mkdir -p ~/code ~/docs ~/dl ~/music ~/pics ~/pub ~/vids
mkdir -p ~/.cache/zsh ~/.local/state/zsh ~/.local/share/mpd
git clone https://github.com/anshul333y/nvim ~/.config/nvim
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

# installing font | post install steps
curl -Lo ~/dl/font.zip "https://github.com/subframe7536/maple-font/releases/download/v7.9/MapleMono-NF-CN-unhinted.zip"
7z x ~/dl/font.zip -o$HOME/dl/fonts && mv ~/dl/fonts ~/.local/share && fc-cache -fv && rm ~/dl/font.zip
mv ~/.gnupg ~/.local/share/gnupg
mv ~/.cargo ~/.local/share/cargo
rm -rf ~/.bash* ~/.zshrc
exit
