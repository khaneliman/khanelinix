## Codex Delegation

Use main thread for planning, integration, and final decisions.

Use persisted goals only for explicit long-running objectives. Keep routine
fact-finding disposable: delegate, receive evidence packet, discard worker
context.

Delegate aggressively when work can be bounded. Prefer configured GPT-5.6
workers for repo discovery, noisy command output, checks, reviews, and
independent fact slices that would otherwise bloat main context.

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

Use GPT-5.6 agents by default. Reserve `gpt-5.3-codex-spark` for trivial,
latency-first tasks where expected output is obvious and failure is cheap.

## Retry Circuit Breaker

AgentsView shows repeated tool retries as the strongest failure predictor. After
two failures from the same command family, same endpoint, same test target, or
same patch shape:

1. Stop repeating it.
2. State the two attempts and observed failure signals.
3. Change lane: simplify the probe, inspect source/config, delegate to
   `debugger`/`probe-runner` when available, or ask for the missing decision.
4. Resume only with a materially different command, narrower scope, or new
   evidence.

## Large Change-Stack Routing

For upstream contribution, multi-commit, PR-stack, migration, branch-review, or
large history-shaping work, split early:

- Main thread owns goal, commit boundaries, final judgment, and integration.
- `fact-finder`: upstream issue/PR context, changed-path ownership, caller
  tracing, and relevant provenance.
- `probe-runner`: focused eval/build/test checks, noisy logs, GitHub/CI probes.
- `test-runner`: broad suites or repeated failure analysis.

Pass workers only paths, refs, commands allowed, and exit criteria. Do not pass
full conversation unless the worker needs it.
