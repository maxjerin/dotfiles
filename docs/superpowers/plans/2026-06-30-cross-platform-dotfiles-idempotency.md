# Cross-Platform Dotfiles Idempotency Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the dotfiles repo idempotent (re-running bootstrap or re-launching a shell converges to the same state) and cross-platform (macOS + Linux desktop), delivering Warp-like zsh UX (autosuggest, syntax-highlight, rich completions, history recall).

**Architecture:** Keep the existing Ansible + GNU Stow hybrid. Collapse OS path differences into `$(brew --prefix)` + `command -v` guards + `[[ $OSTYPE == darwin* ]]` gates. A single portable `.zshrc` loader sources the (currently orphaned) modular `~/.config/zsh/*.zsh` config. Bootstrap scripts share a `bootstrap-common.sh` core. Fish work from a prior session is fully reverted.

**Tech Stack:** zsh, GNU Stow, Ansible, Homebrew (mac `/opt/homebrew` or `/usr/local`, Linux `/home/linuxbrew/.linuxbrew`), starship, zoxide, atuin, carapace, fzf-tab, zsh-abbr.

## Global Constraints

- Target shell is **zsh** on both macOS and Linux desktop. No fish.
- No hardcoded `/Users/maxjerin` or `/opt/homebrew` in stowed files — use `$HOME` and `$(brew --prefix)`; macOS-only paths must be gated by `[[ "$OSTYPE" == darwin* ]]`.
- Every shell-init side effect (symlink, file generation, clone) must be idempotent: `ln -sfn`, generate-only-when-changed, `[ ! -d ] && git clone`.
- Every bootstrap step must be safe to re-run: guard `/etc/shells` appends with `grep -q`, `chsh` only when `$SHELL` differs, `mkdir -p` before copies.
- Ansible file operations use `ansible.builtin.file`/`copy` (not raw `command:`); OS-specific task includes carry `when: ansible_os_family == 'Debian'`.
- Terminal-agnostic: the Warp-like UX lives in the zsh modules and works in any host terminal. Inside Warp (`$TERM_PROGRAM=WarpTerminal`) the shell skips its input-editor plugins (autosuggest, syntax-highlight, fzf-tab, starship, atuin keybind) so they don't fight Warp's native UI.
- Work happens on branch `dotfiles-idempotency-rewrite`. Commit after each task.
- This machine is macOS — Linux-only paths are verified by static checks (syntax, lint, grep, `stow -n`), not execution.

---

### Task 1: Revert all fish work

**Files:**
- Delete: `dotfile_templates/fish/` (whole dir)
- Modify: `roles/system/vars/main.yml` (remove `fish` line)
- Modify: `bootstrap-macos.sh:199-201` (remove fish stow block)

**Interfaces:**
- Produces: a repo with no fish references; `atuin`, `carapace` remain in `formulas_common`.

- [ ] **Step 1: Remove the fish template dir**

```bash
cd /Users/maxjerin/Development/repos/dotfiles
git rm -r --cached dotfile_templates/fish 2>/dev/null; rm -rf dotfile_templates/fish
```

- [ ] **Step 2: Remove `fish` from formulas_common**

In `roles/system/vars/main.yml`, delete the line:
```yaml
    - fish  # primary interactive shell (native autosuggestions + completions)
```
Leave `atuin` and `carapace` lines intact.

- [ ] **Step 3: Remove the fish stow block from bootstrap-macos.sh**

Delete these lines (added in a prior session):
```bash
    # Fish shell (Warp-like interactive shell)
    mkdir -p ~/.config/fish
    stow --adopt -R --target ~/.config/fish fish
```
(Leave the ghostty block — Task 8 moves it to the shared core.)

- [ ] **Step 4: Verify no fish references remain**

Run: `grep -rn 'fish' dotfile_templates/ bootstrap-*.sh roles/system/vars/main.yml | grep -iv 'selfish\|finish'`
Expected: no matches (empty output).

- [ ] **Step 5: Unstow live fish config and revert login shell (interactive — run manually)**

```bash
stow -D -t ~/.config/fish fish 2>/dev/null; rm -rf ~/.config/fish
grep -q "$(command -v zsh)" /etc/shells || true
chsh -s "$(command -v zsh)"   # password prompt; only if $SHELL is fish
```
Expected: `dscl . -read $HOME UserShell` (mac) shows `/bin/zsh` or brew zsh.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "Revert fish: remove template, formula, stow block (zsh is the shell)"
```

---

### Task 2: Delete orphan nvim template dirs

**Files:**
- Delete: `dotfile_templates/neovim/`, `dotfile_templates/nvim/`

**Interfaces:**
- Produces: no orphan template dirs; every remaining `dotfile_templates/*` is stowed by Task 8's list.

- [ ] **Step 1: Confirm neither is referenced by bootstrap**

Run: `grep -rn 'neovim\|nvim' bootstrap-*.sh`
Expected: no matches.

- [ ] **Step 2: Delete both dirs**

```bash
cd /Users/maxjerin/Development/repos/dotfiles
git rm -r --cached dotfile_templates/neovim dotfile_templates/nvim 2>/dev/null
rm -rf dotfile_templates/neovim dotfile_templates/nvim
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "Remove orphan neovim/nvim template dirs (never stowed, unused)"
```

---

### Task 3: Portable `.zshrc` loader and `.zprofile`

**Files:**
- Modify (replace contents): `dotfile_templates/zsh/.zshrc`
- Modify (replace contents): `dotfile_templates/zsh/.zprofile`
- Delete: `dotfile_templates/zsh/.zshrc_linux`

**Interfaces:**
- Produces: a `.zshrc` that bootstraps brew OS-agnostically then sources `~/.config/zsh/[0-9]*.zsh` in order. Consumed by Tasks 4-7 (the modular files).

- [ ] **Step 1: Write the new `.zshrc`**

Replace `dotfile_templates/zsh/.zshrc` entirely with:
```zsh
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
```

- [ ] **Step 2: Write the new `.zprofile`**

Replace `dotfile_templates/zsh/.zprofile` entirely with:
```zsh
# Login-shell PATH bootstrap. Interactive config is in .zshrc.
export PATH="$HOME/.local/bin:$PATH"
```

- [ ] **Step 3: Delete `.zshrc_linux`**

```bash
cd /Users/maxjerin/Development/repos/dotfiles
git rm --cached dotfile_templates/zsh/.zshrc_linux 2>/dev/null
rm -f dotfile_templates/zsh/.zshrc_linux
```

- [ ] **Step 4: Syntax-check both files**

Run: `zsh -n dotfile_templates/zsh/.zshrc && zsh -n dotfile_templates/zsh/.zprofile && echo OK`
Expected: `OK`

- [ ] **Step 5: Verify no hardcoded paths remain**

Run: `grep -n '/Users/maxjerin\|/opt/homebrew' dotfile_templates/zsh/.zshrc dotfile_templates/zsh/.zprofile`
Expected: no matches.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "zsh: portable .zshrc loader + minimal .zprofile, drop .zshrc_linux"
```

---

### Task 4: Rewrite `00-environment.zsh`

**Files:**
- Modify (replace contents): `dotfile_templates/zsh/zsh/00-environment.zsh`

**Interfaces:**
- Consumes: `brew` on PATH (from `.zshrc` bootstrap).
- Produces: PATH with brew bin/sbin, `$HOME/.local/bin`, `$HOME/.opencode/bin`; exports `K9S_CONFIG_DIR`, `STARSHIP_CONFIG`, `HOMEBREW_NO_AUTO_UPDATE`; activates mise. Consumed by all later modules.

- [ ] **Step 1: Write the file**

Replace `dotfile_templates/zsh/zsh/00-environment.zsh` entirely with:
```zsh
# Homebrew-relative paths (mac-arm /opt/homebrew, mac-intel /usr/local, linuxbrew).
if command -v brew >/dev/null 2>&1; then
  _brew_prefix="$(brew --prefix)"
  export PATH="$_brew_prefix/bin:$_brew_prefix/sbin:$PATH"
  unset _brew_prefix
fi

# User-local bins.
export PATH="$HOME/.local/bin:$PATH"      # pipx (ansible, ansible-lint, yamllint)
export PATH="$HOME/.opencode/bin:$PATH"   # opencode

# Tool config locations.
export K9S_CONFIG_DIR="$HOME/.config/k9s"
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

# Homebrew behaviour.
export HOMEBREW_NO_AUTO_UPDATE=1

# mise runtime version manager.
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# Warp ships its own input editor; flag it so later modules skip redundant
# shell UI (autosuggest, syntax-highlight, fzf-tab, starship, atuin keybind).
[[ "$TERM_PROGRAM" == "WarpTerminal" ]] && export _IN_WARP=1

# Deduplicate PATH.
typeset -U PATH path
```

- [ ] **Step 2: Syntax-check**

Run: `zsh -n dotfile_templates/zsh/zsh/00-environment.zsh && echo OK`
Expected: `OK`

- [ ] **Step 3: Verify no hardcoded paths**

Run: `grep -n '/Users/maxjerin\|/opt/homebrew' dotfile_templates/zsh/zsh/00-environment.zsh`
Expected: no matches.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "zsh: portable 00-environment (brew --prefix, \$HOME, mise guard)"
```

---

### Task 5: Rewrite `02-plugins.zsh` (carapace + fzf-tab)

**Files:**
- Modify (replace contents): `dotfile_templates/zsh/zsh/02-plugins.zsh`

**Interfaces:**
- Consumes: `brew` on PATH; `~/.config/zsh/fzf-tab/` cloned by Task 8.
- Produces: sourced zsh-abbr, zsh-autosuggestions, zsh-completions, carapace, fzf-tab, fzf bindings, and zsh-syntax-highlighting (last). `abbr` command available for Task 7.

- [ ] **Step 1: Write the file**

Replace `dotfile_templates/zsh/zsh/02-plugins.zsh` entirely with:
```zsh
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
```

- [ ] **Step 2: Syntax-check**

Run: `zsh -n dotfile_templates/zsh/zsh/02-plugins.zsh && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "zsh: 02-plugins adds carapace + fzf-tab, guards all sources"
```

---

### Task 6: Rewrite `03-style.zsh`

**Files:**
- Modify (replace contents): `dotfile_templates/zsh/zsh/03-style.zsh`

**Interfaces:**
- Consumes: `starship` on PATH.
- Produces: starship prompt initialized. Removes the dead powerline-go block.

- [ ] **Step 1: Write the file**

Replace `dotfile_templates/zsh/zsh/03-style.zsh` entirely with:
```zsh
# Prompt (skip inside Warp — it renders its own prompt UI).
if [[ -z "$_IN_WARP" ]] && command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
```

- [ ] **Step 2: Syntax-check**

Run: `zsh -n dotfile_templates/zsh/zsh/03-style.zsh && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "zsh: 03-style keeps starship, drops dead powerline-go block"
```

---

### Task 7: Rewrite `04-init.zsh` (atuin + idempotency + OS guards)

**Files:**
- Modify (replace contents): `dotfile_templates/zsh/zsh/04-init.zsh`

**Interfaces:**
- Consumes: `abbr` (Task 5), `zoxide`, `atuin`, `tmux`, `alacritty` on PATH when present.
- Produces: combined `~/.config/zsh/abbreviations` (rebuilt only when stale), macOS-gated 1Password+pnpm, zoxide + atuin init, guarded tpm/alacritty clones.

- [ ] **Step 1: Write the file**

Replace `dotfile_templates/zsh/zsh/04-init.zsh` entirely with:
```zsh
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
```

- [ ] **Step 2: Syntax-check**

Run: `zsh -n dotfile_templates/zsh/zsh/04-init.zsh && echo OK`
Expected: `OK`

- [ ] **Step 3: Verify hardcoded macOS paths are OS-gated**

Run: `grep -n 'Library\|/Applications' dotfile_templates/zsh/zsh/04-init.zsh`
Expected: only `Library` lines (1Password, pnpm) — all inside the `darwin*` block; no `/Applications`.

- [ ] **Step 4: Idempotency smoke test (sources twice cleanly)**

Run:
```bash
zsh -ic 'source dotfile_templates/zsh/zsh/04-init.zsh; source dotfile_templates/zsh/zsh/04-init.zsh; echo TWICE_OK' 2>&1 | tail -1
```
Expected: `TWICE_OK` with no `ln:` or `File exists` errors.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "zsh: 04-init adds atuin, idempotent symlink/abbr, OS-gates mac paths"
```

---

### Task 8: `bootstrap-common.sh` with shared idempotent core

**Files:**
- Create: `bootstrap-common.sh`

**Interfaces:**
- Produces functions sourced by both OS scripts: `command_exists()`, `install_git_hooks()`, `setup_dotfiles_common()`, `ensure_login_shell()`, `clone_zsh_plugins()`. Consumes env var `STOW_OS_EXTRA` (space-separated OS-only stow dirs, e.g. `karabiner`) set by the caller.

- [ ] **Step 1: Write `bootstrap-common.sh`**

Create `bootstrap-common.sh` with:
```bash
#!/usr/bin/env bash
# Shared, idempotent bootstrap helpers sourced by bootstrap-{macos,linux}.sh.

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install git pre-commit hook (idempotent: mkdir guard + overwrite-safe copy).
install_git_hooks() {
    mkdir -p .git/hooks
    if [ -f repo_config/pre-commit ]; then
        cp repo_config/pre-commit .git/hooks/pre-commit
        chmod +x .git/hooks/pre-commit
    fi
}

# Clone shell plugins not available via package managers (idempotent).
clone_zsh_plugins() {
    mkdir -p ~/.config/zsh
    if [ ! -d ~/.config/zsh/fzf-tab ]; then
        git clone https://github.com/Aloxaf/fzf-tab ~/.config/zsh/fzf-tab
    fi
}

# Stow all shared configs plus any OS-only dirs in $STOW_OS_EXTRA.
setup_dotfiles_common() {
    if ! command_exists stow; then
        echo "Error: Stow is required but not installed" >&2
        return 1
    fi
    echo "Setting up dotfiles with Stow..."
    pushd dotfile_templates > /dev/null

    # zsh: .zshrc/.zprofile to ~, modular config to ~/.config/zsh
    stow --adopt -R --no-folding --target ~ zsh
    pushd zsh > /dev/null
    mkdir -p ~/.config/zsh
    stow --adopt -R --target ~/.config/zsh zsh
    popd > /dev/null

    local dir
    for dir in starship alacritty tmux kitty ghostty; do
        mkdir -p "$HOME/.config/$dir"
        stow --adopt -R --target "$HOME/.config/$dir" "$dir"
    done

    # k9s + nested skins
    mkdir -p ~/.config/k9s/skins
    stow --adopt -R --target ~/.config/k9s k9s
    pushd k9s > /dev/null
    stow --adopt -R --target ~/.config/k9s/skins skins
    popd > /dev/null

    # Warp themes live under ~/.warp (not ~/.config); both OSes run Warp.
    mkdir -p ~/.warp/themes
    stow --adopt -R --target ~/.warp warp

    # OS-only extras (e.g. karabiner on macOS).
    for dir in $STOW_OS_EXTRA; do
        mkdir -p "$HOME/.config/$dir"
        stow --adopt -R --no-folding --target "$HOME/.config/$dir" "$dir"
    done

    popd > /dev/null
}

# Idempotently make zsh the login shell.
ensure_login_shell() {
    local zsh_path
    zsh_path="$(command -v zsh)"
    [ -z "$zsh_path" ] && { echo "zsh not found; skipping shell switch" >&2; return 0; }
    if ! grep -qx "$zsh_path" /etc/shells; then
        echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
    fi
    if [ "$SHELL" != "$zsh_path" ]; then
        chsh -s "$zsh_path"
    fi
}
```

- [ ] **Step 2: Lint with shellcheck**

Run: `shellcheck bootstrap-common.sh`
Expected: no errors (SC2086 on `$STOW_OS_EXTRA` is intentional word-splitting; add `# shellcheck disable=SC2086` above that loop if flagged).

- [ ] **Step 3: Make executable and commit**

```bash
chmod +x bootstrap-common.sh
git add -A
git commit -m "bootstrap: shared idempotent core (hooks, stow list, shell switch, plugin clone)"
```

---

### Task 9: Refactor `bootstrap-macos.sh` / `bootstrap-linux.sh` to use the common core

**Files:**
- Modify: `bootstrap-macos.sh` (replace `command_exists`, `setup_dotfiles`, hooks block, shell switch)
- Modify: `bootstrap-linux.sh` (same)

**Interfaces:**
- Consumes: `bootstrap-common.sh` functions.
- Produces: both scripts source common, set `STOW_OS_EXTRA`, and call shared functions. macOS sets `STOW_OS_EXTRA="karabiner"`; Linux sets `STOW_OS_EXTRA=""`.

- [ ] **Step 1: Source common near the top of `bootstrap-macos.sh`**

After the `SCRIPT_DIR`/`cd` lines, add:
```bash
# shellcheck source=bootstrap-common.sh
source "$SCRIPT_DIR/bootstrap-common.sh"
export STOW_OS_EXTRA="karabiner"
```
Delete the local `command_exists()` definition and the inline `.git/hooks/pre-commit` copy block; replace the latter with a call to `install_git_hooks`.

- [ ] **Step 2: Replace macOS `setup_dotfiles()` body**

Replace the entire `setup_dotfiles()` function in `bootstrap-macos.sh` with:
```bash
setup_dotfiles() {
    clone_zsh_plugins
    setup_dotfiles_common
}
```

- [ ] **Step 3: Mirror changes in `bootstrap-linux.sh`**

After its `SCRIPT_DIR`/`cd` lines, add:
```bash
# shellcheck source=bootstrap-common.sh
source "$SCRIPT_DIR/bootstrap-common.sh"
export STOW_OS_EXTRA=""
```
Delete its local `command_exists()` and inline hooks block (call `install_git_hooks` instead). Replace its `setup_dotfiles()` with:
```bash
setup_dotfiles() {
    clone_zsh_plugins
    setup_dotfiles_common
}
```
Replace its `setup_zsh_shell()` body (the `tee -a /etc/shells` + chsh block) with a call to `ensure_login_shell`.

- [ ] **Step 4: Ensure macOS also sets the login shell**

In `bootstrap-macos.sh` `main()`, add `ensure_login_shell` after `setup_dotfiles` (macOS previously never switched shells).

- [ ] **Step 5: Lint both scripts**

Run: `shellcheck -x bootstrap-macos.sh bootstrap-linux.sh`
Expected: no errors.

- [ ] **Step 6: Verify duplication removed**

Run: `grep -c 'command_exists()' bootstrap-macos.sh bootstrap-linux.sh`
Expected: `0` for both (definition now only in common; calls remain).

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "bootstrap: macos/linux source shared core, dedupe, mac switches to zsh"
```

---

### Task 10: `vars/main.yml` cleanup

**Files:**
- Modify: `roles/system/vars/main.yml`

**Interfaces:**
- Produces: `zsh` in `formulas_common`; `zoxide` standardized; `z`/`spaceship` removed; karabiner commented mac-only. (`fish` already removed in Task 1.)

- [ ] **Step 1: Move `zsh` into formulas_common**

Add `- zsh` to `formulas_common` (alphabetical). Remove `- zsh` from `formulas_linux` and `formulas_macos`.

- [ ] **Step 2: Standardize on zoxide**

Add `- zoxide` to `formulas_common`. Remove `- zoxide` from `formulas_macos`. Remove `- z` and `- spaceship` from `formulas_linux` (starship in common replaces spaceship; zoxide replaces z).

- [ ] **Step 3: Annotate karabiner as macOS-only**

Confirm `- karabiner-elements` under `casks_macos_only` has a trailing comment `# macOS-only keyboard remapper` (it already does). No Linux equivalent added (out of scope).

- [ ] **Step 4: Lint YAML**

Run: `yamllint roles/system/vars/main.yml && echo OK`
Expected: `OK` (or only pre-existing warnings unrelated to these lines).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "ansible vars: zsh+zoxide to common, drop z/spaceship duplicates"
```

---

### Task 11: De-duplicate Arc/Warp `duti` tasks

**Files:**
- Modify: `roles/system/tasks/macos.yml:48-112` (remove the two duti tasks)

**Interfaces:**
- Produces: Arc browser + Warp SSH duti handlers defined only in `roles/system/tasks/macos/defaults.yml`.

- [ ] **Step 1: Confirm the duplication**

Run: `grep -rn 'duti' roles/system/tasks/macos.yml roles/system/tasks/macos/defaults.yml`
Expected: matches in BOTH files (the duplication).

- [ ] **Step 2: Remove the duti tasks from `macos.yml`**

Delete the "Set Arc browser via duti" task (lines ~48-85) and the "Set Warp SSH handler via duti" task (lines ~87-112) from `roles/system/tasks/macos.yml`. Keep the copies in `macos/defaults.yml`.

- [ ] **Step 3: Verify defaults.yml is included**

Run: `grep -rn 'defaults.yml' roles/system/tasks/`
Expected: a matching `include_tasks` (or `import_tasks`) referencing it. If absent, add `- import_tasks: macos/defaults.yml` to `roles/system/tasks/macos.yml` so the kept copies still run.

- [ ] **Step 4: Syntax check**

Run: `ansible-playbook dotfiles.yml --syntax-check`
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "ansible: remove duplicate Arc/Warp duti tasks (keep defaults.yml copy)"
```

---

### Task 12: `keyboard_mapping/linux.yml` → file module + typo fix

**Files:**
- Modify: `roles/keyboard_mapping/tasks/linux.yml:59-105`
- Modify: `roles/keyboard_mapping/tasks/main.yml` (OS guard)

**Interfaces:**
- Produces: idempotent xkb dir/file creation via `ansible.builtin.file`; corrected `.xkb` path; OS-guarded include.

- [ ] **Step 1: Replace the mkdir/touch command tasks**

In `roles/keyboard_mapping/tasks/linux.yml`, replace:
- the `command: mkdir -p ~/.xkb/keymap` task (lines ~59-64) with:
```yaml
- name: Ensure xkb keymap directory exists
  ansible.builtin.file:
    path: "{{ ansible_env.HOME }}/.xkb/keymap"
    state: directory
    mode: "0755"
```
- the `command: touch ~/.xkbd/keymap/mykbd` task (lines ~66-71, note `.xkbd` typo) with:
```yaml
- name: Ensure xkb keymap file exists
  ansible.builtin.file:
    path: "{{ ansible_env.HOME }}/.xkb/keymap/mykbd"
    state: touch
    mode: "0644"
```
- the `command: mkdir -p ~/.xkb/symbols` task (lines ~81-86) with:
```yaml
- name: Ensure xkb symbols directory exists
  ansible.builtin.file:
    path: "{{ ansible_env.HOME }}/.xkb/symbols"
    state: directory
    mode: "0755"
```

- [ ] **Step 2: Guard the print/xkbcomp commands**

For the `setxkbmap -print > ~/.xkb/keymap/mykbd` task (lines ~74-79) and the `xkbcomp` apply task (lines ~100-105), keep them as `command:` but make the dump idempotent with `creates`/`changed_when` reflecting real change. Minimal acceptable form for the dump:
```yaml
- name: Generate xkb keymap
  ansible.builtin.shell: setxkbmap -print > "{{ ansible_env.HOME }}/.xkb/keymap/mykbd"
  args:
    creates: "{{ ansible_env.HOME }}/.xkb/keymap/mykbd"
```
Leave `xkbcomp` with `changed_when: true` but add a comment `# applies keymap each run by design (no reliable state probe)`.

- [ ] **Step 3: Add OS guard to the include**

In `roles/keyboard_mapping/tasks/main.yml`, ensure the `include_tasks: linux.yml` carries:
```yaml
  when: ansible_os_family == 'Debian'
```

- [ ] **Step 4: Lint**

Run: `ansible-lint roles/keyboard_mapping/ ; yamllint roles/keyboard_mapping/`
Expected: no new errors (the `.xkbd` typo and `command`-for-file findings gone).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "ansible(keyboard): file module + fix .xkbd typo + OS guard"
```

---

### Task 13: `fonts/linux.yml` → copy module + OS guard

**Files:**
- Modify: `roles/fonts/tasks/linux.yml:30-39`
- Modify: `roles/fonts/tasks/main.yml` (OS guard)

**Interfaces:**
- Produces: idempotent font install via `ansible.builtin.copy` with `creates`-style dest check; OS-guarded include.

- [ ] **Step 1: Replace the `mv` font tasks**

In `roles/fonts/tasks/linux.yml`, replace the `command: mv ... PowerlineSymbols.otf /usr/share/fonts` task with:
```yaml
- name: Install Powerline symbols font
  ansible.builtin.copy:
    src: "{{ powerline_src_dir }}/PowerlineSymbols.otf"
    dest: /usr/share/fonts/PowerlineSymbols.otf
    remote_src: true
    mode: "0644"
  become: true
```
and the `mv ... 10-powerline-symbols.conf /etc/fonts/conf.d` task with:
```yaml
- name: Install Powerline fontconfig
  ansible.builtin.copy:
    src: "{{ powerline_src_dir }}/10-powerline-symbols.conf"
    dest: /etc/fonts/conf.d/10-powerline-symbols.conf
    remote_src: true
    mode: "0644"
  become: true
```
Define `powerline_src_dir` as a `vars:` or `set_fact` matching wherever the files are downloaded earlier in the task file (use the existing download dir variable if present).

- [ ] **Step 2: Add OS guard to the include**

In `roles/fonts/tasks/main.yml`, ensure `include_tasks: linux.yml` carries `when: ansible_os_family == 'Debian'`.

- [ ] **Step 3: Lint**

Run: `ansible-lint roles/fonts/ ; yamllint roles/fonts/`
Expected: no new errors.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "ansible(fonts): copy module (idempotent) + OS guard on linux include"
```

---

### Task 14: `apt.yml` curl|bash guard

**Files:**
- Modify: `roles/productivity/tasks/apt.yml:26-28`

**Interfaces:**
- Produces: the packagecloud repo-setup script runs only once (idempotent via `creates`).

- [ ] **Step 1: Add a creates guard to the curl|bash task**

Replace the `curl ... script.deb.sh | sudo bash` task with a `creates` guard on the apt source file it produces:
```yaml
- name: Add packagecloud apt repository
  ansible.builtin.shell: |
    curl -s https://packagecloud.io/install/repositories/<repo>/script.deb.sh | sudo bash
  args:
    creates: /etc/apt/sources.list.d/<repo>.list
  when: ansible_os_family == 'Debian'
```
Use the actual repo name from the existing line for `<repo>` and the matching `sources.list.d` filename it generates (verify by reading the current task).

- [ ] **Step 2: Lint**

Run: `ansible-lint roles/productivity/tasks/apt.yml ; yamllint roles/productivity/tasks/apt.yml`
Expected: no new errors.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "ansible(apt): guard packagecloud repo script with creates (idempotent)"
```

---

### Task 15: Generate Warp theme templates

**Files:**
- Create: `dotfile_templates/warp/themes/warp-dark.yaml`
- Create: `dotfile_templates/warp/themes/warp-light.yaml`

**Interfaces:**
- Consumes: the existing Ghostty palettes in `dotfile_templates/ghostty/themes/warp-dark` and `warp-light` (One Dark / light equivalents).
- Produces: Warp-format theme YAMLs stowed to `~/.warp/themes` by Task 8, giving Warp the same light/dark colors as Ghostty.

- [ ] **Step 1: Write `warp-dark.yaml`**

Create `dotfile_templates/warp/themes/warp-dark.yaml` with:
```yaml
# Warp Dark — matches the Ghostty warp-dark theme (One Dark palette).
accent: '#61AFEF'
background: '#1B1F27'
foreground: '#F2F2F2'
details: darker
terminal_colors:
  normal:
    black: '#1B1F27'
    red: '#E06C75'
    green: '#98C379'
    yellow: '#E5C07B'
    blue: '#61AFEF'
    magenta: '#C678DD'
    cyan: '#56B6C2'
    white: '#ABB2BF'
  bright:
    black: '#808080'
    red: '#E06C75'
    green: '#98C379'
    yellow: '#E5C07B'
    blue: '#61AFEF'
    magenta: '#C678DD'
    cyan: '#56B6C2'
    white: '#FFFFFF'
```

- [ ] **Step 2: Write `warp-light.yaml`**

Create `dotfile_templates/warp/themes/warp-light.yaml` with:
```yaml
# Warp Light — matches the Ghostty warp-light theme.
accent: '#2C5E96'
background: '#F6F7F9'
foreground: '#24282E'
details: lighter
terminal_colors:
  normal:
    black: '#24282E'
    red: '#BE3A3A'
    green: '#2D8B3C'
    yellow: '#A87B00'
    blue: '#2C5E96'
    magenta: '#7A3DAD'
    cyan: '#1A7A85'
    white: '#6B7480'
  bright:
    black: '#4A505A'
    red: '#D14545'
    green: '#3BA84C'
    yellow: '#C99400'
    blue: '#3A72B0'
    magenta: '#9250CC'
    cyan: '#2297A5'
    white: '#24282E'
```

- [ ] **Step 3: Validate YAML**

Run: `yamllint dotfile_templates/warp/themes/ && echo OK`
Expected: `OK`.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "warp: theme templates (dark/light) matching Ghostty palette"
```

> After stow, enable in Warp: Settings → Appearance → pick warp-dark / warp-light,
> and turn on "Sync with OS" so they auto-switch like Ghostty's `dark:/light:`.

---

### Task 16: Whole-repo verification gate

**Files:** none (verification only)

**Interfaces:**
- Consumes: all prior tasks.
- Produces: evidence the repo meets the spec's acceptance criteria.

- [ ] **Step 1: No hardcoded paths in stowed files**

Run: `grep -rn '/Users/maxjerin\|/opt/homebrew' dotfile_templates/`
Expected: no matches (all OS differences via `$HOME`/`$(brew --prefix)`/`darwin*` gates).

- [ ] **Step 2: All zsh modules syntax-clean**

Run: `for f in dotfile_templates/zsh/.zshrc dotfile_templates/zsh/.zprofile dotfile_templates/zsh/zsh/[0-9]*.zsh; do zsh -n "$f" || echo "FAIL $f"; done; echo DONE`
Expected: `DONE` with no `FAIL` lines.

- [ ] **Step 3: Bootstrap scripts lint-clean**

Run: `shellcheck -x bootstrap-common.sh bootstrap-macos.sh bootstrap-linux.sh && echo OK`
Expected: `OK`.

- [ ] **Step 4: Stow dry-run resolves (macOS profile)**

Run: `cd dotfile_templates && for d in zsh starship alacritty tmux kitty ghostty k9s karabiner; do stow -n -v --target ~ "$d" 2>&1 | head -1; done; mkdir -p ~/.warp && stow -n -v --target ~/.warp warp 2>&1 | head -1; cd ..`
Expected: no `existing target is not a symlink` conflicts (already-stowed dirs report nothing or LINK lines).

- [ ] **Step 4b: Warp guard works**

Run: `TERM_PROGRAM=WarpTerminal zsh -ic 'source dotfile_templates/zsh/zsh/00-environment.zsh; echo "warp=$_IN_WARP"'`
Expected: `warp=1` (so 02/03/04 skip the input-editor plugins inside Warp).

- [ ] **Step 5: Ansible syntax + lint**

Run: `ansible-playbook dotfiles.yml --syntax-check && ansible-lint && echo OK`
Expected: `OK` (or only pre-existing, unrelated warnings).

- [ ] **Step 6: Live shell idempotency check (run manually on macOS)**

Open a fresh terminal, then run `source ~/.zshrc; source ~/.zshrc`.
Expected: no warnings/errors; `echo $PATH | tr ':' '\n' | sort | uniq -d` prints nothing (no duplicate PATH entries); `command -v atuin carapace zoxide starship` all resolve.

- [ ] **Step 7: Final commit (if any verification fixes were needed)**

```bash
git add -A
git commit -m "Verify cross-platform idempotency rewrite (all gates green)" --allow-empty
```

---

## Self-Review

**Spec coverage:**
- §0 Terminal layer → Task 4 (Warp guard flag `_IN_WARP`), Tasks 5-7 (guarded plugins), Task 15 (Warp theme templates), Task 8 (Warp themes stow). ✓
- §1 Shell layer → Tasks 3-7 (loader, 00-02-03-04 modules, atuin+carapace+fzf-tab). ✓
- §2 Bootstrap layer → Tasks 8-9 (common core, refactor, idempotent shell switch, `/etc/shells` guard). ✓
- §3 Ansible layer → Tasks 10-14 (vars cleanup, duti dedup, keyboard file module + typo, fonts copy, apt guard, OS guards). ✓
- §4 Stow parity → Task 8 (ghostty + warp in shared list, karabiner via `STOW_OS_EXTRA`) + Task 2 (orphan delete). ✓
- §5 Fish revert → Task 1. ✓
- Verification → Task 16 maps the spec's acceptance tests (incl. Warp guard + stow). ✓

**Placeholder scan:** `<repo>` in Task 14 is an intentional read-from-current-file value with explicit instruction to substitute; `powerline_src_dir` in Task 13 is explicitly defined-from-existing-var. All code steps show complete code.

**Type/name consistency:** Common functions (`command_exists`, `install_git_hooks`, `clone_zsh_plugins`, `setup_dotfiles_common`, `ensure_login_shell`) are defined in Task 8 and consumed by the same names in Task 9. `STOW_OS_EXTRA` set in Task 9, consumed in Task 8. Consistent.

**Rollout order** matches spec §Rollout: fish revert (T1) → shell + Warp guard (T3-7) → stow parity/orphans (T2, T8) → bootstrap (T8-9) → ansible (T10-14) → Warp themes (T15) → verify (T16).
