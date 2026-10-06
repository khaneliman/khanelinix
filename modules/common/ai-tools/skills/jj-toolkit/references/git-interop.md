# Git Interop Reference

## Colocated repos

When `.git/` is sibling of `.jj/`, the repo is "colocated". Git and jj share the
same commits. Imports/exports happen automatically. You can use `git log` to see
the same history. Use `jj` commands to make changes; the narrow exception for an
explicitly authorized Git-native rewrite is documented below.

## Bookmarks

Bookmarks are named pointers to commits. They do NOT advance automatically on
new commits (unlike Git branches). They DO follow when a commit is rewritten.
Bookmarks map to Git branches for push/fetch.

Consequence in a colocated repo: `jj commit` alone produces a commit that no Git
branch contains. See
[Bookmark discipline (mandatory)](#bookmark-discipline-mandatory).

```bash
jj bookmark create <name> -r <rev>      # create bookmark (default rev: @)
jj bookmark set <name> -r <rev>         # move bookmark to revision
jj bookmark delete <name>               # delete bookmark
jj bookmark list --no-pager             # list local bookmarks
jj bookmark list -a --no-pager          # list all including remote
jj bookmark track <name>@<remote>       # start tracking remote bookmark
jj bookmark untrack <name>@<remote>     # stop tracking
```

## Remotes

```bash
jj git clone <url>                      # clone
jj git fetch                            # fetch from default remote
jj git fetch --remote <name>            # fetch from specific remote
jj git fetch --all-remotes              # fetch from all
jj git push -b <bookmark>              # push bookmark
jj git push --all                       # push all bookmarks
jj git push -c <rev>                    # auto-create bookmark and push
jj git push --dry-run                   # preview
```

## Push safety

`jj git push` is similar to `git push --force-with-lease`. It verifies the
remote hasn't changed since last fetch. Conflicted bookmarks cannot be pushed.

### Rewriting a pushed branch

Get rewrite and push authority before starting; a pushed-history rewrite is a
force-push. Keep a backup bookmark at the old tip. Map each fix to its owning
commit, then squash only its paths into that ancestor; descendants rebase
automatically.

```bash
jj squash --into <ancestor> <paths> --ignore-immutable \
  --use-destination-message
```

`--ignore-immutable` is needed when remote bookmarks or other immutable heads
protect the pushed commits. Path arguments leave unrelated working-copy changes
out of the squash. Resolve descendant conflicts before pushing; see
[conflict-resolution.md](conflict-resolution.md).

If the remote bookmark is not tracked, track it with
`jj bookmark track <name>@<remote>`. Importing the old remote tip after a
rewrite can leave the local bookmark conflicted or the change ID divergent.
Select the rewritten tip by **commit ID**, not the now-ambiguous change ID,
before pushing:

```bash
jj bookmark set <name> -r <rewritten-commit-id>
jj git push --bookmark <name>
```

Verify the bookmark names the intended stack tip and the remote has that commit.
Do not abandon an old divergent commit until its replacement is verified and any
unique work is preserved.

## Change ID push workflow

```bash
jj git push -c @                        # creates bookmark "push-<change_id>" and pushes
jj git push --named pr-123=@            # push @ under bookmark name "pr-123"
```

## Private commits

Commits matching `git.private-commits` revset are blocked from pushing by
default. Override with `--allow-private`.

## Colocated Git HEAD and Working Copy Behavior

In colocated repositories, the working copy is always represented as a commit
(`@`).

### Why Git HEAD is Detached

When the working copy has uncommitted changes, `@` becomes a non-empty commit.
Because this commit has no bookmark/branch pointing to it, Git's HEAD will
automatically be detached at the working copy commit hash. **This is normal and
expected behavior.**

### Bookmark discipline (mandatory)

For authorized commit-stack changes in a git-colocated repository, moving the
bookmark is part of finishing the change. These steps do not apply to
inspection, explanation, or diagnosis, and never authorize committing unrelated
work.

1. **Identify the bookmark before touching history**: the nearest bookmarked
   ancestor of `@` is the branch you are working off:

   ```bash
   jj log --no-pager -r 'heads(::@ & bookmarks())' -T 'bookmarks ++ "\n"'
   ```

   Nothing returned means the stack is unnamed: create a bookmark when
   authorized or ask which one to use before changing history. Inspection can
   leave it unnamed.

2. **Finalize task-owned changes, then move the bookmark to the intended stack
   tip** (`@-` after a single `jj commit`). Commit only the authorized paths or
   hunks; leave unrelated changes in `@`. Never move it to a dirty `@`, which
   would commit work-in-progress to the branch with no description:

   ```bash
   jj bookmark set <bookmark> -r @-
   ```

   New branch: `jj bookmark create <name> -r @-`.

3. **Verify before reporting done**: bookmark on the intended tip and task-owned
   changes committed. Expect `@` empty only when no unrelated changes remain:

   ```bash
   jj log --no-pager -r '@ | @-'
   ```

   Rewrites (`jj squash`, `jj absorb`, `jj rebase`) carry bookmarks along but
   can change which commit is the tip, so re-verify after each.

Symptoms of a missed move: `git log` / `git status` show an older branch tip
while `jj log` shows your commits; HEAD detached at a commit holding your work;
bookmark-less commits between the bookmark and `@`. Fix by moving it forward;
`--allow-backwards` is only for a deliberate move to an ancestor.

Verify Git visibility by ancestry, not just the newest `git log` entry: another
session may have advanced the branch. An unreferenced commit may remain
recoverable by ID, but Git branch consumers cannot see it.

```bash
git merge-base --is-ancestor <commit-id> refs/heads/<bookmark>
```

### Git-native rewrite handoff

When a Git-native history rewrite is explicitly authorized, use `git-toolkit` in
an isolated worktree rather than exposing the colocated checkout to mid-rebase
HEADs that jj can import. For a history-only rewrite, prove the old and rebuilt
tips have identical trees before integrating. Move the target Git branch with a
compare-and-swap against its recorded old tip:

```bash
git update-ref refs/heads/<branch> <new-tip> <expected-old-tip>
```

Stop if the comparison fails; another session advanced the branch. Do not
substitute its new tip without inspecting and preserving that work. Recheck jj
bookmarks, working-copy parents, and Git's index after import. Never abandon
unfamiliar heads or clear unexplained index changes as rewrite cleanup.

### Recovery from Accidental Working Copy Committing

If you accidentally moved a bookmark (like `main`) to a dirty working copy
commit:

1. Move the bookmark back to the correct clean parent commit (e.g.
   `ParentCommitID`):
   ```bash
   jj bookmark set main -r ParentCommitID --allow-backwards
   ```
2. Create a new empty working copy pointing to that parent commit:
   ```bash
   jj new main
   ```
3. Restore the uncommitted files from the old dirty commit:
   ```bash
   jj restore --from OldDirtyCommitID
   ```
4. Abandon the old dirty commit to clean up history:
   ```bash
   jj abandon OldDirtyCommitID
   ```
