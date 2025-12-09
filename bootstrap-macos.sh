#!/usr/bin/env bash

set -euo pipefail

# macOS-specific bootstrap script
# This script sets up the dotfiles environment on macOS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Ensure we protect files before commit
if [ -d ".git" ]; then
    cp repo_config/pre-commit .git/hooks/pre-commit
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to install Homebrew if not present
install_homebrew() {
    if ! command_exists brew; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    else
        echo "Homebrew already installed"
    fi
}

# Function to install Stow
install_stow() {
    if ! command_exists stow; then
        echo "Installing Stow..."
        brew install stow
    else
        echo "Stow already installed"
    fi
}

# Function to install pipx and tools
setup_pipx_tools() {
    if ! command_exists pipx; then
        echo "Installing pipx..."
        brew install pipx
        pipx ensurepath
    else
        echo "pipx already installed"
    fi

    echo "Installing project dependencies with pipx..."

    # Install tools if not already installed
    if ! command_exists ansible; then
        pipx install ansible
    fi

    if ! command_exists ansible-lint; then
        pipx install ansible-lint
    fi

    if ! command_exists yamllint; then
        pipx install yamllint
    fi
}

# Function to run Ansible playbook for macOS
run_ansible_playbook() {
    if command_exists ansible-playbook; then
        echo "Running Ansible playbook for macOS..."
        ansible-playbook dotfiles.yml \
            -i hosts \
            --tags macos \
            --extra-vars="ansible_python_interpreter=$(which python3)"
    else
        echo "Warning: ansible-playbook not found. It should have been installed via pipx."
    fi
}

# Function to setup dotfiles with Stow
setup_dotfiles() {
    if ! command_exists stow; then
        echo "Error: Stow is required but not installed"
        return 1
    fi

    echo "Setting up dotfiles with Stow..."

    pushd dotfile_templates > /dev/null

    # Zsh configuration
    stow --adopt -R --no-folding --target ~ zsh
    pushd zsh > /dev/null
    mkdir -p ~/.config/zsh
    stow --adopt -R --target ~/.config/zsh zsh
    popd > /dev/null

    # Starship prompt
    mkdir -p ~/.config/starship
    stow --adopt -R --target ~/.config/starship starship

    # Alacritty terminal
    mkdir -p ~/.config/alacritty
    stow --adopt -R --target ~/.config/alacritty alacritty

    # Tmux
    mkdir -p ~/.config/tmux
    stow --adopt -R --target ~/.config/tmux tmux

    # K9s
    mkdir -p ~/.config/k9s/skins
    stow --adopt -R --target ~/.config/k9s k9s
    pushd k9s > /dev/null
    stow --adopt -R --target ~/.config/k9s/skins skins
    popd > /dev/null

    # Karabiner (macOS only)
    mkdir -p ~/.config/karabiner
    stow --adopt -R --no-folding --target ~/.config/karabiner karabiner

    # Kitty
    mkdir -p ~/.config/kitty
    stow --adopt -R --target ~/.config/kitty kitty

    popd > /dev/null
}

# Main execution
main() {
    echo "Starting macOS bootstrap..."

    install_homebrew
    install_stow
    setup_pipx_tools

    # Optionally run Ansible playbook (commented out by default)
    # run_ansible_playbook

    setup_dotfiles

    echo "Bootstrap complete!"
    echo "Please source your shell configuration: source ~/.zprofile"
}

main "$@"

