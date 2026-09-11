---
name: planning-with-files
description: "Optional persistent file-based planning for multi-phase or long-running work that benefits from recovery across sessions or compaction. Use when requested or when persistence materially improves continuity."
metadata:
  version: "3.4.0"
---

# Planning with Files

## Codex session attachment

Codex hooks require an explicit attachment before relying on planning context
or Stop gating:

```sh
scripts/attach-session.sh <session-id> <plan-id>
```

Use `.` to intentionally attach the repository-root legacy `task_plan.md`.
Unattached sessions receive no planning context or planning Stop gate.

Use persistent markdown files as working memory when a task intentionally opts
into cross-session or compaction recovery. Hook behavior is provider-specific;
this canonical package is the provider-neutral routing layer. Harness adapters
may add hooks without changing the workflow contract.

## Restore First

When the current task has intentionally adopted planning state, read:

- `task_plan.md`
- `findings.md`
- `progress.md`

Recover missing execution evidence from the relevant task session. The bundled
`scripts/session-catchup.py` searches project-wide history; use it only for an
intentional historical investigation, not automatic session recovery.

## Start or Continue

- New persistent plan: create `task_plan.md`, `findings.md`, and `progress.md`
  from templates after choosing this workflow.
- Existing plan: re-read the files before major decisions.
- After each phase: update phase status and append progress.
- After research or external content: record facts in `findings.md`, not
  `task_plan.md`.
- Existing plan files do not activate this workflow for unrelated tasks.

## References

- Detailed workflow and security notes: [reference.md](reference.md)
- Example plans and logs: [examples.md](examples.md)
- Templates: [templates/task_plan.md](templates/task_plan.md),
  [templates/findings.md](templates/findings.md),
  [templates/progress.md](templates/progress.md)
