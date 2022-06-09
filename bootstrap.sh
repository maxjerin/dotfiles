#!/usr/bin/env bash

set -euox pipefail

# Install Homebrew/Linuxbrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Link zshrc from dotfiles
ln -s $(pwd)/.zsh_abbr ~/.zsh_abbr
ln -s $(pwd)/.zshrc_base ~/.zshrc_base

# Zsh and brew setup on MacOS
if [[ $(uname -s) == 'Darwin' ]]; then
    ln -s $(pwd)/.zshrc_macos ~/.zshrc

    # install ansible using homebrew
    brew install ansible
else
# Zsh and brew setup on Linux
    ln -s $(pwd)/.zshrc_linux ~/.zshrc

    # Homebrew build essentials
    sudo apt update
    sudo apt-get install -y build-essential

    # Installs ansible
    sudo apt update
    sudo apt install -y software-properties-common
    sudo add-apt-repository --yes --update ppa:ansible/ansible
    sudo apt update
    sudo apt install -y ansible
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

exit 0
