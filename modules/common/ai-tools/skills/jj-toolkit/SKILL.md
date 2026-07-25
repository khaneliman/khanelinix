---
name: jj-toolkit
description: Use for working with Jujutsu (jj) history workflows, including hunk-level split/squash/diffedit/restore via `jj-hunk-tool`.
---

# Jujutsu Toolkit

Use for `jj` / `jj-hunk-tool` workflows: stack inspection, revsets,
splits/squashes, rebases, absorb/undo, conflict handling, bisect, and
line-precise hunk operations.

Before acting, read the full upstream guide —
[references/jj-surgeon.md](references/jj-surgeon.md) — which covers
`jj-hunk-tool` command mapping and hunk IDs, full `jj` workflows, conflict and
bisect guidance, and revset/workspace reference tables.

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
