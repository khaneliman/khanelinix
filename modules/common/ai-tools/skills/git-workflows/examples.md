# Git Workflow Examples

## Feature Branch Workflow

```bash
# 1. Start from updated main
git checkout main
git pull origin main

# 2. Create feature branch
git checkout -b feat/user-authentication

# 3. Work and commit incrementally
git add -p                    # Stage hunks interactively
git commit -m "feat(auth): add login form"

# 4. Keep branch updated (rebase preferred)
git fetch origin
git rebase origin/main

# 5. Push and create PR
git push -u origin feat/user-authentication
```

## Trunk-Based Development

```bash
# Work directly on main with short-lived branches
git checkout -b quick-fix
# ... make changes ...
git commit -m "fix: handle null response"
git checkout main
git merge quick-fix
git branch -d quick-fix
```

## Conflict Resolution Workflow

```bash
# 1. See conflicting files
git status

# 2. Open file and resolve conflicts
# - Keep HEAD version: remove incoming, keep current
# - Keep incoming: remove current, keep incoming
# - Merge both: combine changes logically

# 3. Mark as resolved
git add <resolved-file>

# 4. Continue operation
git rebase --continue   # If rebasing
git merge --continue    # If merging
git commit              # If regular merge
```

## Interactive Rebase

```bash
# Clean up last 5 commits
git rebase -i HEAD~5

# In editor, change 'pick' to:
# - squash (s): combine with previous
# - fixup (f): combine, discard message
# - reword (r): edit commit message
# - edit (e): stop to amend
# - drop (d): remove commit
```

## Recovery with Reflog

```bash
# See history of HEAD changes
git reflog

# Restore to previous state
git reset --hard HEAD@{2}

# Recover deleted branch
git checkout -b recovered-branch HEAD@{5}
```

## Branch Cleanup

```bash
# Delete local branch
git branch -d feature-branch      # Safe (checks merge)
git branch -D feature-branch      # Force delete

# Delete remote branch
git push origin --delete feature-branch

# Prune stale remote refs
git fetch --prune

# Find merged branches to clean
git branch --merged main
```

## Fixup + Autosquash (Atomic History)

```bash
# Existing history
git log --oneline -n 6
# aaaaaaa feat(api): add v2 routes
# bbbbbbb test(api): add v2 integration tests
# ccccccc docs(api): add v2 migration notes

# Follow-up fix belongs to feature commit
git add src/api/v2/routes.nix
git commit --fixup=aaaaaaa

# Follow-up test fix belongs to test commit
git add tests/api/v2-integration.nix
git commit --fixup=bbbbbbb

# Fold both fixups into original commits
GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash aaaaaaa^

# Verify no standalone "fixup!" commits remain
git log --oneline -n 10
git status --short
```
