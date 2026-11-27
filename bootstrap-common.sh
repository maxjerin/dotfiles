#!/usr/bin/env bash
# Shared, idempotent bootstrap helpers sourced by bootstrap-{macos,linux}.sh.

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install git pre-commit hook (idempotent: mkdir guard + overwrite-safe copy).
install_git_hooks() {
    mkdir -p .git/hooks
    if [ -f repo_config/pre-commit ]; then
        cp repo_config/pre-commit .git/hooks/pre-commit
        chmod +x .git/hooks/pre-commit
    fi
}

# Clone shell plugins not available via package managers (idempotent).
clone_zsh_plugins() {
    mkdir -p ~/.config/zsh
    if [ ! -d ~/.config/zsh/fzf-tab ]; then
        git clone https://github.com/Aloxaf/fzf-tab ~/.config/zsh/fzf-tab
    fi
}

# Point each coding agent's global instructions at ~/.config/agents/AGENTS.md
# and stow the Claude Code globals (CLAUDE.md, RTK.md) into ~/.claude.
# Idempotent. Existing real files are moved to *.pre-dotfiles, never overwritten.
link_agent_instructions() {
    local src="$HOME/.config/agents/AGENTS.md"
    local templates
    templates="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/dotfile_templates"

    # Codex reads ~/.codex/AGENTS.md: symlink it if free.
    mkdir -p ~/.codex
    if [ ! -e ~/.codex/AGENTS.md ] || [ -L ~/.codex/AGENTS.md ]; then
        ln -sfn "$src" ~/.codex/AGENTS.md
    fi

    # Claude Code reads ~/.claude/CLAUDE.md (which imports AGENTS.md + RTK.md): stow the
    # claude package. A pre-existing real file is backed up, not adopted, so local edits
    # never overwrite the repo copy.
    mkdir -p ~/.claude
    local f
    for f in CLAUDE.md RTK.md; do
        if [ -f "$HOME/.claude/$f" ] && [ ! -L "$HOME/.claude/$f" ]; then
            mv "$HOME/.claude/$f" "$HOME/.claude/$f.pre-dotfiles"
        fi
    done
    stow -R --no-folding --dir "$templates" --target ~/.claude claude
}

# Stow all shared configs plus any OS-only dirs in $STOW_OS_EXTRA.
setup_dotfiles_common() {
    if ! command_exists stow; then
        echo "Error: Stow is required but not installed" >&2
        return 1
    fi
    echo "Setting up dotfiles with Stow..."
    pushd dotfile_templates > /dev/null || return 1

    # zsh: .zshrc/.zprofile to ~, modular config to ~/.config/zsh
    stow --adopt -R --no-folding --target ~ zsh
    pushd zsh > /dev/null || return 1
    mkdir -p ~/.config/zsh
    stow --adopt -R --target ~/.config/zsh zsh
    popd > /dev/null || return 1

    local dir
    for dir in starship alacritty tmux kitty ghostty; do
        mkdir -p "$HOME/.config/$dir"
        stow --adopt -R --target "$HOME/.config/$dir" "$dir"
    done

    # k9s + nested skins
    mkdir -p ~/.config/k9s/skins
    stow --adopt -R --target ~/.config/k9s k9s
    pushd k9s > /dev/null || return 1
    stow --adopt -R --target ~/.config/k9s/skins skins
    popd > /dev/null || return 1

    # Warp themes live under ~/.warp (not ~/.config); both OSes run Warp.
    mkdir -p ~/.warp/themes
    stow --adopt -R --target ~/.warp warp

    # Agent-agnostic dev instructions -> ~/.config/agents/AGENTS.md, then point
    # each agent's global instructions file at it.
    mkdir -p ~/.config/agents
    stow --adopt -R --no-folding --target ~/.config/agents agents
    link_agent_instructions

    # OS-only extras (e.g. karabiner on macOS).
    # shellcheck disable=SC2086
    for dir in $STOW_OS_EXTRA; do
        mkdir -p "$HOME/.config/$dir"
        stow --adopt -R --no-folding --target "$HOME/.config/$dir" "$dir"
    done

    popd > /dev/null || return 1
}

# Idempotently make zsh the login shell.
ensure_login_shell() {
    local zsh_path
    zsh_path="$(command -v zsh)"
    [ -z "$zsh_path" ] && { echo "zsh not found; skipping shell switch" >&2; return 0; }
    if ! grep -qx "$zsh_path" /etc/shells; then
        echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
    fi
    if [ "$SHELL" != "$zsh_path" ]; then
        chsh -s "$zsh_path"
    fi
}
