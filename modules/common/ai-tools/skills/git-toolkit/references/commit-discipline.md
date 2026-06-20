# Commit Discipline

Use for commit planning, message drafting, and local history cleanup.

## Core Policy

- Match repository history (`git log`) first.
- Prefer imperative, short, scoped subjects.
- Use Conventional Commit style when repo does.
- Always include a body explaining why the commit exists. One short sentence is
  fine.
- Before the first commit, inspect the full diff and state the planned commit
  split when more than one logical unit exists.
- Stage only intended hunks/files.
- Review `git diff --cached` before every commit.
- Do not bundle unrelated changes.
- Do not bundle independent changes only because they came from one user
  request.
- Ask before bundling when the split is unclear or when a technically possible
  split feels misleading.

## Atomic Commit Planning

Treat each commit as the smallest independently buildable logical unit. A good
split is based on dependency order and behavior, not on convenience.

Split these when each can stand alone:

- reusable module/package/helper creation
- host or profile enablement of that reusable piece
- client/application/package replacement
- cleanup or deletion of newly unused code
- generated files or lockfile updates
- formatting-only churn
- tests or documentation

Keep changes together only when splitting would break evaluation, leave a commit
that cannot run, or hide the actual reason for the change. State that reason
before committing.

## Message CLI Safety

Never emit literal `\n` escape sequences in commit messages.

Bad:

```bash
git commit -m "line1\nline2"
```

Good:

```bash
git commit -m "feat(scope): subject" -m "body paragraph"   # multiple -m flags
git commit -F path/to/message.txt                          # file input
git commit -F-                                             # stdin (heredoc)
```

## Local History Strategy

Before committing follow-up fixes, inspect whether history edit is better:

- immediate HEAD correction: prefer `git commit --amend`
- nearby local-only regression: prefer `git commit --fixup=<target>` then
  `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <parent>^`
  (`GIT_SEQUENCE_EDITOR=:` skips the editor — non-interactive)
- pushed/shared commits: avoid rewrite; use follow-up commit unless user
  coordinates rewrite; confirmed rewrite requires `git push --force-with-lease`

If splitting, squashing, or reordering is needed, state target history shape
before running commands.
