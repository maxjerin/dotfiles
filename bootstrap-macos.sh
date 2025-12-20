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
        pipx ensurepath --force
        # Add pipx bin to PATH for current session
        export PATH="$HOME/.local/bin:$PATH"
    else
        echo "pipx already installed"
        # Ensure pipx bin is in PATH for current session
        export PATH="$HOME/.local/bin:$PATH"
        # Refresh shell PATH hints for current session
        pipx ensurepath --force >/dev/null 2>&1 || true
    fi

    echo "Installing project dependencies with pipx..."

    # Install tools if not already installed
    if ! command_exists ansible; then
        pipx install ansible
        # Re-export PATH after installation to ensure it's available
        export PATH="$HOME/.local/bin:$PATH"
    else
        # Ensure ansible entrypoints are linked into ~/.local/bin even if venv exists
        pipx reinstall ansible >/dev/null 2>&1 || true
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
        # Prefer direct, cheap checks of common pipx venv locations before an expensive home scan
        if [ -x "$HOME/.local/bin/ansible-playbook" ]; then
            export PATH="$HOME/.local/bin:$PATH"
        elif [ -x "$HOME/.local/pipx/venvs/ansible/bin/ansible-playbook" ]; then
            export PATH="$HOME/.local/pipx/venvs/ansible/bin:$PATH"
            echo "Using ansible-playbook from pipx venv: ~/.local/pipx/venvs/ansible/bin"
        elif [ -x "$HOME/.local/pipx/venvs/ansible-core/bin/ansible-playbook" ]; then
            export PATH="$HOME/.local/pipx/venvs/ansible-core/bin:$PATH"
            echo "Using ansible-playbook from pipx venv: ~/.local/pipx/venvs/ansible-core/bin"
        else
            echo "Trying to locate it with pipx metadata..."
            # As a last resort, do a targeted search under pipx directory rather than ~
            ANSIBLE_PATH=$(find "$HOME/.local/pipx/venvs" -type f -name ansible-playbook 2>/dev/null | head -1)
            if [ -n "${ANSIBLE_PATH:-}" ]; then
                echo "Found ansible-playbook at: $ANSIBLE_PATH"
                export PATH="$(dirname "$ANSIBLE_PATH"):$PATH"
            else
                echo "Error: Could not find ansible-playbook after installation"
                echo "Please check pipx installation with: pipx list"
                echo "You can also run: pipx install --force ansible"
                return 1
            fi
        fi
    fi

    echo "✓ Ansible tools installed and available"
}

# Function to run Ansible playbook for macOS
run_ansible_playbook() {
    # Ensure pipx bin is in PATH
    export PATH="$HOME/.local/bin:$PATH"

    # Try to find ansible-playbook if not in PATH
    if ! command_exists ansible-playbook; then
        # Attempt direct known locations first
        if [ -x "$HOME/.local/bin/ansible-playbook" ]; then
            export PATH="$HOME/.local/bin:$PATH"
        elif [ -x "$HOME/.local/pipx/venvs/ansible/bin/ansible-playbook" ]; then
            export PATH="$HOME/.local/pipx/venvs/ansible/bin:$PATH"
        elif [ -x "$HOME/.local/pipx/venvs/ansible-core/bin/ansible-playbook" ]; then
            export PATH="$HOME/.local/pipx/venvs/ansible-core/bin:$PATH"
        fi
    fi

    if command_exists ansible-playbook; then
        echo "Running Ansible playbook for macOS..."
        ansible-playbook dotfiles.yml \
            -i hosts \
            --tags macos \
            --extra-vars="ansible_python_interpreter=$(which python3)"
    else
        # Fallback: run via pipx without relying on PATH
        if command_exists pipx; then
            echo "Running Ansible playbook for macOS via pipx..."
            pipx run --spec ansible-core ansible-playbook dotfiles.yml \
                -i hosts \
                --tags macos \
                --extra-vars="ansible_python_interpreter=$(which python3)"
        else
            echo "Error: ansible-playbook not found and pipx unavailable."
            echo "Please ensure pipx is installed and ansible is installed via: pipx install ansible"
            return 1
        fi
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

    # Run Ansible playbook to configure macOS settings
    # This configures Spotlight, Raycast, Dock, keyboard settings, etc.
    run_ansible_playbook

    setup_dotfiles

    echo "Bootstrap complete!"
    echo ""
    echo "To apply changes in your current shell, run:"
    echo "  source ~/.zshrc"
    echo ""
    echo "Or simply open a new terminal window."
}

main "$@"
