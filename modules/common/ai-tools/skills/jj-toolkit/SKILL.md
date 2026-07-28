---
name: jj-toolkit
description: Use for working with Jujutsu (jj) history workflows, including hunk-level split/squash/diffedit/restore via `jj-hunk-tool`.
---

# Jujutsu Toolkit

Route to one mode and read only its reference:

1. **hunk-edit** — split, squash, restore, or move exact hunks with
   `jj-hunk-tool`. Read [jj-surgeon.md](references/jj-surgeon.md).
2. **conflicts** — resolve conflicted changes or rebases. Read
   [conflict-resolution.md](references/conflict-resolution.md).
3. **bisect** — identify a first bad change. Read
   [bisect.md](references/bisect.md).
4. **git-interop** — bookmarks, colocated repositories, push visibility, and
   GitHub boundaries. Read [git-interop.md](references/git-interop.md).
5. **revsets/templates** — write or debug selection and output expressions. Read
   [revset-reference.md](references/revset-reference.md) or
   [template-reference.md](references/template-reference.md).
6. **workspaces** — create, inspect, or clean up parallel workspaces. Read
   [workspaces.md](references/workspaces.md).

Use model-known `jj` mechanics for routine operations. Load the upstream
`jj-surgeon` guide only for hunk-level work or when another focused reference
routes there.

## Non-negotiable: move the bookmark

In a git-colocated repo, moving the bookmark is part of finishing a change, not
a follow-up. Committing without it leaves the Git branch behind and the work
invisible to `git log`, `gh`, CI, and reviewers — the most common agent failure
mode with jj. A commit with no bookmark on it is not on a branch.

Before reporting any jj work done, confirm the bookmark sits on your stack tip
and `@` is empty. Follow
[references/git-interop.md](references/git-interop.md#bookmark-discipline-mandatory)
— read it before your first commit, not after.

MIT attribution:
[references/LICENSE-jj-hunk-tool](references/LICENSE-jj-hunk-tool).
