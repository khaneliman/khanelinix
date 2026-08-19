# Revset Language Complete Reference

## All operators (by precedence, strongest first)

1. `f(x)` -- function call
2. `x-` (parents), `x+` (children)
3. `p:x` -- string/date pattern
4. `x::` (descendants), `::x` (ancestors), `x::y` (DAG range), `x..y` (set
   diff), `x..`, `..x`, `::`, `..`
5. `~x` -- complement
6. `x & y` -- intersection, `x ~ y` -- difference
7. `x | y` -- union

DAG range `x::y` = descendants of x that are ancestors of y (connected path).
Set diff `x..y` = ancestors of y minus ancestors of x (like Git's `x..y`).

## All functions

### Commit selection

- `parents(x, [depth])`, `children(x, [depth])`
- `ancestors(x, [depth])`, `descendants(x, [depth])`
- `heads(x)`, `roots(x)`, `connected(x)` (= `x::x`)
- `reachable(srcs, domain)` -- all commits reachable within domain
- `fork_point(x)` -- greatest common ancestor(s)
- `first_parent(x)`, `first_ancestors(x)` -- follow first parent only
- `latest(x, [count])` -- most recent by committer date
- `at_operation(op, x)` -- evaluate revset at a past operation
- `coalesce(revsets...)` -- first non-empty revset
- `present(x)` -- returns none() if x doesn't exist (avoids errors)

### Named refs

- `bookmarks([pattern])`, `remote_bookmarks([name], [remote=])`
- `tags([pattern])`, `trunk()`
- `tracked_remote_bookmarks([name], [remote=])`,
  `untracked_remote_bookmarks([name], [remote=])`

### Commit properties

- `description(pattern)`, `subject(pattern)`
- `author(pattern)`, `committer(pattern)`
- `author_date(pattern)`, `committer_date(pattern)`
- `mine()` -- authored by configured user
- `empty()`, `merges()`, `conflicts()`, `divergent()`
- `files(expression)`, `diff_lines(text, [files])`

### Sets

- `all()`, `none()`, `visible_heads()`, `root()`
- `mutable()`, `immutable()`, `immutable_heads()`

## String patterns

Used in `bookmarks()`, `description()`, `author()`, etc.

- `exact:"value"` -- exact match
- `substring:"value"` -- contains (default for most)
- `glob:"pattern"` -- glob matching with `*`, `?`, `[...]`
- `regex:"pattern"` -- regular expression

Append `-i` for case-insensitive: `glob-i:"fix*"`, `regex-i:"TODO"`

## Date patterns

Used in `author_date()`, `committer_date()`.

- `after:"2024-01-01"`, `before:"2024-06-01"`
- `after:"2 days ago"`, `before:"yesterday 5pm"`
- ISO 8601: `after:"2024-02-01T12:00:00-08:00"`

## Workspace symbols

- `@` -- working-copy commit in the current workspace
- `<name>@` -- working-copy commit in workspace `<name>` (e.g., `feature-b@`)
- Valid in any revset context: `jj log -r 'feature-b@::'`

## Built-in aliases

- `trunk()` -- head of default bookmark on default remote
- `immutable_heads()` -- `trunk() | tags() | untracked_remote_bookmarks()`
- `immutable()` -- `::immutable_heads()`
- `mutable()` -- `~immutable()`
