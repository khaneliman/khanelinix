## Codex Delegation

Use main thread for planning, integration, and final decisions.

Use persisted goals only for explicit long-running objectives. Keep routine
fact-finding disposable: delegate, receive evidence packet, discard worker
context.

Spend Spark helper quota aggressively when the work can be bounded. Delegate
early for repo discovery, noisy command output, checks, reviews, and independent
fact slices that would otherwise bloat main context.

Delegate when:

- discovery spans multiple files, callers, modules, commits, or config paths
- command output may be long or noisy
- tests, builds, evals, or browser probes can run while main thread reads code
- review can split by file, module, commit, or concern
- the worker can return evidence without owning final judgment

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

Do not delegate tiny one-command answers, work that needs full conversation
context, or final product/design/architecture decisions.

Use `gpt-5.3-codex-spark` agents by default for bounded evidence, probes, and
test analysis. Use stronger agents for ambiguous debugging, architecture, risky
edits, and final synthesis.
