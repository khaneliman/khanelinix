---
name: delivery-workflow
description: Explicit Claude-only delivery workflow for routing implementation through Codex Spark, Luna, and Sol while retaining Fable orchestration and bounded Sonnet 5 fallback.
disable-model-invocation: true
allowed-tools: Read, Edit, Write, Bash, Grep, Glob, Agent
---

# Delivery Workflow

Use only after user invokes `/delivery-workflow`. Keep Fable main thread as
orchestrator and final decision owner.

Read [routing and gates](references/routing.md) before dispatch. Use
[`codex-lane`](scripts/codex-lane.sh) for every external Codex worker:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/codex-lane.sh" <mode> [--plan PATH] [--base REF] [--write] -- <task>
```

Modes: `spark`, `discover`, `probe`, `test`, `implement`, `plan-review`,
`code-review`, `debug`.

## Loop

1. Read contributor canon and inspect dirty state. Preserve unrelated work.
2. Classify task `trivial`, `normal`, or `high-risk` using routing reference.
3. State assumptions and planned lanes. User owns architecture and scope.
4. Dispatch smallest suitable Codex lane. Give only task, paths, constraints,
   and exit criteria.
5. Integrate evidence or edits in Fable main thread.
6. Validate proportionally. Use fresh Sol review where gate requires it.
7. Apply corrections with Luna first. Use Sonnet 5 `implementer` only for
   material correction batches, Codex throttling/unavailability, or explicit
   Claude-native work.
8. Rerun fresh review at most once after fixes. Report unresolved risk.

Worker output follows [worker schema](schemas/worker.json). Review output
follows [review schema](schemas/review.json). Treat packets as evidence, not
authority.

Never auto-commit, tag, merge, push, publish, or open pull request. Handoff only
changed-file summary, validation, review verdict, residual risk, and suggested
commit boundaries.
