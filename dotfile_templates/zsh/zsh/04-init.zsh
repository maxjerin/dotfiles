# Rebuild combined abbreviations only when a source file is newer (idempotent).
_abbr_dir="$HOME/.config/zsh"
_abbr_out="$_abbr_dir/abbreviations"
if [ "$_abbr_dir/abbreviations_common" -nt "$_abbr_out" ] || \
   [ "$_abbr_dir/abbreviations_work" -nt "$_abbr_out" ] || \
   [ ! -e "$_abbr_out" ]; then
  cat "$_abbr_dir/abbreviations_common" "$_abbr_dir/abbreviations_work" \
    > "$_abbr_out" 2>/dev/null
fi
command -v abbr >/dev/null 2>&1 && abbr load
unset _abbr_dir _abbr_out

# macOS-only integrations.
if [[ "$OSTYPE" == darwin* ]]; then
  # 1Password SSH agent socket.
  _op_sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  if [ -S "$_op_sock" ]; then
    mkdir -p "$HOME/.1password"
    ln -sfn "$_op_sock" "$HOME/.1password/agent.sock"
  fi
  unset _op_sock

  # pnpm.
  export PNPM_HOME="$HOME/Library/pnpm"
  case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
  esac
fi

# zoxide — smart cd.
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# atuin — SQLite history; Ctrl-R recall, Up-arrow stays zsh-native.
# Skip inside Warp (Warp owns Ctrl-R / its own history palette).
if [[ -z "$_IN_WARP" ]] && command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

# OrbStack shell init (macOS).
[ -r "$HOME/.orbstack/shell/init.zsh" ] && \
  source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null

# tmux plugin manager (idempotent clone).
if command -v tmux >/dev/null 2>&1 && [ ! -d "$HOME/.config/tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
fi

# Alacritty themes (idempotent clone).
if command -v alacritty >/dev/null 2>&1 && [ ! -d "$HOME/.config/alacritty/themes" ]; then
  git clone https://github.com/alacritty/alacritty-theme "$HOME/.config/alacritty/themes"
fi
