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
