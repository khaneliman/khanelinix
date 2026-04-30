# Conflict Resolution Reference

## How conflicts arise

jj automatically rebases descendants when you rewrite a commit. If a descendant
modified the same lines you changed, jj records a **conflict** in that
descendant. Conflicts are first-class data — the commit still exists, you can
log it, diff it, and even rebase it further. But the working copy will contain
conflict markers and the code won't compile until resolved.

Common triggers:
- `jj edit <rev>` then modifying code → descendants that touched the same code
  get conflicts on rebase
- `jj squash --from A --into B` where descendants of B overlap with A's changes
- `jj rebase` moving commits to a new base that has diverged
- Fixing clippy/fmt warnings in an early commit when later commits touched the
  same lines

## Detecting conflicts

```bash
jj log --no-pager                    # conflicted commits show "(conflict)" marker
jj log -r 'conflicts()'             # list only conflicted commits
jj resolve --list                    # list conflicted files in @
jj resolve --list -r <rev>          # list conflicted files in specific revision
```

When you `jj edit` a conflicted commit, the warning is printed immediately:
```
Warning: There are unresolved conflicts at these paths:
src/main.rs    2-sided conflict
src/tool.rs    2-sided conflict
```

## Conflict marker format

jj uses a unique conflict format (NOT the same as Git's `<<<< ==== >>>>`):

### 2-sided conflict (most common)

```
<<<<<<< conflict 1 of N
%%%%%%% diff from: <parent info>
\\\\\\\        to: <rebase destination info>
 context line (unchanged)
-old line (removed by the diff)
+new line (added by the diff)
+++++++ <rebased revision info>
replacement content from the rebased revision
>>>>>>> conflict 1 of N ends
```

**Key insight:** The `%%%%%%%` section is a **diff** (with `-` and `+` lines),
not literal content. The `+++++++` section is **literal content** from the
incoming revision. To resolve, you must understand both and pick/merge the right
result.

### Reading the conflict

1. **Between `%%%%%%%` and `+++++++`**: A diff showing what the rebase
   destination changed relative to the original parent. Lines prefixed with
   space are context, `-` are removed, `+` are added.
2. **Between `+++++++` and `>>>>>>>`**: The literal content from the rebased
   (incoming) revision — what the code looks like in the commit being rebased.
3. **Before `<<<<<<<` and after `>>>>>>>`**: Surrounding code that both sides
   agree on.

### Example

If commit A changed `foo()` to `bar()`, and descendant commit B replaced the
entire function with new code, you'll see:

```
<<<<<<< conflict 1 of 1
%%%%%%% diff from: A-original
\\\\\\\        to: A-modified
-fn foo() {
+fn bar() {
+++++++ B
fn completely_new() {
    // new implementation
}
>>>>>>> conflict 1 of 1 ends
```

Resolution: decide whether B's new code should use `bar` (A's rename) or keep
its own name, then replace the entire `<<<<<<< ... >>>>>>>` block with the
correct code.

## Resolution strategies

### Strategy 1: Edit conflict markers directly (most common)

1. Read the conflicted file with `Read` tool
2. Understand what each side intended
3. Replace the entire `<<<<<<< ... >>>>>>> ... ends` block with correct code
4. Use the `Edit` tool to make the replacement
5. Verify with `cargo clippy` / `cargo fmt` / compilation

This is the best strategy when you understand both sides. It's what you'll use
95% of the time.

### Strategy 2: Take one side entirely

```bash
# Take the rebase destination's version ("ours" = where we're rebasing to)
jj resolve --tool :ours

# Take the rebased revision's version ("theirs" = the commit being rebased)
jj resolve --tool :theirs
```

Use when one side is clearly correct and the other should be discarded.

### Strategy 3: Re-apply your changes

If the conflict is from your own edits to an ancestor:
1. Note what you changed (the diff in the `%%%%%%%` section)
2. Take the `+++++++` side (the descendant's content)
3. Re-apply your changes on top of it

## Practical workflow for editing ancestor commits

When you `jj edit <ancestor>` and make changes (e.g., clippy fixes), expect
conflicts in descendants that touched the same code. The workflow is:

```bash
jj edit <ancestor>              # edit the target commit
# ... make changes ...
# jj shows "Rebased N descendant commits" — some may conflict

# Check for conflicts:
jj log --no-pager -r 'descendants(@) & conflicts()'

# For each conflicted descendant:
jj edit <conflicted-change>
# Read the conflicted files, resolve markers, verify compilation
# Then move to the next one
```

**Always resolve conflicts before moving on.** If you leave a conflict and edit
a further descendant, you may create cascading conflicts that are harder to
untangle.

## Tips

- **Conflicts from formatting/clippy fixes** are usually simple: the `%%%%%%%`
  section shows your formatting change, and the `+++++++` section shows the
  descendant's rewritten code. Take the `+++++++` content and apply the same
  formatting fix to it.

- **Conflicts from removing unused code** (imports, functions) in an ancestor
  where a descendant adds usage: take the `+++++++` side which has the code that
  uses the import/function.

- **Multiple conflicts in one file**: each is independently marked with
  `conflict 1 of N`, `conflict 2 of N`, etc. Resolve all of them.

- **After resolving**, run `cargo clippy --all-targets && cargo fmt` to ensure
  the resolution is correct. A bad merge is worse than a conflict.

- **Use `jj resolve --list`** to check which files still have conflicts. Once
  all are resolved, the commit drops its "(conflict)" marker automatically.

- **If resolution goes wrong**, `jj undo` reverts your last operation.
  Alternatively, the conflict markers are still valid data — you can re-read
  and try again.
