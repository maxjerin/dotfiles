# Global development instructions

These rules apply to every coding agent (Claude Code, Codex, Cursor, Gemini, …) in every repo.
A repo's own `AGENTS.md` / `CLAUDE.md` takes precedence over anything here, and the user's
direct instructions take precedence over both.

Source of truth: `dotfiles/dotfile_templates/agents/AGENTS.md`, stowed to
`~/.config/agents/AGENTS.md`. Edit it in the dotfiles repo, not at the stowed path.

---

## 1. Git: never work on `main`

- Never commit directly to `main` (or the repo's default branch). Branch first, even for a
  one-line fix.
- One task = one branch = one worktree. Worktrees let several agents/sessions work the
  same repo in parallel without trampling each other's checkout.

### Worktrees

```bash
git fetch origin
git worktree add .worktrees/<slug> -b <type>/<slug> origin/main
cd .worktrees/<slug>
```

- Keep worktrees under `<repo>/.worktrees/` and make sure `.worktrees/` is in `.gitignore`.
- If the harness already put you in an isolated worktree (e.g. a `worktree-agent-*` or
  `claude/*` branch), do **not** create another one. Rename the branch instead:
  `git branch -m <type>/<slug>`.
- Never `git stash`: the stash stack is shared across every worktree of the repo.
- Never `cd` into the main checkout to make changes; never remove a worktree you didn't create.
- After the PR merges, remove the worktree you created: `git worktree remove .worktrees/<slug>`
  and `git branch -D <type>/<slug>` (squash merges leave it looking unmerged).

### Branch names

`<type>/<short-kebab-slug>`, optionally with a task ID: `feat/tfw-42-copy-watch`.

| type | use for |
|------|---------|
| `feat` | new behaviour |
| `fix` | bug fix |
| `chore` | maintenance, deps, cleanup |
| `refactor` | no behaviour change |
| `docs` | docs only |
| `test` / `e2e` | tests only |
| `ci` | CI/CD pipelines |
| `infra` | infrastructure / deployment config |

### Commits

- Conventional Commits: `type(scope): imperative subject`, subject ≤ ~72 chars.
  The body explains **why** when it isn't obvious from the diff.
- Stage explicit paths. Never `git add -A` / `git add .`; it sweeps in scratch files and secrets.
- Never `--no-verify`. If a hook fails, fix the cause.
- Never force-push `main`. On your own branch after a rebase use `--force-with-lease`, never `--force`.

---

## 2. Pull requests

### Before opening

- Build, lint and test every package you touched. Do not open a PR on a broken build.
- Tests ship in the **same PR** as the code they cover; never as a follow-up.
- If something can't be verified locally (needs live infra, a device, credentials), say so
  explicitly in the PR body instead of skipping silently.

### Opening

```bash
git push -u origin <branch>
gh pr create --base main --title "<title>" --body "<body>"
```

- Title: the Conventional Commit subject, or `[TASK-ID] Summary` when the repo tracks tasks.
- Body: `## Summary` (bullets: what and why) and `## Test plan` (checkbox list of what
  was actually run, ticked only if it passed).

### CI gate (hard block)

```bash
gh pr checks <n> --watch
```

- All green → merge. Any red → `gh run view <run-id> --log-failed`, fix the root cause, push,
  watch again.
- After **2 failed fix attempts** with an unclear cause: stop, don't merge, and report what failed.
- No checks appear within ~2 min? Check `gh pr view <n> --json mergeable,mergeStateStatus`.
  If it's conflicting, `git rebase origin/main`, resolve, `git push --force-with-lease`.
- Repos without branch protection rely on this discipline alone: a red merge breaks every
  other agent's next run.

### Merging

```bash
gh pr merge <n> --squash --delete-branch
```

- Always squash. Never `--auto`, `--merge` or `--rebase`.
- Merge without asking once CI is green **and** the user asked for the work to land
  ("ship it", "get it into main", an approved task brief). Otherwise open the PR and ask.
- After merge: update the main checkout (`git checkout main && git pull`), clean up the
  worktree (§1), and update the task tracker if the repo uses one.

---

## 3. Sessions and chats

- Name each chat/session after its task: the branch slug or task ID (e.g.
  `fix/zsh-compinit-insecure`, `TFW-42`). Parallel sessions are then easy to tell apart.
  In Claude Code that's `/rename <name>`. If you can't rename it yourself, suggest the name
  to the user at the start.
- Rename when the scope of the chat changes materially.
- Long-running work that spans sessions keeps a worklog in the repo (current state + next
  actions) so a fresh session can resume without re-deriving context.

---

## 4. Secrets

- Never ask the user to paste a password, token or key. Load it non-interactively from the
  store (1Password `op read "op://<vault>/<item>/<field>"`; concealed fields need `--reveal`
  with `op item get`) into a transient shell variable.
- A 1Password MCP server (`1password`) is registered for Claude Code. Its tools manage
  1Password **Environments** (env-var sets, local `.env` files), not vault items: use the
  `op` CLI for item reads.
- Authenticate once at the start of a task, pull every secret the task needs in one batch,
  and reuse the variables. A lazy lookup mid-run can stall on a biometric prompt nobody sees.
- Never print, log or commit a secret value. Not in files, PR bodies, commit messages or
  command output. Refer to secrets by store location only.
- If a secret is genuinely missing from the store: stop and report exactly which item/field
  is needed and where it should live.
- Anything needing `sudo` with a password: give the user the exact command to run in a real
  terminal; don't try to work around it.

---

## 5. Working style

- Act, don't narrate. No "Step 3: now editing X" before every edit. Report blockers,
  decisions that need the user, and a short final summary (what shipped, PR link, follow-ups).
- Keep command output small: `git diff --stat`, `--name-only`, `| tail -20` for builds/tests.
- Scratch files go in a temp/scratch directory, never in the repo, with task-specific names
  (several agents may share it).
- Use what the project already has (its cache, queue, flag system, error reporting) before
  adding new infrastructure. New services need an explicit go-ahead.
- Note out-of-scope problems you notice; don't fix them in the current PR.
- Clean up what you start. When a task ends (or before handing back), stop every container,
  stack and long-running process you started: `docker compose down`, `tilt down`, throwaway
  test databases, dev servers, port-forwards. Leave alone anything that was already running
  before you began. If something must stay up, say what and why in your final summary.
