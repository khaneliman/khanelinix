# Git Workflow Examples

Standard workflows (feature branch, trunk-based, conflict resolution, reflog
recovery, branch cleanup) are model-known — no template needed.

## Fixup + Autosquash (non-obvious)

See [git-reference.md](git-reference.md) for mechanics. Example:

```bash
# Existing history
# aaaaaaa feat(api): add v2 routes
# bbbbbbb test(api): add v2 integration tests

git add src/api/v2/routes.nix
git commit --fixup=aaaaaaa

git add tests/api/v2-integration.nix
git commit --fixup=bbbbbbb

GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash aaaaaaa^

git log --oneline -n 10   # verify no standalone "fixup!" commits
git status --short
```
