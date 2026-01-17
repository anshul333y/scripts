# anshul333y's debian installer script

printf '\033c'

# configure grub with custom boot params
sudo sed -i 's/quiet splash/pci=noaer/' /etc/default/grub
sudo sed -i 's/GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=true/' /etc/default/grub

# configure sudo
echo "%sudo ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
echo 'Defaults !admin_flag' | sudo tee /etc/sudoers.d/disable_admin_file_in_home

# configure zsh
echo 'export ZDOTDIR="$HOME/.config/zsh"' | sudo tee -a /etc/zsh/zshenv

# installing apt packages
sudo apt install -y cronie curl zsh git stow unzip \
  python3-venv imagemagick \
  mpv yt-dlp mpd mpc ncmpcpp rsync sxiv htop btop \
  flatpak wl-clipboard fzf ripgrep fd-find tmux gcc g++ nodejs npm

# installing flatpak packages
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.github.wwmm.easyeffects
flatpak install -y flathub org.telegram.desktop
flatpak install -y flathub com.discordapp.Discord
flatpak install -y flathub io.github.sxyazi.yazi

# enabling systemd services
sudo systemctl enable cronie.service

# changing shell to zsh
chsh -s /usr/bin/zsh

# creating user-dirs
cd $HOME
mkdir -p ~/code ~/docs ~/dl ~/music ~/pics ~/pub ~/vids
mkdir -p ~/.local/share/mpd ~/.cache/zsh ~/.local/state/zsh
rm -rf ~/Desktop ~/Documents ~/Downloads ~/Music ~/Pictures ~/Public ~/Templates ~/Videos
rm -rf ~/.config/user-dirs.dirs
mv .gnupg ~/.local/share/gnupg

# installing dotfiles
git clone https://github.com/anshul333y/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles && stow --adopt . && cd
git clone https://github.com/anshul333y/nvim ~/.config/nvim
echo "*" >>~/.config/tmux/plugins/.gitignore
ln -s ~/.config/user.js ~/.mozilla/firefox/*.default-release/
dconf load / <~/.config/gnome.dconf
powerprofilesctl set performance
python3 -m venv ~/.python-venv && source ~/.python-venv/bin/activate && pip install pywal

# installing oh-my-zsh with plugins
export ZSH="$HOME/.config/oh-my-zsh"
export ZSH_CUSTOM="$HOME/.config/oh-my-zsh/custom"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM}/plugins/zsh-history-substring-search
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM}/plugins/you-should-use

# installing font
curl -Lo ~/dl/font.zip "https://github.com/subframe7536/maple-font/releases/download/v7.4/MapleMono-NF-CN-unhinted.zip"
unzip ~/dl/font.zip -d ~/dl/fonts && mv ~/dl/fonts ~/.local/share && fc-cache -fv && rm ~/dl/font.zip

# installing kitty
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
sudo ln -svf ~/.local/kitty.app/bin/kitty ~/.local/kitty.app/bin/kitten /usr/local/bin
cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
sed -i "s|Icon=kitty|Icon=$(readlink -f ~)/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty*.desktop
sed -i "s|Exec=kitty|Exec=$(readlink -f ~)/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty*.desktop
echo 'kitty.desktop' >~/.config/xdg-terminals.list

# installing starship
curl -sS https://starship.rs/install.sh | sh -s -- -y

# installing neovim
curl -Lo ~/dl/nvim-linux-x86_64.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
sudo tar -C /opt -xzf ~/dl/nvim-linux-x86_64.tar.gz
sudo ln -svf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
rm ~/dl/nvim-linux-x86_64.tar.gz

# installing firefox
sudo apt purge -y firefox-esr
sudo install -d -m 0755 /etc/apt/keyrings
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc >/dev/null
gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/{getline; gsub(/^ +| +$/,""); if($0 == "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3") print "\nThe key fingerprint matches ("$0").\n"; else print "\nVerification failed: the fingerprint ("$0") does not match the expected one.\n"}'
cat <<EOF | sudo tee /etc/apt/sources.list.d/mozilla.sources
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Signed-By: /etc/apt/keyrings/packages.mozilla.org.asc
EOF
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla
sudo apt-get update && sudo apt-get install -y firefox

# installing code
curl -Lo ~/dl/code.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
sudo apt install -y ~/dl/code.deb
rm ~/dl/code.deb

# installing docker
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER

# post install steps
rm .bash* .zshrc
