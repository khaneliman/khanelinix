# Provider and Agent Routing

The [model-routing registry](model-routing.json) owns model, role, task, and
quota-pool data. After a policy edit, run
[`render-model-routes.py`](../scripts/render-model-routes.py) with `render`,
apply the generated section update, then run it with `check`.

## Subscription map

<!-- BEGIN GENERATED SUBSCRIPTIONS -->

| Subscription         | Model agents                                                                                 |
| -------------------- | -------------------------------------------------------------------------------------------- |
| OpenAI (Codex)       | `gpt-5-3-codex-spark`, `gpt-5-6-luna`, `gpt-5-6-terra`, `gpt-5-6-sol`                        |
| Google (Antigravity) | `gpt-oss-120b`, `google-opus-4-6`, `google-sonnet-4-6`, `gemini-3-7-flash`, `gemini-3-1-pro` |
| Anthropic            | `opus-5`, `fable-5`, `sonnet-5`                                                              |

<!-- END GENERATED SUBSCRIPTIONS -->

Prefer `opus-5` for Anthropic implementation and diagnosis. Use `fable-5` for
independent planning or review; use `sonnet-5` only when explicitly requested.
Keep Gemini fallback-only. Every subscription requires a live route and current
authentication.

## Preferred routes

<!-- BEGIN GENERATED ROUTES -->

| Need                                       | Primary               | Fallback                                    | Semantic role  | Write policy                      |
| ------------------------------------------ | --------------------- | ------------------------------------------- | -------------- | --------------------------------- |
| obvious lookup or mechanical one-file edit | `gpt-5-3-codex-spark` | `gpt-5-6-luna`, `gemini-3-7-flash`          | `mechanic`     | read-only unless edit is explicit |
| repository discovery                       | `gpt-5-6-luna`        | `gpt-5-3-codex-spark`, `gemini-3-7-flash`   | `fact-finder`  | read-only                         |
| bounded reproduction                       | `gpt-5-6-luna`        | `opus-5`, `gemini-3-7-flash`                | `probe-runner` | build artifacts only              |
| focused validation                         | `gpt-5-3-codex-spark` | `gpt-5-6-luna`                              | `checker`      | build artifacts only              |
| noisy validation                           | `gpt-oss-120b`        | `gpt-5-6-luna`, `gemini-3-7-flash`          | `test-runner`  | build artifacts only              |
| implementation                             | `opus-5`              | `gpt-5-6-luna`                              | `implementer`  | workspace write                   |
| ambiguous diagnosis                        | `opus-5`              | `gpt-5-6-sol`, `gemini-3-7-flash`           | `debugger`     | read-only                         |
| plan or code review                        | `opus-5`              | `fable-5`, `gpt-5-6-sol`, `google-opus-4-6` | `reviewer`     | read-only                         |

For explicit three-provider deliberation, use Anthropic `opus-5`, Google
`google-opus-4-6` with `gemini-3-7-flash` fallback, and OpenAI `gpt-5-6-sol`.

<!-- END GENERATED ROUTES -->

## Effort policy

Choose effort for the task, not only for the model. Use the shared policy in the
always-loaded AI context:

- `low`: prose, metadata, summaries, and simple lookups.
- `medium`: mechanical edits and focused checks.
- `high`: discovery, reproduction, routine implementation, and test analysis.
- `xhigh`: cross-file implementation, broad validation, and difficult debugging.
- `max`: architecture, council work, hard failures, and high-stakes review.

The following user-supplied DeepSWE snapshot reports `pass@1` and average cost
for mini-swe-agent coding tasks. Each cell uses `pass@1 / USD`.

| Model            | Low         | Medium      | High        | Xhigh        | Max          |
| ---------------- | ----------- | ----------- | ----------- | ------------ | ------------ |
| GPT-5.6 Luna     | 2% / $0.01  | 11% / $0.04 | 44% / $0.16 | 57% / $0.31  | 67% / $0.61  |
| GPT-5.6 Sol      | 45% / $1.07 | 61% / $1.86 | 69% / $3.47 | 71% / $4.70  | 73% / $8.39  |
| Claude Opus 5    | 58% / $1.66 | 69% / $3.29 | 73% / $6.08 | 73% / $9.07  | 74% / $11.84 |
| Claude Fable 5   | 60% / $3.76 | 65% / $6.09 | 69% / $9.18 | 70% / $13.41 | 70% / $21.63 |
| Gemini 3.7 Flash | 54% / $1.83 | 65% / $2.03 | 65% / $2.18 | not shown    | not shown    |
| Claude Sonnet 5  | 31% / $2.19 | 40% / $4.08 | 48% / $7.43 | 50% / $11.89 | 54% / $26.40 |

Use the matrix as relative evidence. Luna gains sharply from high through max,
so use xhigh for meaningful default work and max for high-stakes work. Sol and
Opus reach strong results at high, so reserve xhigh or max for harder tasks.
Fable gains little beyond xhigh. Gemini Flash shows no measured gain from medium
to high. Sonnet is not a cost-efficient default in this snapshot.

Spark, Terra, and GPT-OSS do not appear in the snapshot. Keep their existing
latency-first or explicit-only roles until comparable measurements exist.

## Quota circuits

Use scripted preflight only when telemetry identifies every relevant pool.

- Google: Opus, Sonnet, and GPT-OSS share `claude-gpt`; Gemini Pro and Flash
  share `gemini`. Run [check-google-quota](../scripts/check-google-quota.sh)
  once before Google dispatch when `codexbar` is available.
- OpenAI: Spark has a separate `spark` pool; Luna, Terra, and Sol share
  `general`. Current CodexBar data does not distinguish both pools, so do not
  preflight. A `429` opens only the matching pool.
- Anthropic: no reliable quota query is available in the current environment.
  Let the first required dispatch act as probe; a quota failure opens the
  Anthropic circuit.
- `exhausted`: skip that pool without dispatch. Check another pool only when its
  model is a capable fallback.
- `available`: dispatch normally.
- `unknown`: allow one required attempt; a `429` or retry-limit failure opens
  that pool circuit for the current task.
- Reuse open circuits across later phases and challenge rounds. Do not probe or
  retry another model in the same pool. Skipped calls do not consume dispatch
  budget.
- Treat unknown agent types, unsupported models, and model-specific errors as
  route failures; one corrected route in the same pool is allowed. Treat auth or
  connection failure as provider-wide. A provider is unavailable only when all
  usable pools are unavailable or its provider-wide circuit is open.

## Worker patience

- Give frontier reasoning seats such as Opus, Fable, Sol, or comparable models
  time to research, reason, and synthesize on large tasks. Fast models such as
  Luna, Spark, Flash, or Haiku should receive narrower packets and may be
  redirected sooner.
- Treat a wait or poll timeout as observer cadence, not worker failure or a
  runtime deadline. Repeat polls without changing healthy seat state; use longer
  waits when the harness can still provide required user updates.
- Do not interrupt, demand immediate finalization from, or close a healthy
  reasoning seat for elapsed time alone. Nudge only for scope drift, confirmed
  looping, an explicit user deadline, or proximity to the actual harness runtime
  limit; interrupt only to stop runaway work.
- Count only new seat creation against dispatch limits. Mark a seat unavailable
  only after an explicit error, shutdown, route failure, or actual runtime
  limit. Never invent a shorter deadline from repeated poll expiry.

Choose for capability and total retry cost. Among equal routes, prefer the
independent quota pool with more headroom. Keep Spark first for obvious low-risk
lookups, mechanical edits, and focused checks even when the parent uses the
OpenAI general pool. Use Luna for average discovery, implementation, probes, and
broad tests. Keep Terra explicit-only. Prefer provider diversity only after
capability and quota-pool fit. Do not duplicate work only to balance
subscriptions.

Confirm agent type before dispatch and omit model overrides. Unknown type means
use its semantic role or one bounded native worker. If the host returns
`agent
type is currently not available`, stop retrying named roles. Use built-in
`default` with configured defaults when available, or mark that route
unavailable. Do not treat this error as quota evidence or launch another
harness. Use only write-capable routes for mutation; task prompts must still
make deliberation and review read-only.
