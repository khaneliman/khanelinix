# Template Language Reference

Templates customize output of `jj log`, `jj show`, `jj op log`, etc.
Use with `-T <template>`.

## Commit keywords

| Keyword | Type | Description |
|---|---|---|
| `description` | String | Full commit description |
| `change_id` | ChangeId | Stable change identifier |
| `commit_id` | CommitId | Content-addressed hash |
| `author` | Signature | Author name/email/timestamp |
| `committer` | Signature | Committer name/email/timestamp |
| `bookmarks` | List<Ref> | All bookmarks pointing here |
| `local_bookmarks` | List<Ref> | Local bookmarks |
| `remote_bookmarks` | List<Ref> | Remote bookmarks |
| `tags` | List<Ref> | Tags |
| `working_copies` | String | Workspace names with this as @ |
| `current_working_copy` | Bool | Is this @ in current workspace? |
| `conflict` | Bool | Has conflicts? |
| `empty` | Bool | No diff vs parent? |
| `immutable` | Bool | Is immutable? |
| `parents` | List<Commit> | Parent commits |
| `diff([files])` | TreeDiff | Changes in this commit |
| `mine` | Bool | Author matches configured user? |

## Common methods

```
change_id.short()          # first 12 chars
change_id.shortest()       # shortest unambiguous prefix
commit_id.short()          # first 12 chars
description.first_line()   # subject line
author.name()              # author name
author.email()             # author email
author.timestamp()         # commit timestamp
timestamp.ago()            # "2 hours ago"
timestamp.format("%Y-%m-%d")
bookmarks.join(", ")
parents.map(|c| c.commit_id.short())
```

## Operators

- `x ++ y` -- string concatenation
- `if(cond, then, else)` -- conditional
- `separate(sep, items...)` -- join non-empty items
- `surround(prefix, suffix, content)` -- wrap if non-empty
- `label(name, content)` -- color label

## Useful one-liners

```bash
# Compact log
jj log -T 'change_id.short() ++ " " ++ description.first_line() ++ "\n"' --no-graph --no-pager

# Show change ID and commit ID
jj log -T 'change_id.shortest() ++ " (" ++ commit_id.short() ++ ") " ++ description.first_line() ++ "\n"' --no-graph --no-pager

# Description only
jj show -T 'description' --no-pager -r <rev>
```
