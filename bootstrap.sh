#!/usr/bin/env bash

set -e


# TODO
# Check if 
# install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# source zshrc for homebrew
source ~/.zshrc

# install ansible using homebrew
brew install ansible

# Dotfiles' project root directory
ROOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Host file location
HOSTS="$ROOTDIR/hosts"
# Main playbook
PLAYBOOK="$ROOTDIR/dotfiles.yml"

# Installs ansible
# apt-get update && apt-get install -y ansible

# Runs Ansible playbook using our user.
ansible-playbook -i "$HOSTS" "$PLAYBOOK" --tags "macos"

# Link zshrc from dotfiles
ln -s $(pwd)/.zshrc ~/.zshrc

exit 0
