---
name: git-surgeon
description: Non-interactive hunk-level git staging, unstaging, discarding, undoing, fixup, amend, squash, commit splitting, and commit reordering. Use when selectively staging, unstaging, discarding, reverting, squashing, splitting, or reordering individual diff hunks by ID instead of interactively.
---

# git-surgeon

CLI for hunk-level git operations without interactive prompts. Useful for AI
agents that need precise control over which changes to stage, unstage, discard,
or undo.

## Commands

```bash
# List unstaged hunks (shows ID, file, +/- counts, preview)
git-surgeon hunks

# List staged hunks
git-surgeon hunks --staged

# Filter to one file
git-surgeon hunks --file=src/main.rs

# List hunks from a specific commit
git-surgeon hunks --commit <HEAD/sha>

# Show all hunks with line numbers (for small commits needing line-range splits)
git-surgeon hunks --commit <sha> --full

# Show blame info (which commit introduced each line)
git-surgeon hunks --blame
git-surgeon hunks --blame --staged
git-surgeon hunks --blame --commit <sha>

# Show full diff for a hunk (lines are numbered for use with --lines)
git-surgeon show <id>
git-surgeon show <id> --commit HEAD

# Stage specific hunks
git-surgeon stage <id1> <id2> ...

# Stage only part of a hunk by line range
git-surgeon stage <id> --lines 5-30

# Stage and commit hunks in one step
git-surgeon commit <id1> <id2> ... -m "message"

# With inline line ranges
git-surgeon commit <id>:1-11 <id2> -m "message"

# Commit hunks directly to another branch (no checkout needed)
git-surgeon commit-to <branch> <id1> <id2> ... -m "message"
git-surgeon commit-to main <id>:1-11 <id2> -m "message"

# Unstage specific hunks
git-surgeon unstage <id1> <id2> ...
git-surgeon unstage <id> --lines 5-30

# Discard working tree changes for specific hunks
git-surgeon discard <id1> <id2> ...
git-surgeon discard <id> --lines 5-30

# Fold a commit into an earlier commit (default: HEAD into target)
git-surgeon fixup <target>
git-surgeon fixup <target> --from <commit>
git-surgeon fixup <target> --from <commit1> <commit2> <commit3>

# Fold staged changes into an earlier commit
git-surgeon amend <commit>

# Change commit message
git-surgeon reword HEAD -m "new message"
git-surgeon reword <commit> -m "new message"
git-surgeon reword HEAD -m "subject" -m "body"

# Squash ALL commits from <commit> through HEAD into one
git-surgeon squash HEAD~1 -m "combined feature"
git-surgeon squash HEAD~2 -m "Add user auth" -m "Implements JWT-based authentication."
git-surgeon squash <commit> -m "feature complete"
git-surgeon squash HEAD~3 --force -m "squash with merges"
git-surgeon squash HEAD~1 --no-preserve-author -m "use current author"

# Undo specific hunks from a commit (reverse-apply to working tree)
git-surgeon undo <id1> <id2> ... --from <commit>
git-surgeon undo <id> --from <commit> --lines 2-10

# Undo all changes to specific files from a commit
git-surgeon undo-file <file1> <file2> ... --from <commit>

# Split a commit into multiple commits by hunk selection
git-surgeon split HEAD \
  --pick <id1> <id2> -m "first commit" \
  --rest-message "remaining changes"

# Split with subject + body (multiple -m flags, like git commit)
git-surgeon split HEAD \
  --pick <id1> -m "Add feature" -m "Detailed description here." \
  --rest-message "Other changes" --rest-message "Body for rest."

# Split with line ranges (comma syntax or repeat ID for non-contiguous ranges)
git-surgeon split <commit> \
  --pick <id>:1-11,20-30 <id2> -m "partial split"

# Move a commit after another commit
git-surgeon move <sha> --after <target-sha>

# Move a commit before another commit
git-surgeon move <sha> --before <target-sha>

# Move a commit to the end of the branch
git-surgeon move <sha> --to-end

# Update git-surgeon to the latest version
git-surgeon update

# Split into three+ commits
git-surgeon split HEAD \
  --pick <id1> -m "first" \
  --pick <id2> -m "second" \
  --rest-message "rest"
```

## Typical workflow

1. Run `git-surgeon hunks` to list hunks with their IDs
2. Use `git-surgeon show <id>` to inspect a hunk (lines are numbered)
3. Stage and commit in one step: `git-surgeon commit <id1> <id2> -m "message"`
4. Or stage separately: `git-surgeon stage <id1> <id2>`, then `git commit`
5. To commit only part of a hunk, use inline ranges: `git-surgeon commit <id>:5-30 -m "message"`

## Committing to another branch

Use `commit-to` when working in a worktree and you need to commit changes to a
branch checked out elsewhere (e.g., main):

1. Run `git-surgeon hunks` to list hunks
2. Commit to another branch: `git-surgeon commit-to main <id1> <id2> -m "message"`
3. The hunks are applied to the target branch's tree and discarded from the working tree
4. Fails if the patch cannot be applied cleanly to the target branch

## Folding fix commits into earlier commits

`fixup` folds one or more commits into an earlier one. The source(s) (default:
HEAD) are removed from history and their changes merge into the target.
Intermediate commits stay untouched. Dirty working tree is autostashed.

- `git-surgeon fixup <target>` -- fold HEAD into target (most common)
- `git-surgeon fixup <target> --from <commit>` -- fold a specific non-HEAD commit
- `git-surgeon fixup <target> --from <c1> <c2> <c3>` -- fold multiple commits in one pass
- Fails if the range contains merge commits

### Using --blame to find the fixup target

Use `--blame` to see which commit introduced the surrounding lines:

```bash
git-surgeon hunks --blame
```

Output shows commit hashes for each line:
```
a1b2c3d src/auth.rs (+2 -0)
  8922b52  fn login(user: &str) {
  8922b52      validate(user);
  0000000 +    log_attempt(user);  # new line, not yet committed
  0000000 +    audit(user);        # new line, not yet committed
  8922b52  }
```

The context lines show `8922b52` -- that's the commit where this function was
added. If your new lines belong with that change:

```bash
git-surgeon commit a1b2c3d -m "add login logging"
git-surgeon fixup 8922b52
```

## Amending earlier commits with staged changes

`amend` folds staged changes into an earlier commit. For HEAD, amends directly;
for older commits, uses autosquash rebase. Unstaged changes are preserved.

1. Stage desired hunks: `git-surgeon stage <id1> <id2>`
2. Amend the target commit: `git-surgeon amend <commit-sha>`

## Squashing commits

Squash collapses ALL commits from the target through HEAD into a single commit.
Every intermediate commit in the range is merged. To fold one commit into a
non-adjacent earlier commit without collapsing the range, use `fixup` instead.

1. Squash commits from a target commit through HEAD: `git-surgeon squash HEAD~2 -m "combined"`
2. Use multiple `-m` flags for subject + body: `git-surgeon squash HEAD~1 -m "Subject" -m "Body paragraph"`
3. Target commit must be an ancestor of HEAD
4. Use `--force` to squash ranges containing merge commits
5. Uncommitted changes are autostashed and restored
6. Author from the oldest commit is preserved by default; use `--no-preserve-author` for current user

## Undoing changes from commits

1. Run `git-surgeon hunks --commit <sha>` to list hunks in a commit
2. Undo specific hunks: `git-surgeon undo <id> --from <sha>`
3. Or undo entire files: `git-surgeon undo-file src/main.rs --from <sha>`
4. Changes appear as unstaged modifications in the working tree

## Splitting commits

1. List hunks in the commit: `git-surgeon hunks --commit <sha>`
   - For small commits, use `--full` to see all lines with line numbers in one call
2. Split by picking hunks: `git-surgeon split <sha> --pick <id1> -m "first" --rest-message "second"`
3. Use multiple `-m` flags for subject + body: `--pick <id> -m "Subject" -m "Body paragraph"`
4. Use `id:range` syntax for partial hunks: `--pick <id>:5-20`
   - For non-contiguous lines, use commas: `--pick <id>:2-6,34-37`
5. Works on HEAD (direct reset) or earlier commits (via rebase)
6. Requires a clean working tree

## Moving commits

`move` reorders commits in history. Useful for grouping related changes or
moving a commit to a logical position after splitting.

- `git-surgeon move <sha> --after <target>` -- place commit right after target
- `git-surgeon move <sha> --before <target>` -- place commit right before target
- `git-surgeon move <sha> --to-end` -- place commit at HEAD
- Dirty working tree is autostashed
- Fails if the range contains merge commits

## Hunk IDs

- 7-character hex strings derived from file path + hunk content
- Stable across runs as long as the diff content hasn't changed
- Duplicates get `-2`, `-3` suffixes
- If a hunk ID is not found, re-run `hunks` to get fresh IDs
