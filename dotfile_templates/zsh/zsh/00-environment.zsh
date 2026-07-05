# Homebrew-relative paths (mac-arm /opt/homebrew, mac-intel /usr/local, linuxbrew).
if command -v brew >/dev/null 2>&1; then
  _brew_prefix="$(brew --prefix)"
  export PATH="$_brew_prefix/bin:$_brew_prefix/sbin:$PATH"
  unset _brew_prefix
fi

# User-local bins.
export PATH="$HOME/.local/bin:$PATH"      # pipx (ansible, ansible-lint, yamllint)
export PATH="$HOME/.opencode/bin:$PATH"   # opencode

# Tool config locations.
export K9S_CONFIG_DIR="$HOME/.config/k9s"
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

# Homebrew behaviour.
export HOMEBREW_NO_AUTO_UPDATE=1

# mise runtime version manager.
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# Warp ships its own input editor; flag it so later modules skip redundant
# shell UI (autosuggest, syntax-highlight, fzf-tab, starship, atuin keybind).
[[ "$TERM_PROGRAM" == "WarpTerminal" ]] && export _IN_WARP=1

# Deduplicate PATH.
typeset -U PATH path
