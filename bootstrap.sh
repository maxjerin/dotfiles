#!/usr/bin/env bash

set -e

# Zsh setup on MacOS
if [[ $(uname -s) == 'Darwin' ]]; then

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # source zshrc for homebrew
    source ~/.zshrc

    # install ansible using homebrew
    brew install ansible

    # Link zshrc from dotfiles
    ln -s $(pwd)/.zshrc ~/.zshrc
    ln -s $(pwd)/.zsh_abbr ~/.zsh_abbr
else
    # Installs ansible
    sudo apt update \
    sudo apt install -y software-properties-common \
    sudo add-apt-repository --yes --update ppa:ansible/ansible \
    sudo apt update \
    sudo apt install -y ansible
fi

# Dotfiles' project root directory
ROOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Host file location
HOSTS="$ROOTDIR/hosts"
# Main playbook
PLAYBOOK="$ROOTDIR/dotfiles.yml"

# Runs Ansible playbook using our user.
ansible-playbook -i "$HOSTS" "$PLAYBOOK" --tags "macos"

exit 0
