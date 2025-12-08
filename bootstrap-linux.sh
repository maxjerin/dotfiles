#!/usr/bin/env bash

set -euo pipefail

# Linux-specific bootstrap script
# This script sets up the dotfiles environment on Linux

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

# Function to check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        echo "Error: Do not run this script as root"
        exit 1
    fi
}

# Function to install Linuxbrew if not present
install_linuxbrew() {
    if ! command_exists brew; then
        echo "Installing Linuxbrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Linuxbrew to PATH
        if [ -d "/home/linuxbrew/.linuxbrew" ]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        elif [ -d "$HOME/.linuxbrew" ]; then
            eval "$($HOME/.linuxbrew/bin/brew shellenv)"
        fi
    else
        echo "Linuxbrew already installed"
    fi
}

# Function to install build essentials (required for Linuxbrew)
install_build_essentials() {
    if command_exists apt-get; then
        echo "Installing build essentials..."
        sudo apt-get update
        sudo apt-get install -y build-essential curl file git
    elif command_exists yum; then
        echo "Installing build essentials..."
        sudo yum groupinstall -y "Development Tools"
        sudo yum install -y curl file git
    elif command_exists dnf; then
        echo "Installing build essentials..."
        sudo dnf groupinstall -y "Development Tools"
        sudo dnf install -y curl file git
    else
        echo "Warning: Could not detect package manager. Please install build-essential manually."
    fi
}

# Function to install Stow
install_stow() {
    if ! command_exists stow; then
        echo "Installing Stow..."
        if command_exists brew; then
            brew install stow
        elif command_exists apt-get; then
            sudo apt-get install -y stow
        elif command_exists yum; then
            sudo yum install -y stow
        elif command_exists dnf; then
            sudo dnf install -y stow
        else
            echo "Error: Could not install Stow. Please install it manually."
            return 1
        fi
    else
        echo "Stow already installed"
    fi
}

# Function to install pipx and tools
setup_pipx_tools() {
    if ! command_exists pipx; then
        echo "Installing pipx..."
        if command_exists brew; then
            brew install pipx
        elif command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y pipx
        elif command_exists yum; then
            sudo yum install -y pipx
        elif command_exists dnf; then
            sudo dnf install -y pipx
        else
            # Fallback: install via pip
            python3 -m pip install --user pipx
        fi
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

# Function to set zsh as default shell
setup_zsh_shell() {
    if command_exists zsh; then
        if command_exists brew; then
            ZSH_PATH="$(brew --prefix)/bin/zsh"
        else
            ZSH_PATH="$(command -v zsh)"
        fi

        if [ -n "$ZSH_PATH" ] && [ -f "$ZSH_PATH" ]; then
            echo "Setting zsh as default shell..."
            echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
            chsh -s "$ZSH_PATH"
        fi
    else
        echo "Warning: zsh not found. Please install zsh first."
    fi
}

# Function to run Ansible playbook for Linux
run_ansible_playbook() {
    if command_exists ansible-playbook; then
        echo "Running Ansible playbook for Linux..."
        ansible-playbook dotfiles.yml \
            -i hosts \
            --tags linux \
            --become \
            --become-method sudo \
            --extra-vars="ansible_python_interpreter=$(which python3)"
    else
        echo "Warning: ansible-playbook not found. Install it first."
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
    ln -sf "$(pwd)/zsh/.zshrc_linux" "${HOME}/.zshrc"
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

    # Neovim
    mkdir -p ~/.config/nvim/lua/plugins/lsp/servers ~/.config/nvim/lua/utils
    stow --adopt -R --no-folding --target ~/.config/nvim neovim
    pushd neovim > /dev/null
    stow --adopt -R --no-folding --target ~/.config/nvim/lua lua
    popd > /dev/null
    pushd neovim/lua > /dev/null
    stow --adopt -R --no-folding --target ~/.config/nvim/lua/utils utils
    stow --adopt -R --no-folding --target ~/.config/nvim/lua/plugins plugins
    popd > /dev/null
    pushd neovim/lua/plugins > /dev/null
    stow --adopt -R --no-folding --target ~/.config/nvim/lua/plugins/lsp lsp
    popd > /dev/null
    pushd neovim/lua/plugins/lsp > /dev/null
    stow --adopt -R --no-folding --target ~/.config/nvim/lua/plugins/lsp/servers servers
    popd > /dev/null

    # K9s
    mkdir -p ~/.config/k9s/skins
    stow --adopt -R --target ~/.config/k9s k9s
    pushd k9s > /dev/null
    stow --adopt -R --target ~/.config/k9s/skins skins
    popd > /dev/null

    # Kitty
    mkdir -p ~/.config/kitty
    stow --adopt -R --target ~/.config/kitty kitty

    popd > /dev/null
}

# Main execution
main() {
    check_root
    echo "Starting Linux bootstrap..."

    install_build_essentials
    install_linuxbrew
    install_stow
    setup_pipx_tools
    setup_zsh_shell

    # Optionally run Ansible playbook (commented out by default)
    # run_ansible_playbook

    setup_dotfiles

    echo "Bootstrap complete!"
    echo "Please source your shell configuration: source ~/.zprofile"
}

main "$@"

