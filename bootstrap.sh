#!/usr/bin/env bash

set -euo pipefail

# Symlink rc files
ln -sf "$(pwd)/.zshrc_base" "${HOME}/.zshrc_base"
ln -sf "$(pwd)/.zprofile" "${HOME}/.zprofile"
mkdir -p ~/.config
ln -sf "$(pwd)/starship.toml" "${HOME}/.config/starship.toml"

install_homebrew_linuxbrew() {
    if ! command -v brew &> /dev/null
    then
        # Install Homebrew/Linuxbrew
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        source "${HOME}/.zprofile"
    else
        echo "Homebrew/Linuxbrew already installed"
    fi
}

# Zsh and brew setup on MacOS
if [[ $(uname -s) == 'Darwin' ]]; then
    ln -fs "$(pwd)/.zshrc_macos" "${HOME}/.zshrc"

    install_homebrew_linuxbrew

    if ! command -v ansible &> /dev/null
    then
        # install ansible using homebrew
        brew install ansible
    fi
else
# Zsh and brew setup on Linux
    ln -sf "$(pwd)/.zshrc_linux" "${HOME}/.zshrc"

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

# Copy abbreviations
[ ! -d "${HOME}/.config" ] && mkdir "${HOME}/.config"
[ ! -d "${HOME}/.config/zsh" ] && mkdir "${HOME}/.config/zsh"
cp abbreviations ~/.config/zsh/

# source zshrc for homebrew
# shellcheck source=/dev/null
source "${HOME}/.zshrc"

# # Dotfiles' project root directory
# ROOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# # Host file location
# HOSTS="$ROOTDIR/hosts"
# # Main playbook
# PLAYBOOK="$ROOTDIR/dotfiles.yml"

# # Runs Ansible playbook using our user.
# ansible-playbook -i "$HOSTS" "$PLAYBOOK"

exit 0
