@AGENTS.md

## Claude Delivery Routing

Use Fable as main orchestrator. Keep planning, integration decisions, and final
user communication in main thread.

For explicit `/delivery-workflow` runs, route bounded work through its
`codex-lane` helper. Prefer Codex quota:

1. Spark for trivial latency-first read-only work and explicitly mechanical
   one-file edits.
2. Luna for discovery, probes, tests, and normal implementation.
3. Sol for plan review, code review, and ambiguous debugging.
4. Sonnet 5 implementer only for material correction batches, Codex
   throttling/unavailability, or explicit Claude-native work.

Outside that workflow, bundled Claude agents remain fallbacks. Do not spawn them
when a bounded Codex lane is available and fits task.

Never let worker own architecture, publishing, merge, push, pull-request, tag,
or release decisions. Exchange evidence packets and changed-file summaries, not
full transcripts.
