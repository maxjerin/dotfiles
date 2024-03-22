#!/usr/bin/env bash

set -euo pipefail

# Ensure we protect files before commit
cp repo_config/pre-commit .git/hooks/pre-commit

# Link zshrc from dotfiles
ln -sf "$(pwd)/dotfile_templates/zsh/.zshrc_base" "${HOME}/.zshrc_base"
ln -sf "$(pwd)/dotfile_templates/zsh/.zprofile" "${HOME}/.zprofile"
mkdir -p ~/.config
ln -sf "$(pwd)/dotfile_templates/starship/starship.toml" "${HOME}/.config/starship.toml"

mkdir -p ~/.config/alacritty
ln -sf "$(pwd)/dotfile_templates/alacritty/alacritty.toml" "${HOME}/.config/alacritty/alacritty.toml"

mkdir -p ~/.config/tmux
ln -sf "$(pwd)/dotfile_templates/tmux/tmux.conf" "${HOME}/.config/tmux/tmux.conf"

mkdir -p ~/.config/k9s/skins
ln -sf "$(pwd)/dotfile_templates/k9s/config.yaml" "${HOME}/.config/k9s/config.yaml"
ln -sf "$(pwd)/dotfile_templates/k9s/skin.yaml" "${HOME}/.config/k9s/skins/dracula.yaml"

mkdir -p ~/.config/karabiner
ln -sf "$(pwd)/dotfile_templates/karabiner/karabiner.json" "${HOME}/.config/karabiner/karabiner.json"

mkdir -p ~/.config/kitty
ln -sf "$(pwd)/dotfile_templates/kitty/kitty.conf" "${HOME}/.config/kitty/kitty.conf"
cp "$(pwd)/dotfile_templates/kitty/Spacemacs_dark.conf" "${HOME}/.config/kitty/Spacemacs_dark.conf"
cp "$(pwd)/dotfile_templates/kitty/Spacemacs_light.conf" "${HOME}/.config/kitty/Spacemacs_light.conf"
ln -sf ~/.config/kitty/Spacemacs_dark.conf ~/.config/kitty/theme.conf

# Abbreviations
[ ! -d "${HOME}/.config" ] && mkdir "${HOME}/.config"
[ ! -d "${HOME}/.config/zsh" ] && mkdir "${HOME}/.config/zsh"
cat dotfile_templates/abbreviations_common > ~/.config/zsh/abbreviations
cat dotfile_templates/abbreviations_work >> ~/.config/zsh/abbreviations

install_homebrew_linuxbrew() {
    if ! command -v brew &> /dev/null
    then
        echo "Install Homebrew/Linuxbrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        source "${HOME}/.zprofile"
    else
        echo "Homebrew/Linuxbrew already installed"
    fi
}

setup_poetry_project() {
    python3 -m venv venv
    source venv/bin/activate
    pip install poetry
    poetry install
}

# Zsh and brew setup on MacOS
if [[ $(uname -s) == 'Darwin' ]]; then
    ln -fs "$(pwd)/dotfile_templates/zsh/.zshrc_macos" "${HOME}/.zshrc"

    install_homebrew_linuxbrew
    setup_poetry_project
else
# Zsh and brew setup on Linux
    ln -sf "$(pwd)/dotfile_templates/zsh/.zshrc_linux" "${HOME}/.zshrc"

    install_homebrew_linuxbrew

    # Homebrew build essentials
    sudo apt update
    sudo apt-get install -y build-essential

    if ! command -v ansible &> /dev/null
    then
        # Installs ansible
        sudo apt update
        sudo apt install -y software-properties-common
        sudo add-apt-repository --yes --update ppa:ansible/ansible
        sudo apt update
        sudo apt install -y ansible
    fi
fi

if [[ $(uname -s) == 'Linux' ]]; then
    if command -v brew &> /dev/null
    then
        command -v zsh | sudo tee -a /etc/shells
        chsh -s "$(brew --prefix)/bin/zsh"
    else
        echo "zsh not installed"
    fi
fi

# # Dotfiles' project root directory
# ROOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# # Host file location
# HOSTS="$ROOTDIR/hosts"
# # Main playbook
# PLAYBOOK="$ROOTDIR/dotfiles.yml"

# # Runs Ansible playbook using our user.
# ansible-playbook -i "$HOSTS" "$PLAYBOOK"

# MacOs Playbook
ansible-playbook dotfiles.yml \
-i hosts \
--tags macos \
--extra-vars="ansible_python_interpreter=$(which python)"

# source zshrc for homebrew
# shellcheck source=/dev/null
source "${HOME}/.zprofile"
source "${HOME}/.zshrc"

exit 0
