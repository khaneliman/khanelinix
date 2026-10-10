---
description: "Show current planning status at a glance - phases, progress, and any logged errors."
---

Resolve the selected plan using `scripts/resolve-plan-dir.sh` from the installed
`planning-with-files` skill directory, with the project as the working directory.
Read `task_plan.md` in the returned directory and display a compact status
summary. An empty result means the repository-root legacy plan. Check findings
and progress in the same resolved directory.

## What to Show

1. **Current Phase**: Extract from "## Current Phase" section
2. **Phase Progress**: Count phases and their status
   (pending/in_progress/complete)
3. **Phase List**: Show each phase with status icon
4. **Errors**: Count entries in "## Errors Encountered" table if present
5. **Files Check**: Confirm which planning files exist

## Status Icons

- `[ ]` or "pending" → ⏸️
- "in_progress" → 🔄
- `[x]` or "complete" → ✅
- "failed" or "blocked" → ❌

## Output Format

```
📋 Planning Status

Current: Phase {N} of {total} ({percent}%)
Status: {status_icon} {status_text}

  {icon} Phase 1: {name}
  {icon} Phase 2: {name} ← you are here
  {icon} Phase 3: {name}
  ...

Files: task_plan.md {✓|✗} | findings.md {✓|✗} | progress.md {✓|✗}
Errors logged: {count}
```

## If No Planning Files Exist

```
📋 No planning files found

Run /plan to start a new planning session.
```

## Keep It Brief

This is a quick status check, not a full report. Show just enough to answer
"where am I?" without re-reading all the files.
