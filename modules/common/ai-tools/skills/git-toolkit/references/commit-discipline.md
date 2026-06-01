# Commit Discipline

Use for commit planning, message drafting, and local history cleanup.

## Core Policy

- Match repository history (`git log`) first.
- Prefer imperative, short, scoped subjects.
- Use Conventional Commit style when repo does.
- Stage only intended hunks/files.
- Review `git diff --cached` before every commit.
- Do not bundle unrelated changes.

## Message CLI Safety

Never emit literal `\n` escape sequences in commit messages.

Bad:

```bash
git commit -m "line1\nline2"
```

Good:

```bash
git commit -m "feat(scope): subject" -m "first body paragraph" -m "second paragraph"
```

## Local History Strategy

Before committing follow-up fixes, inspect whether history edit is better:

- immediate HEAD correction: prefer `git commit --amend`
- nearby local-only regression: prefer `git commit --fixup=<target>` then
  `git rebase -i --autosquash`
- pushed/shared commits: avoid rewrite; use follow-up commit unless user
  coordinates rewrite

If splitting, squashing, or reordering is needed, state target history shape
before running commands.
