# Portable zsh entrypoint — same file on macOS and Linux.
# Interactive config lives in ~/.config/zsh/[0-9]*.zsh (stowed separately).

# OS-aware Homebrew bootstrap — first existing prefix wins.
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [ -x "$_brew" ]; then
    eval "$("$_brew" shellenv)"
    break
  fi
done
unset _brew

# Load modular config in numeric order.
for _f in "$HOME"/.config/zsh/[0-9]*.zsh; do
  [ -r "$_f" ] && source "$_f"
done
unset _f
