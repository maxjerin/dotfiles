#!/usr/bin/env bash

set -euo pipefail

# Ensure we protect files before commit
cp repo_config/pre-commit .git/hooks/pre-commit

install_homebrew_linuxbrew() {
    if ! command -v brew &> /dev/null
    then
        echo "Installing Homebrew/Linuxbrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "Homebrew/Linuxbrew already installed"
    fi
}

install_stow() {
    if ! command -v stow &> /dev/null; then
        echo "Installing Stow"
        brew install stow
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
    # ln -fs "$(pwd)/dotfile_templates/zsh/.zshrc_macos" "${HOME}/.zshrc"

    install_homebrew_linuxbrew
    install_stow
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

# MacOs Playbook
# ansible-playbook dotfiles.yml \
# -i hosts \
# --tags macos \
# --extra-vars="ansible_python_interpreter=$(which python)"

# Link zshrc from dotfiles
if ! command -v stow &> /dev/null; then
    echo "Stow not installed"
else
    pushd dotfile_templates
    stow -R --no-folding --target ~ zsh
    popd
    pushd dotfile_templates/zsh
    mkdir -p ~/.config/zsh
    stow -R --target ~/.config/zsh zsh
    popd

    pushd dotfile_templates
    mkdir -p ~/.config/starship
    stow -R --target ~/.config/starship starship
    mkdir -p ~/.config/alacritty
    stow -R --target ~/.config/alacritty alacritty
    mkdir -p ~/.config/tmux
    stow -R --target ~/.config/tmux tmux
    popd

    mkdir -p ~/.config/nvim/lua/plugins/ls/servers \
        ~/.config/nvim/lua/utils

    pushd dotfile_templates
    stow -R --no-folding --target ~/.config/nvim nvim
    popd
    pushd dotfile_templates/nvim
    stow -R --no-folding --target ~/.config/nvim/lua lua
    popd
    pushd dotfile_templates/nvim/lua
    stow -R --no-folding --target ~/.config/nvim/lua/utils utils
    popd
    pushd dotfile_templates/nvim/lua
    stow -R --no-folding --target ~/.config/nvim/lua/plugins plugins
    popd
    pushd dotfile_templates/nvim/lua/plugins
    stow -R --no-folding --target ~/.config/nvim/lua/plugins/lsp lsp
    popd
    pushd dotfile_templates/nvim/lua/plugins/lsp
    stow -R --no-folding --target ~/.config/nvim/lua/plugins/lsp/servers servers
    popd


    pushd dotfile_templates
    stow -R --target ~/.config/k9s k9s
    popd
    pushd dotfile_templates/k9s
    mkdir -p ~/.config/k9s/skins
    stow -R --target ~/.config/k9s/skins skins
    popd

    pushd dotfile_templates
    mkdir -p ~/.config/karabiner
    stow -R --no-folding --target ~/.config/karabiner karabiner
    popd

    pushd dotfile_templates
    mkdir -p ~/.config/kitty
    stow -R --target ~/.config/kitty kitty
    popd
fi

# source zshrc for homebrew
# shellcheck source=/dev/null
source "${HOME}/.zprofile"
# source "${HOME}/.zshrc"

exit 0
