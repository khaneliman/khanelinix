# Git Interop Reference

## Colocated repos

When `.git/` is sibling of `.jj/`, the repo is "colocated". Git and jj share
the same commits. Imports/exports happen automatically. You can use `git log`
to see the same history, but always use `jj` commands to make changes.

## Bookmarks

Bookmarks are named pointers to commits. They do NOT advance automatically on
new commits (unlike Git branches). They DO follow when a commit is rewritten.
Bookmarks map to Git branches for push/fetch.

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

## Change ID push workflow

```bash
jj git push -c @                        # creates bookmark "push-<change_id>" and pushes
jj git push --named pr-123=@            # push @ under bookmark name "pr-123"
```

## Private commits

Commits matching `git.private-commits` revset are blocked from pushing by
default. Override with `--allow-private`.
