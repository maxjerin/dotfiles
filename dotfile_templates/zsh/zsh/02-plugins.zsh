source "$(brew --prefix)/share/zsh-abbr/zsh-abbr.zsh"
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
# source "$(brew --prefix)/etc/profile.d/z.sh"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
FPATH="$(brew --prefix)/share/zsh-completions:$FPATH"
autoload -Uz compinit
for dump in ~/.zcompdump(N.mh+24); do
  compinit
done
compinit -C
zstyle ':completion:*' menu select
