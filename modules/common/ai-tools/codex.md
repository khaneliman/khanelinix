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

Pick smallest worker:

1. `fact-finder` for read-only evidence gathering.
2. `probe-runner` for bounded non-destructive command or browser checks.
3. `test-runner` for broader test suites or noisy failure loops.
4. `debugger` for ambiguous root-cause analysis.

Pass only task, paths, constraints, allowed skill/tool lane, and exit criteria.
Continue local integration while worker runs; treat result as evidence packet.
Use `git-toolkit` change-stack mode for multi-commit or PR-stack boundaries.

Do not delegate tiny one-command answers, work that needs full conversation
context, or final product/design/architecture decisions.

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
