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

## Fixup + Autosquash Strategy

Use this workflow to keep history atomic when follow-up fixes are discovered
after multiple commits.

### Why use this

- Keep each commit logically complete.
- Avoid "fix lint", "oops", or "follow-up fix" commits in final history.
- Keep review history clean and intentional.

### Core idea

- `git commit --fixup=<target-commit>` creates a temporary commit linked to an
  earlier commit.
- `git rebase -i --autosquash <base>` moves each fixup next to its target and
  marks it as `fixup`.
- Rebase folds fixups into original commits, so temporary fixup commits
  disappear.

### Standard workflow

1. Identify the earlier commit each fix belongs to.
2. Stage only the relevant changes for one target commit.
3. Create a fixup commit:

```bash
git commit --fixup=<target-commit-hash>
```

4. Repeat for each target commit.
5. Run autosquash from the parent of the oldest target commit:

```bash
GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <oldest-target-hash>^
```

6. Verify:

```bash
git log --oneline -n 20
git status --short
```

### Why `GIT_SEQUENCE_EDITOR=:` is useful

- Makes interactive rebase non-interactive.
- Git still builds the todo list, applies autosquash ordering, and executes it.
- Useful when fixup targeting is already correct and no manual todo edits are
  needed.

### Practical notes

- Commit hashes change after rebase (history rewrite).
- If already pushed, use:

```bash
git push --force-with-lease
```

- Keep unrelated untracked files out of staging.
- Stage carefully so each fixup maps to exactly one target commit.

### Mapping strategy

- If a fix touches code introduced by commit `A`, fold into `A`.
- If a fix touches tests introduced by commit `B`, fold into `B`.
- Do not bundle cross-cutting fixes into a new commit unless they are genuinely
  new work.

### When not to use it

- Commits are already shared and team policy forbids rewritten history.
- The fix is genuinely new work and should remain a separate commit.
