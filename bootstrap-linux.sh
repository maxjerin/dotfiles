#!/usr/bin/env bash

set -euo pipefail

# Linux-specific bootstrap script
# This script sets up the dotfiles environment on Linux

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# shellcheck source=bootstrap-common.sh
source "$SCRIPT_DIR/bootstrap-common.sh"
export STOW_OS_EXTRA=""

# Ensure we protect files before commit
install_git_hooks

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
            eval "$("$HOME"/.linuxbrew/bin/brew shellenv)"
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
        # Add pipx bin to PATH for current session
        export PATH="$HOME/.local/bin:$PATH"
    else
        echo "pipx already installed"
        # Ensure pipx bin is in PATH for current session
        export PATH="$HOME/.local/bin:$PATH"
    fi

    echo "Installing project dependencies with pipx..."

    # Install tools if not already installed
    if ! command_exists ansible; then
        pipx install ansible
        # Re-export PATH after installation to ensure it's available
        export PATH="$HOME/.local/bin:$PATH"
    fi

    if ! command_exists ansible-lint; then
        pipx install ansible-lint
    fi

    if ! command_exists yamllint; then
        pipx install yamllint
    fi

    # Verify ansible-playbook is accessible
    if ! command_exists ansible-playbook; then
        echo "Warning: ansible-playbook not found in PATH"
        echo "Trying to locate it..."
        ANSIBLE_PATH=$(find ~ -name ansible-playbook 2>/dev/null | head -1)
        if [ -n "$ANSIBLE_PATH" ]; then
            echo "Found ansible-playbook at: $ANSIBLE_PATH"
            ANSIBLE_DIR="$(dirname "$ANSIBLE_PATH")"
            export PATH="$ANSIBLE_DIR:$PATH"
        else
            echo "Error: Could not find ansible-playbook after installation"
            echo "Please check pipx installation: pipx list"
            return 1
        fi
    fi

    echo "✓ Ansible tools installed and available"
}

# Function to set zsh as default shell
setup_zsh_shell() {
    ensure_login_shell
}

# Function to run Ansible playbook for Linux
run_ansible_playbook() {
    # Ensure pipx bin is in PATH
    export PATH="$HOME/.local/bin:$PATH"

    # Try to find ansible-playbook if not in PATH
    if ! command_exists ansible-playbook; then
        ANSIBLE_PATH=$(find ~ -name ansible-playbook 2>/dev/null | head -1)
        if [ -n "$ANSIBLE_PATH" ]; then
            echo "Found ansible-playbook at: $ANSIBLE_PATH"
            ANSIBLE_DIR="$(dirname "$ANSIBLE_PATH")"
            export PATH="$ANSIBLE_DIR:$PATH"
        else
            echo "Error: ansible-playbook not found."
            echo "Please ensure pipx is installed and ansible is installed via: pipx install ansible"
            return 1
        fi
    fi

    if command_exists ansible-playbook; then
        echo "Running Ansible playbook for Linux..."
        ansible-playbook dotfiles.yml \
            -i hosts \
            --tags linux \
            --become \
            --become-method sudo \
            --extra-vars="ansible_python_interpreter=$(which python3)"
    else
        echo "Error: ansible-playbook not found. It should have been installed via pipx."
        return 1
    fi
}

# Function to setup dotfiles with Stow
setup_dotfiles() {
    clone_zsh_plugins
    setup_dotfiles_common
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
    echo ""
    echo "To apply changes in your current shell, run:"
    echo "  source ~/.zshrc"
    echo ""
    echo "Or simply open a new terminal window."
}

main "$@"
