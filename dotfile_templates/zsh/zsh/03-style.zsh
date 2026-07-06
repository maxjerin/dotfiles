# Prompt (skip inside Warp — it renders its own prompt UI).
if [[ -z "$_IN_WARP" ]] && command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
