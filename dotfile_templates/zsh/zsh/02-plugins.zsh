_brew_prefix="$(brew --prefix 2>/dev/null)"

# Abbreviations (zsh-abbr).
[ -r "$_brew_prefix/share/zsh-abbr/zsh-abbr.zsh" ] && \
  source "$_brew_prefix/share/zsh-abbr/zsh-abbr.zsh"

# Ghost-text autosuggestions (skip inside Warp — it has its own).
if [[ -z "$_IN_WARP" ]] && \
   [ -r "$_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Completions.
FPATH="$_brew_prefix/share/zsh-completions:$FPATH"
autoload -Uz compinit
if [ -n "$(find -L ~/.zcompdump -prune -mtime +1 2>/dev/null)" ] || [ ! -e ~/.zcompdump ]; then
  compinit
else
  compinit -C
fi
zstyle ':completion:*' menu select

# carapace — cross-shell rich completions.
if command -v carapace >/dev/null 2>&1; then
  export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
  source <(carapace _carapace zsh)
fi

# fzf-tab — fzf-driven completion menus (skip inside Warp).
if [[ -z "$_IN_WARP" ]] && [ -r ~/.config/zsh/fzf-tab/fzf-tab.plugin.zsh ]; then
  source ~/.config/zsh/fzf-tab/fzf-tab.plugin.zsh
fi

# fzf key bindings.
[ -r ~/.fzf.zsh ] && source ~/.fzf.zsh

# Syntax highlighting — MUST be sourced last (skip inside Warp).
if [[ -z "$_IN_WARP" ]] && \
   [ -r "$_brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$_brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

unset _brew_prefix
