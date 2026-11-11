# anshul333y's server installer script

#part1
printf '\033c'

# installing apt packages | installing flatpak packages | enabling systemd services
sudo apt install -y cronie curl zsh git stow p7zip-full unzip \
  python3-venv mpv yt-dlp mpd mpc ncmpcpp rsync nsxiv htop btop fastfetch \
  wl-clipboard eza bat zoxide starship fzf ripgrep fd-find tmux \
  gcc g++ nodejs npm \
  ufw nginx
sudo systemctl enable cronie.service

# installing neovim | installing docker
curl -Lo ~/dl/nvim-linux-arm64.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz"
sudo tar -C /opt -xzf ~/dl/nvim-linux-arm64.tar.gz
sudo ln -svf /opt/nvim-linux-arm64/bin/nvim /usr/local/bin/nvim
rm ~/dl/nvim-linux-arm64.tar.gz

sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo groupadd docker
sudo usermod -aG docker $USER

# changing shell to zsh | configure sudo | configure zsh
chsh -s /usr/bin/zsh
echo "%sudo ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
echo 'Defaults !admin_flag' | sudo tee -a /etc/sudoers.d/disable_admin_file_in_home
echo 'export ZDOTDIR="$HOME/.config/zsh"' | sudo tee -a /etc/zsh/zshenv

#part3
printf '\033c'

# system configuration variables
export GNUPGHOME="$HOME/.local/share/gnupg"
export CARGO_HOME="$HOME/.local/share/cargo"
export ZDOTDIR="$HOME/.config/zsh"
export ZSH="$HOME/.config/oh-my-zsh"
export ZSH_CUSTOM="$HOME/.config/oh-my-zsh/custom"

# creating user-dirs | installing dotfiles
cd $HOME
mkdir -p ~/code ~/docs ~/dl ~/music ~/pics ~/pub ~/vids
mkdir -p ~/.config ~/.cache/zsh ~/.local/state/zsh ~/.local/share/gnupg ~/.local/share/mpd
git clone https://github.com/anshul333y/.dots.git ~/.dots
git clone https://github.com/anshul333y/scripts.git ~/.local/bin
rm -rf ~/.config/user-dirs.dirs && cd ~/.dots && stow --adopt . && cd
# ln -s ~/.config/custom/user.js ~/.config/mozilla/firefox/*.default-release
# echo "*/5 * * * * /home/anshul333y/.local/bin/notify/notify-battery-alert" | crontab -
# dconf load / <~/.config/custom/gnome.dconf

# installing oh-my-zsh with plugins
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM}/plugins/zsh-history-substring-search
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM}/plugins/you-should-use

# # installing font
# curl -Lo ~/dl/font1.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
# curl -Lo ~/dl/font2.zip "https://github.com/subframe7536/maple-font/releases/download/v7.9/MapleMono-NF-CN-unhinted.zip"
# 7z x ~/dl/font1.zip -o$HOME/dl/fonts && 7z x ~/dl/font2.zip -o$HOME/dl/fonts && mv ~/dl/fonts ~/.local/share && fc-cache -fv && rm ~/dl/font1.zip ~/dl/font2.zip

# post install steps
# python3 -m venv ~/.local/venvs/pywal && source ~/.local/venvs/pywal/bin/activate && pip install pywal
mv ~/Documents/* ~/docs/ && mv ~/Downloads/* ~/dl/ && mv ~/Music/* ~/music/ && mv ~/Pictures/* ~/pics/ && mv ~/Public/* ~/pub/ && mv ~/Videos/* ~/vids/
rm -rf ~/Desktop ~/Documents ~/Downloads ~/Music ~/Pictures ~/Public ~/Templates ~/Videos
rm -rf ~/.profile ~/.bashrc
exit
