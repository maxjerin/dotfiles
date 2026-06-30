# Cross-Platform Dotfiles — Idempotency Rewrite

**Date:** 2026-06-30
**Status:** Approved design, pending implementation plan
**Author:** brainstorming session (maxjerin + Claude)

## Goal

Make the dotfiles repo cleanly **idempotent** (every bootstrap run and every shell
launch converges to the same state, re-running is a no-op) and **cross-platform**
(macOS + Linux desktop) with a single source of truth. Deliver Warp-like
interactive UX (autosuggestions, syntax highlighting, rich completions, history
recall) in **zsh** on both OSes.

## Decisions (locked)

- **Shell:** zsh on both OSes (not fish). zsh + plugins gives ~90% of fish's
  interactive UX with full POSIX/bash-paste compatibility. Fish work from the
  earlier session is fully reverted.
- **Linux target:** Linux *desktop* (GUI present) → ghostty, fonts, terminal
  theming apply on Linux too.
- **Warp tools:** add `atuin` (Ctrl-R history recall) + `carapace` (rich
  cross-shell completions) wired into zsh. Keep existing autosuggest +
  syntax-highlight + zsh-abbr + starship + zoxide + fzf.
- **nvim/neovim orphan template dirs:** user uses neither → delete both.
- **Ansible idempotency depth:** pragmatic — fix cheap/structural issues; leave
  `defaults write` / `duti` / PlistBuddy tasks as-is but documented (proper
  change-detection there is costly and brittle).

## Non-goals

- No migration off Ansible+Stow to chezmoi/Nix (`$(brew --prefix)` already
  abstracts the main OS path difference).
- No new Linux GUI app parity (grammarly/intellij/postico equivalents) — noted
  but out of scope.
- No removal of currently-stowed terminals the user may still use (kitty,
  alacritty) — left intact.

---

## Section 1 — Shell layer (zsh)

### Problem (from audit)
- `dotfile_templates/zsh/.zshrc` is pipx-generated cruft that **never sources**
  the modular `~/.config/zsh/*.zsh` files → the real config is orphaned/dead on
  macOS.
- `dotfile_templates/zsh/.zshrc_linux:3` sources `~/.zshrc_base`, which **does not
  exist** in the repo.
- Hardcoded paths: `/Users/maxjerin/.local/bin`, `/Users/maxjerin/.opencode/bin`,
  `/opt/homebrew/bin/mise` (`.zshrc:3,4,7`, `.zprofile:3`).
- `04-init.zsh` idempotency/portability bugs: `ln -s` without `-f` (line 10),
  `cat > abbreviations` rebuilt every shell (lines 2-3), macOS-only 1Password
  sock + `/Applications/Visual Studio Code.app` + `PNPM_HOME="~/Library/pnpm"`
  (quoted tilde won't expand) with no OS guard.

### Design
Delete `.zshrc`, `.zshrc_linux`; drop the `.zshrc_base` concept. One portable
`.zshrc` stowed to `~` on both OSes, acting as a thin loader:

```zsh
# OS-aware brew bootstrap — first existing prefix wins (idempotent)
for p in /opt/homebrew/bin /usr/local/bin /home/linuxbrew/.linuxbrew/bin; do
  if [ -x "$p/brew" ]; then eval "$("$p/brew" shellenv)"; break; fi
done

# Load modular config in order
for f in ~/.config/zsh/[0-9]*.zsh; do
  [ -r "$f" ] && source "$f"
done
```

Modular `~/.config/zsh/*.zsh` rewritten:

- **00-environment.zsh** — keep `$(brew --prefix)` PATH (portable across
  mac-arm `/opt/homebrew`, mac-intel `/usr/local`, linuxbrew). Replace hardcoded
  user paths with `$HOME/.local/bin`, `$HOME/.opencode/bin`. mise activation
  guarded by `command -v mise`. Keep `typeset -U PATH` dedup.
- **01-history.zsh** — unchanged (already correct).
- **02-plugins.zsh** — keep zsh-abbr, zsh-autosuggestions, zsh-syntax-highlighting,
  zsh-completions (all via `$(brew --prefix)`). **Add carapace** init
  (`source <(carapace _carapace zsh)`, with `CARAPACE_BRIDGES`). **Add fzf-tab**
  (cloned plugin) for fzf-driven completion menus.
- **03-style.zsh** — keep `starship init zsh`. Delete the large commented-out
  powerline-go block (dead code).
- **04-init.zsh** — fixes:
  - `ln -s` → `ln -sfn` (idempotent symlink).
  - Gate 1Password agent sock, VS Code `code version use`, and `PNPM_HOME`
    behind `[[ "$OSTYPE" == darwin* ]]`; fix `PNPM_HOME` to `$HOME/Library/pnpm`
    (no quoted tilde), macOS-only.
  - Build `~/.config/zsh/abbreviations` only when the source files are newer than
    the output (or generate once at stow time), not every shell start.
  - Keep guarded zoxide/tmux/alacritty clone blocks (already idempotent via
    `test ! -d`).
  - **Add atuin** init (`eval "$(atuin init zsh --disable-up-arrow)"`) — Ctrl-R
    history recall; Up-arrow stays zsh-native.

### Outcome
Every Warp feature is present in zsh, cross-platform: ghost-text autosuggest,
syntax highlight, carapace+fzf-tab rich menus, atuin history recall, starship
prompt, zoxide smart-cd.

---

## Section 2 — Bootstrap layer

### Problem (from audit)
- `command_exists()` and the `.git/hooks/pre-commit` copy block are duplicated
  verbatim in both bootstrap scripts (`:17-19`, `:12-14`); the hooks copy has no
  `mkdir -p` guard.
- `bootstrap-linux.sh:158` appends to `/etc/shells` without dedup (duplicate
  entries on re-run).
- `setup_dotfiles()` is largely duplicated and has drifted (fish+ghostty on mac
  only; Linux uses `ln -sf .zshrc_linux` instead of stow).
- Divergent `install_stow`, `run_ansible_playbook` (Linux does an expensive
  `find ~ -name ansible-playbook`), pipx handling.

### Design
New `bootstrap-common.sh`, sourced by both OS scripts, holding:
- `command_exists()`.
- Guarded `.git/hooks` install (`mkdir -p .git/hooks` first; copy is overwrite-safe).
- One `setup_dotfiles()` driven by an OS-provided stow list. Common stows: zsh
  (`.zshrc` to `~`, modular to `~/.config/zsh`), starship, tmux, k9s(+skins),
  alacritty, kitty, **ghostty**. macOS-only: karabiner. No fish.
- Idempotent default-shell switch: `grep -q "$ZSH_PATH" /etc/shells || echo ... | sudo tee -a`;
  `chsh` only if `$SHELL` differs.
- Unified ansible-playbook resolution (no home-dir scan); pipx reinstall +
  `pipx run` fallback on both.

`bootstrap-{macos,linux}.sh` shrink to: detect/define OS specifics (brew install
path, ansible `--become`/`--become-method` on Linux, OS-only stow list) then call
into common.

---

## Section 3 — Ansible layer (pragmatic)

### Fixes
- **Delete duplicate tasks:** Arc browser + Warp SSH `duti` handlers exist in both
  `roles/system/tasks/macos.yml:48-112` and `roles/system/tasks/macos/defaults.yml:2-69`.
  Keep one location (defaults.yml), remove from macos.yml.
- **keyboard_mapping/tasks/linux.yml** — replace `command:` file ops with
  `ansible.builtin.file`:
  - `:59-64` mkdir → `file: state=directory`
  - `:66-71` touch → `file: state=touch`; **fix `.xkbd` typo → `.xkb`**
  - `:81-86` mkdir → `file: state=directory`
  - `:74-79` `setxkbmap -print >` and `:100-105` `xkbcomp` — add change-detection
    or `creates:`/`when:` so they don't rewrite/apply every run.
- **fonts/tasks/linux.yml:30-39** — `mv` font files → `ansible.builtin.copy` with
  `creates:`/dest check (idempotent, reports change only when copied).
- **OS guards:** add `when: ansible_os_family == 'Debian'` to the `include_tasks`
  in `roles/fonts/tasks/main.yml` and `roles/keyboard_mapping/tasks/main.yml`.
- **productivity/tasks/apt.yml:26-28** — `curl ... | sudo bash` repo setup: add a
  `creates:` guard (idempotent) or convert to a proper apt-repo task.
- **vars/main.yml cleanup:**
  - Move `zsh` into `formulas_common` (currently duplicated in both
    `formulas_linux` and `formulas_macos`).
  - Standardize on `zoxide` (drop Linux's old `z`; drop `spaceship` in favor of
    the common `starship`).
  - Comment `karabiner-elements` as macOS-only.
  - Ensure `atuin`, `carapace` present in `formulas_common` (added this session);
    **remove `fish`** (revert).

### Accepted (documented, not fixed)
`defaults write` / PlistBuddy / `duti` Spotlight+Raycast tasks remain
"always-changed"; reliable change-detection is costly/brittle. Documented in the
role.

---

## Section 4 — Stow / config parity

- **ghostty** added to the shared stow list → deployed on Linux too.
- **karabiner** stays macOS-only (correct — macOS-only tool).
- **Delete orphan template dirs** `dotfile_templates/neovim/` and
  `dotfile_templates/nvim/` (never stowed; user uses neither).
- Verify post-rewrite: every `dotfile_templates/*` dir is either stowed by the
  common/OS list or intentionally absent; no stow step points at a missing dir.

---

## Section 5 — Fish revert (cleanup of earlier session)

- Remove `dotfile_templates/fish/` from the repo.
- Remove `fish` from `formulas_common` in `vars/main.yml`.
- Remove the fish stow block from bootstrap (superseded by the shared list).
- `stow -D` / unlink `~/.config/fish`; `chsh -s "$(command -v zsh)"` back to zsh
  (guarded); optionally `brew uninstall fish`.
- **Keep** `atuin` + `carapace` + the zoxide 0.9.9 upgrade (now serving zsh).

---

## Verification

Idempotency is the acceptance test. After implementation:

1. **Shell:** open a fresh zsh — no warnings/errors; `echo $PATH` has no dupes
   (`typeset -U` holds); autosuggest + highlight + atuin Ctrl-R + carapace menus
   work. Re-source `.zshrc` twice — identical state, no errors.
2. **Bootstrap:** run `./bootstrap.sh` twice on a clean-ish state. Second run:
   no `/etc/shells` dupes, no `ln` errors, stow reports already-linked, no
   chsh re-prompt.
3. **Ansible:** `ansible-playbook ... --check` then a real run, then a second real
   run — second run reports `changed=0` except the documented always-changed
   defaults/duti tasks.
4. **Cross-platform:** dry-run the stow list resolves on both OS branches; no
   hardcoded `/Users/maxjerin` or `/opt/homebrew` remain in stowed files
   (`grep -rn '/Users/maxjerin\|/opt/homebrew' dotfile_templates/` → only
   OS-guarded occurrences).

## Rollout order

1. Fish revert (clears the deck).
2. Shell layer rewrite (highest daily value; independently testable).
3. Stow parity + orphan deletion.
4. Bootstrap common-core refactor.
5. Ansible idempotency fixes.

Each step is committable and verifiable on its own.
