#!/usr/bin/env bash

set -euox pipefail

# Link zshrc from dotfiles
ln -sf $(pwd)/.zsh_abbr ~/.zsh_abbr
ln -sf $(pwd)/.zshrc_base ~/.zshrc_base

# Zsh and brew setup on MacOS
if [[ $(uname -s) == 'Darwin' ]]; then
    ln -fs $(pwd)/.zshrc_macos ~/.zshrc

    if ! command -v brew &> /dev/null
    then
        # Install Homebrew/Linuxbrew
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    if ! command -v ansible &> /dev/null
    then
        # install ansible using homebrew
        brew install ansible
    fi
else
# Zsh and brew setup on Linux
    ln -sf $(pwd)/.zshrc_linux ~/.zshrc

    if ! command -v brew &> /dev/null
    then
        # Install Homebrew/Linuxbrew
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Homebrew build essentials
        sudo apt update
        sudo apt-get install -y build-essential

    fi

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

# source zshrc for homebrew
source ~/.zshrc

# Dotfiles' project root directory
ROOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Host file location
HOSTS="$ROOTDIR/hosts"
# Main playbook
PLAYBOOK="$ROOTDIR/dotfiles.yml"

# Runs Ansible playbook using our user.
ansible-playbook -i "$HOSTS" "$PLAYBOOK"

if [[ $(uname -s) == 'Linux' ]]; then
    if command -v brew &> /dev/null
    then
        command -v zsh | sudo tee -a /etc/shells
        chsh -s $(brew --prefix)/bin/zsh
    else
        echo "zsh not installed"
    fi
fi


exit 0
