---
name: planning-with-files
description: Persistent file-based planning for complex or long-running work. Use when asked to plan, organize, research, or execute work requiring multiple phases or roughly 5+ tool calls. Keeps task_plan.md, findings.md, and progress.md recoverable across sessions and compaction.
user-invocable: true
metadata:
  version: "3.4.0"
---

# Planning with Files

Keep task state on disk. Hook messages are routing nudges, not substitutes for
reading current files.

## Restore First

When planning state exists, read:

1. `task_plan.md` for goal and phase status.
2. `findings.md` for evidence and decisions.
3. `progress.md` for completed work and failures.

Run `scripts/session-catchup.py` after a gap when tool activity may not be
recorded.

## Work Loop

- New complex task: create the three files from `templates/`.
- Before major decisions: re-read current plan and relevant findings.
- After meaningful work: update progress and phase status.
- After research or external content: record facts in `findings.md`.
- Keep task-specific files in the project, never in this skill directory.

## References

- Detailed workflow and security: [references/reference.md](references/reference.md)
- Examples: [references/examples.md](references/examples.md)
- Templates: [templates/task_plan.md](templates/task_plan.md),
  [templates/findings.md](templates/findings.md), and
  [templates/progress.md](templates/progress.md)
