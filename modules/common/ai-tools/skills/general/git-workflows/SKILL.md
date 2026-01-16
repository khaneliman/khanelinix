---
name: git-workflows
description: Git version control workflows, branching strategies, and conflict resolution. Use when managing branches, resolving merge conflicts, understanding git history, or following team git conventions.
---

# Git Workflows Guide

Expert guidance for Git version control workflows, branching strategies, and
conflict resolution.

## Core Principles

1. **Atomic commits** - One logical change per commit
2. **Clear history** - Meaningful commit messages that explain why
3. **Branch hygiene** - Keep branches focused and short-lived
4. **Safe operations** - Understand destructive commands before using
5. **Collaboration-friendly** - Follow team conventions consistently

## Common Workflows

### Feature Branch Workflow

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

### Trunk-Based Development

```bash
# Work directly on main with short-lived branches
git checkout -b quick-fix
# ... make changes ...
git commit -m "fix: handle null response"
git checkout main
git merge quick-fix
git branch -d quick-fix
```

## Branch Naming Conventions

| Prefix      | Purpose          | Example                |
| ----------- | ---------------- | ---------------------- |
| `feat/`     | New feature      | `feat/user-dashboard`  |
| `fix/`      | Bug fix          | `fix/login-redirect`   |
| `docs/`     | Documentation    | `docs/api-reference`   |
| `refactor/` | Code refactoring | `refactor/auth-module` |
| `test/`     | Test additions   | `test/user-service`    |
| `chore/`    | Maintenance      | `chore/update-deps`    |

## Conflict Resolution

### Understanding Conflict Markers

```diff
<<<<<<< HEAD
Your current changes
=======
Incoming changes from merge/rebase
>>>>>>> feature-branch
```

### Resolution Workflow

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

### Resolution Strategies

| Conflict Type                    | Strategy                                |
| -------------------------------- | --------------------------------------- |
| **Same line, different changes** | Combine both changes if compatible      |
| **Deleted vs modified**          | Decide if deletion or modification wins |
| **Structural changes**           | May need manual refactoring             |
| **Binary files**                 | Choose one version, can't merge         |

### When to Use Which

| Situation               | Use                       |
| ----------------------- | ------------------------- |
| Updating feature branch | `git rebase main`         |
| Integrating to main     | `git merge feature`       |
| Quick one-off fix       | Direct commit to main     |
| Collaborative branch    | Merge (preserves history) |

## Useful Git Commands

### Inspection Commands

```bash
# View commit history
git log --oneline -20
git log --graph --all --oneline

# See what changed
git diff                      # Working vs staged
git diff --cached            # Staged vs last commit
git diff main..feature       # Between branches

# Find who changed what
git blame <file>
git log -p -- <file>         # History of a file
```

### Undo Operations

| Scenario                        | Command                   | Safe?       |
| ------------------------------- | ------------------------- | ----------- |
| Unstage file                    | `git reset HEAD <file>`   | Yes         |
| Discard working changes         | `git checkout -- <file>`  | Yes         |
| Amend last commit (not pushed)  | `git commit --amend`      | Local only  |
| Undo last commit (keep changes) | `git reset --soft HEAD~1` | Local only  |
| Undo last commit (discard)      | `git reset --hard HEAD~1` | Destructive |
| Revert pushed commit            | `git revert <sha>`        | Yes         |

### Branch Cleanup

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

## Rebase vs Merge

### When to Rebase

- Updating feature branch with main changes
- Cleaning up local commit history
- Before creating PR (squash/fixup)
- Solo work not yet pushed

### When to Merge

- Integrating feature to main
- Shared branches others are using
- Preserving exact history is important
- You want a merge commit marker

### Interactive Rebase

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

## Safety Guidelines

### Destructive Commands (Use Carefully)

| Command            | Effect                  | Recovery             |
| ------------------ | ----------------------- | -------------------- |
| `git reset --hard` | Discards all changes    | `git reflog`         |
| `git push --force` | Overwrites remote       | Others may lose work |
| `git branch -D`    | Force deletes branch    | `git reflog`         |
| `git clean -fd`    | Removes untracked files | None                 |

### Before Force Push

1. **Never force push to main/master**
2. Check if others are using the branch
3. Use `--force-with-lease` instead (safer)
4. Communicate with team first

### Recovery with Reflog

```bash
# See history of HEAD changes
git reflog

# Restore to previous state
git reset --hard HEAD@{2}

# Recover deleted branch
git checkout -b recovered-branch HEAD@{5}
```

## Workflow Checklist

Before starting work:

- [ ] Pull latest from main
- [ ] Create appropriately named branch
- [ ] Understand the task scope

During work:

- [ ] Commit frequently with clear messages
- [ ] Keep changes focused on one concern
- [ ] Rebase on main periodically for long branches

Before PR:

- [ ] Rebase on latest main
- [ ] Squash fixup commits
- [ ] Run tests and linting
- [ ] Write clear PR description

## See Also

- **Commit messages**: See [commit-messages](../commit-messages/) for
  conventional commit format
- **Code review**: See [code-review](../code-review/) for PR review guidelines
