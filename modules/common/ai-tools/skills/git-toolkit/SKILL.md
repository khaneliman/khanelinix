---
name: git-toolkit
description: Git commit planning, fixup/autosquash, branch cleanup, conflict resolution, regression bisect, and multi-commit change-stack workflows. Use for safe local history operations or deciding how changes should be split, repaired, or validated.
---

# Git Toolkit

Route Git work to one mode and load only its reference.

## How I choose what to do (progressive disclosure)

When invoked, route to one mode:

1. **commit-discipline** — plan atomic commits, draft messages, or choose
   amend/fixup/autosquash. Read
   [commit-discipline.md](references/commit-discipline.md).
2. **hunk-history** — split, move, restore, amend, or squash selected hunks with
   `git-surgeon`. Read [git-surgeon.md](references/git-surgeon.md).
3. **regression-bisect** — locate a first bad commit. Read
   [bisect.md](references/bisect.md).
4. **change-stack** — shape or review multi-commit branches and PR stacks. Read
   [change-stack.md](references/change-stack.md).
5. **routine-workflow** — branch cleanup, merge/rebase choice, conflict
   resolution, or standard Git operations. Git mechanics are model-known; read
   [operating-rules.md](references/operating-rules.md) only when shared-history
   risk or GitHub boundaries matter.
6. **github-toolkit** — issues, pull requests, review feedback, and CI state.
   Use [`github-toolkit`](../github-toolkit/).

If intent is unclear, ask for the mode before applying changes.

Repository contributor docs and existing history remain authoritative. This
skill supplies workflow defaults where repository canon is silent.
