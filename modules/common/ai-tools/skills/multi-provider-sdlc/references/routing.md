# Provider and Agent Routing

The [model-routing registry](model-routing.json) is the canonical source for
model, role, task, and quota-pool policy. A consumer owns runtime behavior until
its projection adopts that policy. After a policy edit, run
[`render-model-routes.py`](../scripts/render-model-routes.py) with `render`,
apply the generated section update, then run it with `check`.

## Subscription map

<!-- BEGIN GENERATED SUBSCRIPTIONS -->

| Subscription         | Model agents                                                                                 |
| -------------------- | -------------------------------------------------------------------------------------------- |
| OpenAI (Codex)       | `gpt-5-3-codex-spark`, `gpt-5-6-luna`, `gpt-5-6-terra`, `gpt-5-6-sol`, `gpt-6-astra`         |
| Google (Antigravity) | `gpt-oss-120b`, `google-opus-4-6`, `google-sonnet-4-6`, `gemini-3-8-flash`, `gemini-3-1-pro` |
| Anthropic            | `opus-5`, `fable-5-1`, `sonnet-5`                                                            |

<!-- END GENERATED SUBSCRIPTIONS -->

Use Luna and Gemini Flash for routine implementation and repository research.
Use Sol and Opus for difficult implementation. Use `fable-5-1` and `gpt-6-astra`
as equal preferred review routes. Keep Sol as the debugger route. Use `sonnet-5`
only when explicitly requested. Every subscription requires a live route and
current authentication.

## Preferred routes

<!-- BEGIN GENERATED ROUTES -->

| Need                                       | Preferred                          | Fallback                                    | Semantic role  | Write policy                      |
| ------------------------------------------ | ---------------------------------- | ------------------------------------------- | -------------- | --------------------------------- |
| obvious lookup or mechanical one-file edit | `gpt-5-3-codex-spark`              | `gpt-5-6-luna`, `gemini-3-8-flash`          | `mechanic`     | read-only unless edit is explicit |
| repository discovery                       | `gpt-5-6-luna`, `gemini-3-8-flash` | `gpt-5-3-codex-spark`                       | `fact-finder`  | read-only                         |
| bounded reproduction                       | `gpt-5-6-luna`                     | `opus-5`, `gpt-5-6-sol`, `gemini-3-8-flash` | `probe-runner` | build artifacts only              |
| focused validation                         | `gpt-5-3-codex-spark`              | `gpt-5-6-luna`                              | `checker`      | build artifacts only              |
| noisy validation                           | `gpt-oss-120b`                     | `gpt-5-6-luna`, `gemini-3-8-flash`          | `test-runner`  | build artifacts only              |
| implementation                             | `gpt-5-6-luna`, `gemini-3-8-flash` | `gpt-5-6-sol`, `opus-5`                     | `implementer`  | workspace write                   |
| difficult implementation                   | `gpt-5-6-sol`, `opus-5`            | `gpt-5-6-luna`, `gemini-3-8-flash`          | `implementer`  | workspace write                   |
| ambiguous diagnosis                        | `opus-5`                           | `gpt-5-6-sol`, `gemini-3-8-flash`           | `debugger`     | read-only                         |
| plan or code review                        | `fable-5-1`, `gpt-6-astra`         | `gpt-5-6-sol`, `opus-5`, `google-opus-4-6`  | `reviewer`     | read-only                         |

For explicit three-provider deliberation, use Anthropic `opus-5`, Google
`gemini-3-8-flash` with `google-opus-4-6` fallback (degraded family diversity),
and OpenAI `gpt-6-astra`.

<!-- END GENERATED ROUTES -->

## Effort policy

Use canonical `semantic_roles` profiles for ordinary workers. Keep the parent's
reasoning effort separate; task size alone does not override a worker profile.
Escalate for a documented capability gap, repeated evidenced failure, or risk
that the default cannot cover. Return the actual model, subscription, family,
effort, outcome, and fallback reason when observable. Mark unavailable fields
unknown; do not infer runtime dispatch from the configured route.

`model_family` identifies a shared model lineage, not the subscription paying
for it. Distinct families provide different perspectives, not proof of
statistical independence. Council primaries use distinct families; report a
fallback that duplicates another seat's family as degraded diversity.

The dated DeepSWE benchmark is retained as historical relative evidence in
[the benchmark snapshot](deepswe-benchmark-snapshot.md). It does not promote a
model or replace canonical semantic-role defaults and live task evidence.

## Quota circuits

Use scripted preflight only when telemetry identifies every relevant pool.

### Task-local capability state

Use [`route-capability.py`](../scripts/route-capability.py) when one task can
retry, cross providers, or reuse capability evidence in later phases. Skip the
state file for one known dispatch. The caller remains the only dispatcher and
state writer.

Choose an explicit path in the task's ignored planning or temporary area. Do not
use durable memory, commit the state, or store provider output in it. Initialize
once. Resolve `<skill-root>` to the directory containing this skill's
`SKILL.md`:

```console
python3 <skill-root>/scripts/route-capability.py --state <state-path> --task-id <task-id> init
```

Ask for a route before dispatch. Use a `need` value from the generated route
table:

```console
python3 <skill-root>/scripts/route-capability.py --state <state-path> --task-id <task-id> plan --need "plan or code review"
```

The result returns the current revision, eligible named candidates, blocked
circuits, and one semantic fallback. When `selectionRequired` is true, choose
one `preferredCandidates` entry with caller judgment. The planner leaves
`selected` null because each preferred model has equal policy rank. When
`selectionRequired` is false, claim `selected`. `probe: true` means that route
has unknown capability. Add `--gateway off` when the provider runs semantic
roles on native models. The default `on` resolves each role through its gateway
model.

When no candidate remains, the plan also resolves the semantic role. If
`claimConflicts` is true, wait for the active claim; `semanticFallback` is null
with reason `claim-conflict`. If every gateway model for the role is blocked,
`semanticFallback` is null and `semanticFallbackReason` names the blocking
circuit. Force a native worker or wait for that quota; do not dispatch the role
through the blocked circuit. Otherwise, use the semantic fallback when no named
candidate remains. Claim the selected or caller-chosen preferred model with the
returned need and revision:

```console
python3 <skill-root>/scripts/route-capability.py --state <state-path> --task-id <task-id> claim --expected-revision <revision> --need "<need>" --model <model>
```

Only a successful claim authorizes named-model dispatch. Never dispatch from a
plan alone. The claim records its task need, plan revision, selected model, and
current planned candidate set. A claim reserves each unknown named-agent,
provider, and pool scope, plus the selected route. Use a fresh revision for each
parallel claim; distinct known scopes can remain active together.

Use a non-candidate only when caller intent requires one. Add exactly one
categorical `--override-reason`: `explicit-model-request`,
`provider-diversity-seat`, or `caller-capability-judgment`. State records the
`non-candidate` marker and reason. An override does not bypass an open circuit
or active claim scope.

After every claimed named-model attempt, record one categorical outcome with its
`claimId`. Use `success`, `quota-exhausted`, `route-unavailable`,
`auth-failure`, `connection-failure`, `agent-type-unavailable`, or
`agent-type-available`. Record `agent-type-available` when the host accepted the
named agent type but the attempt returned no route, pool, or provider evidence.

```console
python3 <skill-root>/scripts/route-capability.py --state <state-path> --task-id <task-id> record --claim-id <claim-id> --outcome route-unavailable
```

If dispatch did not start, cancel its claim. If dispatch started but then
stopped without a provider result, record `dispatch-interrupted`; this opens the
claimed route. Do not cancel a claim for a seat that can still return. Keep
native semantic-fallback evidence in the caller-owned lifecycle; this state
tracks named model routes only.

```console
python3 <skill-root>/scripts/route-capability.py --state <state-path> --task-id <task-id> cancel --claim-id <claim-id>
```

Before a Google claim, ingest only categorical telemetry and use the returned
revision for the next plan or claim:

```console
<skill-root>/scripts/check-google-quota.sh | python3 <skill-root>/scripts/route-capability.py --state <state-path> --task-id <task-id> ingest-google --expected-revision <revision>
```

The state keeps active claim metadata and categorical route, pool, provider, and
named-agent circuits. Route, pool, and provider circuits stay open for the
current task. The named-agent surface is the one recoverable circuit. A later
outcome that carries named-agent availability evidence closes that surface and
resumes named routing. A compare-and-swap claim rejects concurrent or stale
probes. If the canonical registry or state schema changes, initialize a new
task-state path. Do not rewrite stale state because older claims lack current
binding evidence.

- Google: Opus, Sonnet, and GPT-OSS share `claude-gpt`; Gemini Pro and Flash
  share `gemini`. Run [check-google-quota](../scripts/check-google-quota.sh)
  once before Google dispatch when `codexbar` is available.
- OpenAI: Spark has a separate `spark` pool; Luna, Terra, Sol, and Astra share
  `general` conservatively. Current CodexBar data does not distinguish both
  pools, so do not preflight. A `429` opens only the matching pool.
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
- Treat unsupported models and model-specific errors as route failures; one
  corrected route in the same pool is allowed. Treat host rejection of named
  agent types as a named-agent surface failure. Treat auth or connection failure
  as provider-wide. A provider is unavailable only when all usable pools are
  unavailable or its provider-wide circuit is open.

## Worker patience

- Give frontier reasoning seats such as Astra, Opus, Fable, Sol, or comparable
  models time to research, reason, and synthesize on large tasks. Fast models
  such as Luna, Spark, Flash, or Haiku should receive narrower packets and may
  be redirected sooner.
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
OpenAI general pool. Use Luna for average discovery, implementation fallback,
probes, and broad tests. Keep Terra explicit-only. Prefer provider diversity
only after capability and quota-pool fit. Do not duplicate work only to balance
subscriptions.

Confirm agent type before dispatch and omit model overrides. Unknown type means
use its semantic role or one bounded native worker. If the host returns
`agent
type is currently not available`, stop retrying named roles. Use built-in
`default` with configured defaults when available, or mark that route
unavailable. When capability state exists, record `agent-type-unavailable` and
use its semantic fallback. Record `agent-type-available`, or any other
named-model outcome, once a later attempt shows that the host accepts named
agent types again. Do not treat this error as quota evidence or launch another
harness. Use only write-capable routes for mutation; task prompts must still
make deliberation and review read-only.
