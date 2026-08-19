---
name: git-toolkit
description: Git commit planning, branch naming and cleanup, fixup/autosquash, conflict resolution, regression bisect, independent single-reviewer change review, and multi-commit change-stack workflows. Use for safe local history operations or deciding how changes should be split, repaired, reviewed, or validated. Use interrogate for multi-model adversarial review.
---

# Git Toolkit

Route Git work to one mode and load only its reference.

## How I choose what to do (progressive disclosure)

When invoked, route to one mode:

1. **commit-discipline**: plan atomic commits, draft messages, or choose
   amend/fixup/autosquash. Read
   [commit-discipline.md](references/commit-discipline.md).
2. **hunk-history**: split, move, restore, amend, or squash selected hunks with
   `git-surgeon`. Read [git-surgeon.md](references/git-surgeon.md).
3. **regression-bisect**: locate a first bad commit. Read
   [bisect.md](references/bisect.md).
4. **change-stack**: shape or review multi-commit branches and PR stacks. Read
   [change-stack.md](references/change-stack.md).
5. **adversarial-review**: independently review a commit, PR, or diff against
   falsifiable design premises and repository-wide constraints. Read
   [adversarial-review.md](references/adversarial-review.md).
6. **routine-workflow**: branch creation, naming, cleanup, merge/rebase choice,
   conflict resolution, or standard Git operations. Git mechanics are
   model-known; read [operating-rules.md](references/operating-rules.md) when
   naming a branch or when shared-history risk or GitHub boundaries matter.
7. **github-toolkit**: issues, pull requests, review feedback, and CI state.
   Invoke `$github-toolkit`; do not depend on a sibling filesystem path.

If intent is unclear, ask for the mode before applying changes.

Read [scripts.md](references/scripts.md) when deterministic stack collection or
an isolated automated bisect can replace manual Git command assembly.

MIT attribution for `git-surgeon`:
[LICENSE-git-surgeon](references/LICENSE-git-surgeon).

Repository contributor docs and existing history remain authoritative. This
skill supplies workflow defaults where repository canon is silent.
