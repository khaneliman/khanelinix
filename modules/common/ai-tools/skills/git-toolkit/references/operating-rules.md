# Git Operating Rules

Use for safety boundaries across Git modes.

## Branch Names

- Follow repository documentation and existing branch history when they define a
  naming convention.
- When repository canon is silent, choose a concise semantic name. Do not add a
  provider-identity prefix such as `agent/`, `codex/`, or `claude/` merely
  because an AI agent created the branch.
- Use a provider or automation prefix only when the user, repository, or
  execution environment explicitly requires one.

## Shared History

- Call out destructive risk before commands touching shared history or remotes:
  force push, reset, remote branch deletion, rebase of pushed commits.
- If uncertain whether commit is shared, inspect remotes before rewrite.
- Require user authority before destructive operations; honor existing explicit
  authority without asking again. For owned open-PR follow-ups, follow
  [Local History Strategy](commit-discipline.md#local-history-strategy), not the
  genuinely shared-branch default. Rewrite authority does not grant push access.
- Verified task-owned local cleanup follows [cleanup.md](cleanup.md). Honor
  existing cleanup authority without asking again; do not classify removal of
  integrated temporary resources as a new destructive request.

## Shared Checkouts and Isolated Worktrees

- Parallel agents in one checkout share the index. Serialize staging and
  committing; keep workers workspace-only while others have edits in flight.
  Broad `git add` can stage another agent's files, and a plain commit can sweep
  up their staged changes. Inspect `git diff --cached` immediately before
  committing and use `git commit --only <paths>` for explicit owned paths. Path
  scoping does not isolate concurrent edits within the same file.
- Preserve unexplained changes. If work disappears, inspect `git stash list`
  before assuming loss. Recover with `git stash apply`, not `pop`, so the backup
  survives while you verify the result. Do not stash a shared dirty checkout
  while other writers are active.
- Commit hooks can temporarily hide unstaged changes, even from a read-only
  reviewer, and their restore can overwrite concurrent edits. Finish live-file
  review and pause writers before hooks, or review an immutable candidate. After
  overlap, wait for restoration and confirm the restored candidate; a
  disappearing diff is not proof of loss or a completed review.
- Automatically isolated worktrees may start at the checkout's current `HEAD`,
  not the task's named base. Pre-create each worktree at the intended base with
  `git worktree add -b <branch> <path> <base-sha>`, verify its tip, then pass
  the absolute path to the worker. Use [cleanup.md](cleanup.md) for ownership.

## Cross-Skill Boundaries

- Use `github-toolkit` for PR review comments, CI check triage, and issue
  creation.
- Keep Git logic here; keep GitHub workflow logic in GitHub toolkit.
