# Git Reference Guide

## Branch Naming Conventions

| Prefix      | Purpose          | Example                |
| ----------- | ---------------- | ---------------------- |
| `feat/`     | New feature      | `feat/user-dashboard`  |
| `fix/`      | Bug fix          | `fix/login-redirect`   |
| `docs/`     | Documentation    | `docs/api-reference`   |
| `refactor/` | Code refactoring | `refactor/auth-module` |
| `test/`     | Test additions   | `test/user-service`    |
| `chore/`    | Maintenance      | `chore/update-deps`    |

## Conflict Resolution Strategies

| Conflict Type                    | Strategy                                |
| -------------------------------- | --------------------------------------- |
| **Same line, different changes** | Combine both changes if compatible      |
| **Deleted vs modified**          | Decide if deletion or modification wins |
| **Structural changes**           | May need manual refactoring             |
| **Binary files**                 | Choose one version, can't merge         |

## Merge vs Rebase: When to Use Which

| Situation               | Use                       |
| ----------------------- | ------------------------- |
| Updating feature branch | `git rebase main`         |
| Integrating to main     | `git merge feature`       |
| Quick one-off fix       | Direct commit to main     |
| Collaborative branch    | Merge (preserves history) |

## Undo Operations

| Scenario                        | Command                   | Safe?       |
| ------------------------------- | ------------------------- | ----------- |
| Unstage file                    | `git reset HEAD <file>`   | Yes         |
| Discard working changes         | `git checkout -- <file>`  | Yes         |
| Amend last commit (not pushed)  | `git commit --amend`      | Local only  |
| Undo last commit (keep changes) | `git reset --soft HEAD~1` | Local only  |
| Undo last commit (discard)      | `git reset --hard HEAD~1` | Destructive |
| Revert pushed commit            | `git revert <sha>`        | Yes         |

## Destructive Commands

| Command            | Effect                  | Recovery             |
| ------------------ | ----------------------- | -------------------- |
| `git reset --hard` | Discards all changes    | `git reflog`         |
| `git push --force` | Overwrites remote       | Others may lose work |
| `git branch -D`    | Force deletes branch    | `git reflog`         |
| `git clean -fd`    | Removes untracked files | None                 |
