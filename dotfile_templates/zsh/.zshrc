#! /bin/zsh

if [[ $(uname -s) == 'Darwin' ]] && [[ $(uname -m) == 'arm64' ]]; then
  #  if M1 mac then use the following
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Load configs
for config (~/.config/zsh/*.zsh) source $config

# WORK ZSHRC
if test -f ~/.zshrc_company; then
  source ~/.zshrc_company
fi

# Load ASDF
source $(brew --prefix asdf)/libexec/asdf.sh

# Configure PNPM
# pnpm
export PNPM_HOME="/Users/maxjerin/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
