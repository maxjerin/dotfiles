######### Theme ############

if type brew &>/dev/null; then
  # SPACESHIP_PROMPT_ADD_NEWLINE=true
  # SPACESHIP_PROMPT_SEPARATE_LINE=false
  # source $(brew --prefix)/share/zsh/site-functions/prompt_spaceship_setup

  # TODO: Try this
  # https://github.com/pbar1/dotfiles/blob/master/.config/starship.toml
  eval "$(starship init zsh)"
fi

# Powerline Go Setup
: '
if [[ $(uname -s) == 'Darwin' ]]; then
  export PATH=$PATH:$(brew --prefix)/bin
  POWERLINE_GO=$(brew --prefix)/bin/powerline-go

  function powerline_precmd() {
    PS1="$($POWERLINE_GO -error $? -jobs ${${(%):%j}:-0})"

    # Uncomment the following line to automatically clear errors after showing
    # them once. This not only clears the error for powerline-go, but also for
    # everything else you run in that shell. Don't enable this if you're not
    # sure this is what you want.

    #set "?"
  }

  function install_powerline_precmd() {
    for s in "${precmd_functions[@]}"; do
      if [ "$s" = "powerline_precmd" ]; then
        return
      fi
    done
    precmd_functions+=(powerline_precmd)
  }

  if [ "$TERM" != "linux" ] && [ -f "$POWERLINE_GO" ]; then
    install_powerline_precmd
  fi

  # Newline after terminal
  prompt_end() {
   if [[ -n $CURRENT_BG ]]; then
       print -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
   else
       print -n "%{%k%}"
   fi

   print -n "%{%f%}"
   CURRENT_BG=''

   # Adds the new line and ➜ as the start character.
   printf "\n ➜";
  }
fi
: '


######### Theme ############
