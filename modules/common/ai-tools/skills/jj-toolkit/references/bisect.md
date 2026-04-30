# Bisect Reference

## Overview

`jj bisect run` performs automated binary search over a range of revisions to
find where a bug was introduced (or fixed). It checks out each candidate
revision and runs a command to determine good/bad.

## Usage

```bash
jj bisect run --range <good>..<bad> -- <command> [args...]
```

- **`--range`** (required): A revset range. The heads (newest) are assumed bad;
  ancestors outside the range are assumed good. Typically `v1.0..main` or
  `<known-good>..<known-bad>`.
- **`<command>`**: Evaluated at each candidate revision. Exit codes:
  - `0` = good (bug not present)
  - `125` = skip this revision (can't test, e.g. doesn't compile)
  - `127` = abort bisection (command not found)
  - Any other non-zero = bad (bug present)

The candidate's commit ID is available in `$JJ_BISECT_TARGET`.

## Examples

```bash
# Find which commit broke the tests
jj bisect run --range v1.0..main -- cargo nextest run

# Find which commit broke a specific test
jj bisect run --range v1.0..main -- cargo nextest run -E 'test(my_test)'

# Complex check via shell one-liner
jj bisect run --range abc..xyz -- bash -c \
  'cargo build 2>&1 | grep -q "error" && exit 1 || exit 0'

# Interactive: drop into a shell, test manually, exit 0 or 1
jj bisect run --range v1.0..main -- bash

# Apply a patch at each step before testing
jj bisect run --range v1.0..main -- bash -c \
  'jj duplicate -r fixrev -B @ && cargo nextest run'
```

## Finding the first good revision

By default, bisect assumes heads are bad and finds the first bad revision.
`--find-good` inverts this to find the first good revision.

```bash
jj bisect run --range v1.0..main --find-good -- cargo nextest run
```

## Agent patterns

### Skip non-compiling revisions

Use exit code 125 to skip revisions that fail for unrelated reasons:

```bash
jj bisect run --range v1.0..main -- bash -c \
  'cargo check 2>&1 || exit 125; cargo nextest run -E "test(specific_test)"'
```

### Identify the range first

```bash
jj log --no-pager -r 'trunk()..@' \
  -T 'change_id.short() ++ " " ++ description.first_line() ++ "\n"' --no-graph
# Pick known-good and known-bad from the list, then:
jj bisect run --range <good>..<bad> -- <test command>
```

### Manual binary search (no automation)

When `jj bisect run` doesn't fit:

```bash
jj log --no-pager -r '<good>..<bad>' --no-graph \
  -T 'change_id.short() ++ " " ++ description.first_line() ++ "\n"'
# Pick the middle revision, test it, narrow the range, repeat
```

## Tips

- The command runs in the workspace root (`$JJ_WORKSPACE_ROOT` is set).
- Bisect does not modify history — it only checks out revisions temporarily.
- After bisect completes, your working copy is restored.
- Use `--` before the command to prevent jj from interpreting its flags.
- For long test suites, narrow the range first with a quick check (e.g., grep
  for a known-bad pattern) before running full tests.
