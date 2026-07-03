## Codex Delegation

Use main thread for planning, integration, and final decisions.

Delegate only when a worker result feeds the next main-thread decision.

Before spawning:

1. Name the missing fact, probe result, or review slice.
2. Pick the smallest worker:
   - `fact-finder` for read-only evidence gathering.
   - `probe-runner` for bounded non-destructive command or browser checks.
   - `test-runner` for broader test suites or noisy failure loops.
   - `debugger` for ambiguous root-cause analysis.
3. Pass only task, paths/cwd, constraints, allowed tool or skill lane, and exit
   criteria. Do not pass full conversation unless required.
4. Continue local integration work while the worker runs when possible.
5. Treat worker output as an evidence packet. Main thread owns synthesis, edits,
   risk decisions, and final answer.

Use `gpt-5.3-codex-spark` agents for narrow deterministic tasks with clear
inputs and evidence-only outputs. Use stronger agents for ambiguous debugging,
architecture, risky edits, and final synthesis.
