# Git Reference Guide

## Fixup + Autosquash

Canonical policy is in [commit-discipline.md](commit-discipline.md). Key
non-obvious mechanics:

- `GIT_SEQUENCE_EDITOR=:` makes autosquash rebase non-interactive — git builds
  the todo list, applies ordering, executes without opening an editor.
- Use `git push --force-with-lease` (never bare `--force`) after any history
  rewrite that touches a pushed branch.

```bash
git commit --fixup=<target-sha>
GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <oldest-target-sha>^
git push --force-with-lease
```
