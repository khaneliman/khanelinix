---
name: jj-surgeon
description: Comprehensive guide for working with Jujutsu (jj) version control. Use whenever inspecting or modifying jj changes or commits, including managing, viewing, creating, editing, splitting, squashing, rebasing, reordering, and changing history — including hunk-level operations, bookmarks, conflict resolution, revsets, bisecting, and all standard jj workflows.
---

# Jujutsu (jj) Agent Guide

## Key concepts

**Working copy is always a commit.** The working directory is automatically
snapshotted into commit `@` at the start of every jj command. There is no
staging area. All file changes are immediately part of `@`.

**"Clean" means an empty `@`.** When `@` has no diff vs its parent, the working
copy is clean. You do NOT need to `jj abandon` an empty `@` — it is harmless
and jj creates a new empty `@` automatically after operations that consume it.
**Always finish your work with a clean `@`.** Use `jj commit -m "message"`
(not `jj describe`) when you're done with a change — `jj commit` finalizes `@`
and creates a new empty working copy on top. If you use `jj describe` instead,
`@` still contains your changes and you're still "editing" it. This is the jj
equivalent of leaving a dirty working copy in Git.

**Change IDs vs commit IDs.** Every commit has two identifiers:
- *Change ID* — stable across rewrites (rebase, amend, squash). Shown as
  reversed-hex letters (k-z). Use this to refer to changes you plan to rewrite.
- *Commit ID* — content hash (standard hex). Changes on every rewrite. Matches
  the Git SHA in colocated repos. Becomes permanent once immutable.

**No branches, only bookmarks.** Bookmarks are named pointers to commits. They
do NOT advance automatically on new commits (unlike Git branches). They DO
follow when a commit is rewritten. See
[references/git-interop.md](references/git-interop.md).

**Editing history is safe — but watch for conflicts.** jj rewrites commits
freely and automatically rebases descendants. If a rebase causes overlapping
changes, jj records a conflict in the descendant commit and warns you.
Conflicts are data (not blocking states) but must be resolved before the code
compiles. See
[references/conflict-resolution.md](references/conflict-resolution.md).

**Operation log.** Every command creates an operation entry. `jj undo` reverts
the last operation. `jj op restore <id>` jumps to any past state.

## Always pass these flags

```bash
# When viewing diffs:
jj diff --git --no-pager
jj show --git --no-pager @-
jj diff --git --no-pager -r <rev>
jj log --no-pager -p --git -r <revset>

# These prevent pager hangs and ensure machine-readable unified diff output.
```

## Hunk-level operations

Several jj commands (`split`, `squash`, `diffedit`, `restore`) can operate at
the hunk level, but only through an interactive diff editor — **which agents
must never use**. `jj-hunk-tool` provides non-interactive equivalents using
stable hunk IDs. These are shown alongside their native jj counterparts
throughout this guide.

### Listing hunks

```bash
jj-hunk-tool hunks                      # list hunks in @ with IDs and line numbers
jj-hunk-tool hunks -r <rev>             # from a specific revision
jj-hunk-tool hunks --file src/main.rs   # filter to one file
jj-hunk-tool hunks --compact            # brief preview (no line numbers)
```

### Hunk IDs

- 7-char hex strings derived from file path + hunk content
- Stable across runs as long as the diff hasn't changed
- Duplicates get `-2`, `-3` suffixes
- If not found, re-run `hunks` for fresh IDs
- Line ranges: `id:5-30` (1-based, from `hunks` output)
- Multiple ranges: `id:2-6,34-37`

### Generating patches

```bash
jj-hunk-tool patch <id1> <id2:1-10>             # unified diff for selected hunks
jj-hunk-tool patch <id>:5-30,40-50 -r <rev>     # with line ranges and revision
jj-hunk-tool patch --reverse <id>                # reverse patch
```

## Creating and describing changes

```bash
jj new                                  # new empty change on top of @
jj new <rev>                            # new change on top of <rev>
jj new <rev1> <rev2>                    # new merge commit
jj new -A <rev>                         # insert after <rev>, rebasing descendants
jj new -B <rev>                         # insert before <rev>
jj commit -m "message"                  # set description on @, create new empty @
jj describe -m "message"                # set/update description (default: @)
jj describe <rev> -m "message"          # describe a specific revision
jj edit <rev>                           # set <rev> as @ (edit a historical change)
```

After `jj edit <rev>`, any file changes you make modify `<rev>` directly and
all descendants are rebased. Check `jj log -r 'conflicts()'` afterward. When
done, use `jj new` to stop editing and create a fresh empty `@`.

## Viewing changes

```bash
jj status                               # working copy status
jj diff --git --no-pager                # working copy diff
jj diff --git --no-pager -r <rev>       # diff of specific revision
jj show --git --no-pager <rev>          # description + diff
jj log --no-pager                       # commit graph
jj log --no-pager -r '<revset>' -p --git  # graph with patches
jj file annotate <path>                 # blame (which change introduced each line)
```

## Splitting

```bash
jj split path/to/file -m "these files"           # split by file
jj-hunk-tool split <id1> <id2> -m "msg"          # split by hunk
jj-hunk-tool split <id>:1-11 -r <rev> -m "msg"   # hunk + line range from other rev
jj-hunk-tool split <id> -r <rev> -p              # parallel siblings
jj-hunk-tool split <id> -A <rev>                 # insert after
```

**Always pass `-m`** to `jj split` and `jj-hunk-tool split`. Without `-m`, jj
opens `$EDITOR` for each resulting commit.

**Do not use bare `jj split` (without file paths).** It opens an interactive
diff editor. Use `jj split path/to/file` for file-level splits or
`jj-hunk-tool split` for hunk-level splits.

Splitting rewrites the target revision, so all descendants are rebased. jj
will warn if this creates conflicts — resolve them before continuing. See
[references/conflict-resolution.md](references/conflict-resolution.md).

## Squashing and absorbing

```bash
jj squash -m "msg"                                # squash @ into parent
jj squash -r <rev> -m "msg"                       # squash <rev> into its parent
jj squash --from <src> --into <dst> -m "msg"      # move changes between revisions
jj-hunk-tool squash <id1> <id2> -m "msg"          # squash specific hunks into parent
jj-hunk-tool squash <id> --from <rev> --into <rev> -m "msg"
```

**Always pass `-m` to `jj squash`.** Without `-m`, jj opens `$EDITOR`.

**Warning:** `jj squash` rewrites the destination commit, causing all its
descendants to be rebased. jj will warn if this creates conflicts — resolve
them before continuing. See
[references/conflict-resolution.md](references/conflict-resolution.md).

### Absorbing

`jj absorb` auto-distributes changes from `@` into the correct mutable
ancestors by blame — extremely powerful for fixup workflows.

```bash
jj absorb                               # auto-distribute @ into ancestors
jj absorb --from <rev>                  # absorb from specific revision
jj-hunk-tool absorb                     # hunk-aware absorb (whole-hunk routing)
jj-hunk-tool absorb <id1> <id2>         # absorb specific hunks only
jj-hunk-tool absorb --dry-run           # preview routing plan
```

Always review with `jj op show -p --no-pager` afterward.

`jj-hunk-tool absorb` differs from `jj absorb`: it treats each hunk as an
atomic unit and routes based on deleted/modified line blame. Pure insertions
fall back to the most recent mutable ancestor that touched the same file. New
files stay in `@`. Ambiguous hunks (lines from multiple ancestors) stay in `@`
with candidates printed.

## Editing diffs in place

```bash
jj-hunk-tool diffedit <id1> <id2> -r <rev>  # keep only selected hunks in <rev>
```

**Do not use bare `jj diffedit`.** It opens an interactive diff editor. Use
`jj-hunk-tool diffedit` with explicit hunk IDs instead.

## Restoring (undoing changes)

```bash
jj restore <paths...>                   # restore files in @ from parent
jj restore --from <rev> <paths...>      # restore files from specific revision
jj restore -c <rev>                     # undo all changes introduced by <rev>
jj-hunk-tool restore <id1> <id2>        # undo specific hunks from @
jj-hunk-tool restore <id> -c <rev>      # undo specific hunks from <rev>
jj-hunk-tool restore <id> --from <rev> --into <rev>
```

## Rebasing and reordering

```bash
jj rebase -r <rev> -d <dest>            # move single commit onto dest
jj rebase -s <rev> -d <dest>            # move commit + descendants
jj rebase -b <rev> -d <dest>            # move whole branch
jj rebase -r <rev> -A <after>           # insert after (reorder)
jj rebase -r <rev> -B <before>          # insert before
jj rebase -s @ -d main                  # rebase current stack onto main
```

Rebasing can create conflicts if the new base has diverged. jj will warn if
this happens — resolve them before continuing. See
[references/conflict-resolution.md](references/conflict-resolution.md).

## Undoing operations

```bash
jj undo                                 # undo last operation
jj op log --no-pager -n 10              # view recent operation history
jj op restore <op-id>                   # restore to any past state
jj revert -r <rev> -d @                 # create reverse-patch of <rev> on @
jj abandon <rev>                        # drop a revision, rebase descendants
```

## Conflicts

```bash
jj log -r 'conflicts()'                # find commits with conflicts
jj resolve --list                       # list conflicted files in @
jj resolve --list -r <rev>             # list conflicted files in specific revision
```

Conflicts are first-class data — a commit can contain conflicts and still be
rebased, squashed, or pushed. **For agents, the most reliable resolution method
is reading the conflicted file and editing out the conflict markers directly.**
jj's conflict markers differ from Git's — see
[references/conflict-resolution.md](references/conflict-resolution.md) for the
format and resolution strategies.

## Revsets

Revsets select sets of commits. Used with `-r` on most commands.

### Symbols

| Symbol | Meaning |
|---|---|
| `@` | Working copy commit |
| `@-` | Parent of `@` (shorthand for `@-1`) |
| `@--` | Grandparent of `@` |
| `root()` | Root commit |
| `trunk()` | Head of default remote's default branch |
| `<change_id>` | Commit by change ID (or unique prefix) |
| `<bookmark>` | Commit at bookmark |

### Operators

| Syntax | Meaning |
|---|---|
| `x-` | Parents of x |
| `x+` | Children of x |
| `::x` | Ancestors of x (inclusive) |
| `x::` | Descendants of x (inclusive) |
| `x::y` | DAG range: ancestors of y that are descendants of x |
| `x..y` | Set difference: ancestors of y minus ancestors of x |
| `~x` | Complement |
| `x & y` | Intersection |
| `x \| y` | Union |
| `x ~ y` | Difference (x minus y) |

### Common patterns

```bash
trunk()..@             # changes on current stack not yet on trunk
@::                    # @ and all descendants
ancestors(@, 5)        # last 5 ancestors
mutable() & ancestors(@)  # mutable ancestors of @
description("fixup")   # commits with "fixup" in description
mine() & mutable()     # my mutable commits
conflicts()            # all commits with conflicts
```

For the complete function reference, string/date patterns, and workspace
symbols, see [references/revset-reference.md](references/revset-reference.md).

## Workflows

### Stacking changes

```bash
jj commit -m "feature part 1"           # finalize @, create new empty @
# ... work ...
jj commit -m "feature part 2"
jj log --no-pager -r 'trunk()..@'       # see the stack
```

### Blame-guided fixup

```bash
jj file annotate src/main.rs            # find which change touched each line
jj-hunk-tool hunks                      # list current hunks
jj-hunk-tool squash <id> --into <target> -m "fix bug"
```

### Discard specific hunks

```bash
jj-hunk-tool hunks                      # list hunks
jj-hunk-tool restore <id1> <id2>        # undo those hunks
```

### Auto-fixup with absorb

```bash
# Make fixes in working copy, then:
jj absorb                               # auto-distribute to correct ancestors
jj op show -p --no-pager                # review what happened

# Or hunk-aware absorb:
jj-hunk-tool absorb --dry-run           # preview routing
jj-hunk-tool absorb                     # execute
```

### Reorder commits in a stack

```bash
jj rebase -r <rev> -A <after>           # move <rev> after <after>
jj rebase -r <rev> -B <before>          # move <rev> before <before>
```

### Undo mistakes

```bash
jj undo                                 # undo last operation
jj op log --no-pager                    # find operation to restore
jj op restore <op-id>                   # restore to any point
```

## Common pitfalls for agents

- **NEVER use `-i` / `--interactive` flags.** Commands like `jj split -i`,
  `jj squash -i`, `jj restore -i`, `jj-hunk-tool absorb -i`, etc. open an
  interactive diff editor or prompt that waits for terminal input. This will
  hang indefinitely. Use `jj-hunk-tool` with explicit hunk IDs instead.
- **NEVER use bare `jj split` (without file paths).** It opens a diff editor.
  Use `jj split path/to/file` for file-level or `jj-hunk-tool split` for
  hunk-level.
- **NEVER use bare `jj diffedit`.** It opens a diff editor. Use
  `jj-hunk-tool diffedit` with explicit hunk IDs.
- Do NOT `jj abandon @` to "clean up" an empty working copy. It's normal.
- **Always leave `@` empty when you're done working.** Use `jj commit -m "msg"`
  to finalize a change — NOT `jj describe`, which leaves your changes in `@`.
- Do NOT use `git` commands in a jj repo. Always use `jj`.
- Always pass `--git --no-pager` when viewing diffs.
- Always pass `--no-pager` to `jj log`, `jj op log`, `jj bookmark list`.
- **Always pass `-m "message"` to `jj commit`, `jj describe`, `jj squash`,
  `jj split`, and any other command that sets a commit message** — unless the
  user explicitly asks to write the message in their editor.
- `jj diff` with no `-r` shows `@` vs parent. Use `-r <rev>` for other revisions.
- After `jj commit -m "msg"`, the described change is `@-` (the parent). `@` is
  the new empty working copy.
- Immutable commits (on trunk, tags, remote bookmarks) cannot be rewritten.
  Use `mutable()` revset to find what you can edit.
- `jj squash` without args squashes `@` into `@-`. With `--from`/`--into` you
  can squash between any two mutable commits.
- After any history rewrite, jj will warn if conflicts were created. Resolve
  them immediately — cascading conflicts are much harder to fix. See
  [references/conflict-resolution.md](references/conflict-resolution.md).
  Use `jj log -r 'conflicts()'` if you need to find all conflicted commits.

## Reference docs

- [Revsets](references/revset-reference.md) — full function list, string/date patterns
- [Conflict resolution](references/conflict-resolution.md) — marker format, reading guide, strategies
- [Git interop](references/git-interop.md) — bookmarks, pushing, remotes, colocated repos
- [Workspaces](references/workspaces.md) — multiple working copies, sparse checkouts
- [Templates](references/template-reference.md) — custom log/show output
- [Bisect](references/bisect.md) — binary search for regressions with `jj bisect run`
