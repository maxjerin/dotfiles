# =============================================================================
# Fish config — Warp-like interactive shell for Ghostty / Supacode
#
# Fish provides the two Warp features that a terminal emulator cannot:
#   • Ghost-text autosuggestions as you type  (native — accept with → / Ctrl-F)
#   • Rich tab completions                     (native + carapace bridges)
# The remaining Warp-like pieces are layered in below.
# =============================================================================

# -----------------------------------------------------------------------------
# PATH (ported from .zshrc)
# -----------------------------------------------------------------------------
fish_add_path /Users/maxjerin/.local/bin       # pipx
fish_add_path /Users/maxjerin/.opencode/bin    # opencode

# -----------------------------------------------------------------------------
# Interactive-only setup
# -----------------------------------------------------------------------------
if status is-interactive
    # --- mise: runtime version manager ---
    mise activate fish | source

    # --- atuin: SQLite history, fuzzy Ctrl-R = "next command" recall ---
    #   Ctrl-R = atuin search. Up-arrow kept fish-native (drop the flag to let
    #   atuin own Up too).
    atuin init fish --disable-up-arrow | source

    # --- carapace: cross-shell rich completion menus (Warp-like) ---
    set -gx CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'
    carapace _carapace fish | source

    # --- zoxide: smart `cd` (z / zi) ---
    zoxide init fish | source

    # --- fzf: fuzzy file/dir picker key bindings (Ctrl-T, Alt-C) ---
    fzf --fish | source

    # --- starship prompt (command duration, exit code, git status) ---
    starship init fish | source

    # --- Autosuggestion color tweak (subtle gray ghost text, Warp-ish) ---
    set -g fish_color_autosuggestion 555
end
