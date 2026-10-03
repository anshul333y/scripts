# anshul333y's server installer script

#part1
printf '\033c'

sudo apt install -y zsh stow fzf eza zoxide starship \
  gcc g++ unzip \
  nginx nodejs npm

curl -Lo ~/dl/nvim-linux-arm64.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz"
sudo tar -C /opt -xzf ~/dl/nvim-linux-arm64.tar.gz
sudo ln -svf /opt/nvim-linux-arm64/bin/nvim /usr/local/bin/nvim
rm ~/dl/nvim-linux-arm64.tar.gz

chsh -s /usr/bin/zsh
echo 'export ZDOTDIR="$HOME/.config/zsh"' | sudo tee -a /etc/zsh/zshenv

#part3
printf '\033c'

# system configuration variables
export GNUPGHOME="$HOME/.local/share/gnupg"
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

# installing oh-my-zsh with plugins
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM}/plugins/zsh-history-substring-search
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM}/plugins/you-should-use

# post install steps
mv ~/Documents/* ~/docs/ && mv ~/Downloads/* ~/dl/ && mv ~/Music/* ~/music/ && mv ~/Pictures/* ~/pics/ && mv ~/Public/* ~/pub/ && mv ~/Videos/* ~/vids/
rm -rf ~/Desktop ~/Documents ~/Downloads ~/Music ~/Pictures ~/Public ~/Templates ~/Videos
rm -rf ~/.bash*
exit
