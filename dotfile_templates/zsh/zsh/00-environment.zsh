export PATH=$(brew --prefix)/bin:$PATH
export PATH=$(brew --prefix)/sbin:$PATH

# K9S
export K9S_CONFIG_DIR=~/.config/k9s

# Starship
export STARSHIP_CONFIG=~/.config/starship/starship.toml

# Disable Homebrew autoupdates
export HOMEBREW_NO_AUTO_UPDATE=1

# Remove all duplicates from $PATH
typeset -U PATH
