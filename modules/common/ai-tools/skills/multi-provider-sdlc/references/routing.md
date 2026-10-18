# Provider and Agent Routing

The [model-routing registry](model-routing.json) is the canonical source for
model, role, task, and quota-pool policy. A consumer owns runtime behavior until
its projection adopts that policy. After a policy edit, run
[`render-model-routes.py`](../scripts/render-model-routes.py) with `render`,
apply the generated section update, then run it with `check`.

This is a maintainer reference, not delegation input. Runtime selection is owned
by `route-model.py` and its JSON contract.

## Subscription map

<!-- BEGIN GENERATED SUBSCRIPTIONS -->

| Subscription         | Model agents                                                                                                   |
| -------------------- | -------------------------------------------------------------------------------------------------------------- |
| OpenAI (Codex)       | `gpt-6-luna`, `gpt-5-6-terra`, `gpt-6-1-sol`, `gpt-6-astra`                                                    |
| Anthropic            | `opus-5-5`, `fable-5-1`, `sonnet-5-5`, `haiku-5-5`                                                             |
| Google (Antigravity) | `gpt-oss-120b`, `google-opus-5-5`, `google-sonnet-5-5`, `gemini-4-argon`, `gemini-3-8-flash`, `gemini-3-1-pro` |

<!-- END GENERATED SUBSCRIPTIONS -->

Favor the existing Codex and Claude subscriptions for ordinary coding work.
Google AI Pro is secondary: use Gemini for supported multimodal inputs, bounded
overflow, or a useful independent perspective. Compare accepted work, rework,
elapsed time, and actual subscription usage, not API prices alone. Within
Google, Gemini 4 Argon is the stronger agentic model (Terminal-Bench 4.0 57% vs
20% for 3.8 Flash) and takes implementation, reproduction, diagnosis, review,
multimodal, and deliberation seats. Gemini 3.8 Flash matches Argon on
long-context reading (AA-LCR) at about 40% less cost per task, so it keeps the
lookup, discovery, and validation fallbacks.

Use Luna for bounded discovery, reproduction, mechanical edits, and checks; Sol
for routine implementation and review; Opus or Astra for serious review and
sustained judgment. Keep Fable as an evidence-driven escalation, not the first
reviewer for every change. For architecture or high-risk review, use
`plan or code review`; for an ordinary diff, use `routine code review`.

Haiku 5.5 is the alternative to Luna for the same narrow packets. It runs on the
Anthropic subscription, so it stays available when a `429` opens the shared
OpenAI pool that Luna draws from. Luna remains preferred; Haiku is the first
fallback wherever Luna is preferred and directly follows Luna wherever Luna is
itself a fallback.

Sonnet 5.5 is a provisional candidate, not a blanket replacement for Opus. Use
`bounded Sonnet trial` for an intentional implementation or UI experiment; keep
review trials read-only even when the selected model can write. Compare against
the current default on representative local tasks before promotion. Sol 6.1 also
has limited independent evidence at this snapshot date. See the
[September 2026 evidence and adoption criteria](routing-evidence-2026-09.md).
The
[October 2026 Artificial Analysis snapshot](aa-intelligence-index-2026-10.md)
places each model by general capability and cost per task: Luna is the cheapest,
Sol is the best value above 50, and Opus at xhigh is the strongest at
Astra-level cost. Use it for tiering, not to override review-specific evidence.

The named task preferences below apply to gateway selection. Native dispatch
uses provider-specific semantic-role profiles, not the named-model ranking: for
example, both review needs use the native `reviewer` profile. Do not claim a
trial or multimodal route ran unless the actual model and harness support it.
Every subscription requires a live route and current authentication.

## Preferred routes

<!-- BEGIN GENERATED ROUTES -->

| Need                                       | Preferred                 | Fallback                                                        | Semantic role  | Write policy                      |
| ------------------------------------------ | ------------------------- | --------------------------------------------------------------- | -------------- | --------------------------------- |
| obvious lookup or mechanical one-file edit | `gpt-6-luna`              | `haiku-5-5`, `gemini-3-8-flash`                                 | `mechanic`     | read-only unless edit is explicit |
| repository discovery                       | `gpt-6-luna`              | `haiku-5-5`, `gpt-6-1-sol`, `gemini-3-8-flash`                  | `fact-finder`  | read-only                         |
| bounded reproduction                       | `gpt-6-luna`              | `haiku-5-5`, `gpt-6-1-sol`, `opus-5-5`, `gemini-4-argon`        | `probe-runner` | build artifacts only              |
| focused validation                         | `gpt-6-luna`              | `haiku-5-5`, `gemini-3-8-flash`                                 | `checker`      | build artifacts only              |
| noisy validation                           | `gpt-6-luna`              | `haiku-5-5`, `gemini-3-8-flash`, `gpt-oss-120b`                 | `test-runner`  | build artifacts only              |
| implementation                             | `gpt-6-1-sol`             | `opus-5-5`, `gpt-6-luna`, `haiku-5-5`, `gemini-4-argon`         | `implementer`  | workspace write                   |
| difficult implementation                   | `gpt-6-1-sol`, `opus-5-5` | `gpt-6-luna`, `haiku-5-5`, `gemini-4-argon`                     | `implementer`  | workspace write                   |
| ambiguous diagnosis                        | `gpt-6-1-sol`             | `opus-5-5`, `gemini-4-argon`                                    | `debugger`     | read-only                         |
| plan or code review                        | `opus-5-5`, `gpt-6-astra` | `gpt-6-1-sol`, `gemini-4-argon`, `fable-5-1`, `google-opus-5-5` | `reviewer`     | read-only                         |
| routine code review                        | `gpt-6-1-sol`             | `opus-5-5`, `gemini-4-argon`                                    | `reviewer`     | read-only                         |
| bounded Sonnet trial                       | `sonnet-5-5`              | `gpt-6-1-sol`, `opus-5-5`                                       | `implementer`  | workspace write                   |
| multimodal analysis                        | `gemini-4-argon`          | `gpt-6-1-sol`, `opus-5-5`                                       | `fact-finder`  | read-only                         |

For explicit three-provider deliberation, use Anthropic `opus-5-5`, Google
`gemini-4-argon` with `google-opus-5-5` fallback (degraded family diversity),
and OpenAI `gpt-6-astra`.

<!-- END GENERATED ROUTES -->

## Effort policy

Use canonical `semantic_roles` profiles for ordinary workers. Keep the parent's
reasoning effort separate; task size alone does not override a worker profile.
Escalate for a documented capability gap, repeated evidenced failure, or risk
that the default cannot cover. Return the actual model, subscription, family,
effort, outcome, and fallback reason when observable. Mark unavailable fields
unknown; do not infer runtime dispatch from the configured route.

Do not default to max effort. More reasoning can add scope drift, false
positives, and timeouts rather than quality. Keep the current role effort unless
task evidence justifies high or xhigh; use max only for a concrete unresolved
problem. Keep Standard speed for background work unless latency justifies the
extra subscription usage. Never broaden a write policy to gain access to a
stronger model: Astra and Fable gateway workers remain read-only.

`model_family` identifies a shared model lineage, not the subscription paying
for it. Distinct families provide different perspectives, not proof of
statistical independence. Council primaries use distinct families; report a
fallback that duplicates another seat's family as degraded diversity.

The dated DeepSWE benchmark is retained as historical relative evidence in
[the benchmark snapshot](deepswe-benchmark-snapshot.md). It does not promote a
model or replace canonical semantic-role defaults and live task evidence.

## Quota circuits

Use scripted preflight only when telemetry identifies every relevant pool.

### Quota pace and delegation

Use [`quota-advice.py`](../scripts/quota-advice.py) before substantial batches
when usage data could help choose how much work to delegate. Match the queried
subscription and account to the route actually running the workers; native CLI
usage does not establish the budget of an unrelated gateway account.

```console
python3 <skill-root>/scripts/quota-advice.py --provider codex
python3 <skill-root>/scripts/quota-advice.py --provider codex --user-requested
```

Use `claude` or `antigravity` for their corresponding CodexBar sources.
`--from-stdin` accepts an existing CodexBar usage JSON response without another
fetch. The helper reads reported windows, ages their exhaustion estimates, and
returns a forecast, window evidence, and an advisory `next_action`:

- `use-normal-delegation`: reported windows are on track through reset. Favor
  useful independent work, not additional work merely to consume quota.
- `conserve-optional-workers`: a window may run out before reset. Favor smaller
  batches and leave capacity for finishing, independent review, and corrections.
- `use-normal-judgment`: usage data is missing, stale, incomplete, or cannot be
  attributed to one provider account. Continue without a quota-based decision.
- `follow-user-request`: explicit requests for more workers or a swarm override
  forecast-based conservation. The bounded fetch still returns fresh usage,
  reset timing, and forecasts so the caller can allocate work across providers.
  When present, `reset_credits_available` reports Codex reset-credit inventory;
  missing inventory is unknown, not zero. The helper never redeems credits.

CodexBar is optional. It publishes macOS and Linux CLI builds; a missing CLI on
Windows or any other platform returns unavailable advice, not a blocked route.
The helper uses standard Python without shell tools or OS-specific commands. Run
it with Python 3; on Windows, `py -3` or `python` may be the installed command
instead of `python3`. If its prerequisites are unavailable, skip quota advice
and continue the task. It defaults to a five-minute freshness window, adjustable
with `--max-age-seconds`, and a bounded fetch without retries. Do not add quota
queries to trivial work.

Advice never sets an exact worker count, dispatches workers, or changes quota
circuits. More workers can change the pace; rerun the helper before expanding a
substantial batch. The user may deliberately spend quota before a reset or use
an available usage reset. Honor that direction without repeated confirmation.
Actual provider exhaustion and host limits still apply; use a capable available
route when the requested route cannot run. Do not bypass recorded quota failures
or assume a forecast reset time proves capacity returned.

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
has unknown capability. The default `--gateway off` keeps semantic roles native;
use `--gateway on` only for an explicit gateway invocation. Add
`--native-dispatch` to plans and claims for native semantic or T3 workers so a
local named-agent failure does not gate app-owned dispatch. Provider, pool,
route, and active-claim circuits still apply.

When no candidate remains, the plan also resolves the semantic role. If
`claimConflicts` is true, wait for the active claim; `semanticFallback` is null
with reason `claim-conflict`. If every gateway model for the role is blocked,
`semanticFallback` is null and `semanticFallbackReason` names the blocking
circuit. Force a native worker or wait for that quota; do not dispatch the role
through the blocked circuit. Otherwise, use the semantic fallback when no named
candidate remains. In native mode, `native-profile-requires-resolution` means
call `route-model.py` with the actual provider and existing state to check that
profile's quota; the generic planner cannot authorize an unchecked native
fallback. Claim the selected or caller-chosen preferred model with the returned
need and revision:

```console
python3 <skill-root>/scripts/route-capability.py --state <state-path> --task-id <task-id> claim --expected-revision <revision> --need "<need>" --model <model>
```

Only a successful claim authorizes named-model dispatch. Never dispatch from a
plan alone. The claim records its task need, plan revision, selected model, and
current planned candidate set. A claim reserves each unknown named-agent,
provider, pool, and route scope for one probe. Once those capabilities are
known, many workers can use the same model concurrently. Use a fresh revision
for each claim; the parent serializes state claims, not worker execution.

Use a non-candidate only when caller intent requires one. Add exactly one
categorical `--override-reason`: `explicit-model-request`,
`provider-diversity-seat`, or `caller-capability-judgment`. State records the
`non-candidate` marker and reason. An override does not bypass an open circuit
or active claim scope.

After every claimed named-model attempt, record one categorical outcome with its
`claimId`. Use `success`, `quota-exhausted`, `route-unavailable`,
`auth-failure`, `connection-failure`, `agent-type-unavailable`, or
`agent-type-available`. Named-agent outcomes apply only to local named workers,
not claims created with `--native-dispatch`. Record `agent-type-available` when
the host accepted the named agent type but the attempt returned no route, pool,
or provider evidence.

```console
python3 <skill-root>/scripts/route-capability.py --state <state-path> --task-id <task-id> record --claim-id <claim-id> --outcome route-unavailable
```

If dispatch did not start, cancel its claim. If dispatch started but then
stopped without a provider result, recover or cancel the app-owned task before
reassigning its work, then record `dispatch-interrupted`. This releases the
claim without changing route, provider or quota evidence: a caller interruption
does not establish a provider failure. Do not cancel a claim for a seat that can
still return. Keep native semantic-fallback evidence in the caller-owned
lifecycle; this state tracks named model routes only.

```console
python3 <skill-root>/scripts/route-capability.py --state <state-path> --task-id <task-id> cancel --claim-id <claim-id>
```

If a caller-side rejection was mistakenly recorded as `dispatch-interrupted`,
retain that failure receipt and verify both that no child started and that the
caller fault is resolved. Only then rearm that route for one required probe:

```console
python3 <skill-root>/scripts/route-capability.py --state <state-path> --task-id <task-id> reset-route --expected-revision <revision> --model <model> --confirmed-caller-fault
```

This changes only the named route from `open` to `unknown`, rejects active
claims on it, and preserves provider, quota-pool, and other route failures. It
is not recovery for interrupted inference, provider errors, or quota exhaustion.
Continue through the resolver and a fresh claim; do not dispatch directly.

Before a Google claim, ingest only categorical telemetry and use the returned
revision for the next plan or claim:

```console
<skill-root>/scripts/check-google-quota.sh | python3 <skill-root>/scripts/route-capability.py --state <state-path> --task-id <task-id> ingest-google --expected-revision <revision>
```

The state keeps active claim metadata and categorical route, pool, provider, and
named-agent circuits. Route and provider circuits stay open for the current
task. Pool circuits also stay open unless a quota reset is confirmed through the
recovery procedure below. A later outcome that carries named-agent availability
evidence closes that surface and resumes named routing. A compare-and-swap claim
rejects concurrent or stale probes. If the canonical registry or state schema
changes, initialize a new task-state path. Do not rewrite stale state because
older claims lack current binding evidence. Schema 4 permits claims without
exclusive scopes once a route is known. Earlier task state is rejected rather
than silently converted. Finish its claims with the matching installed script
and keep its failures for that task; initialize schema-4 state for new tasks,
not to bypass old circuits.

### Confirmed quota resets

After fresh telemetry for the same account shows replenished capacity, or the
user explicitly reports completing that account's reset, rearm only the affected
pool. An available reset credit, a forecast timestamp, ordinary rate throttling,
or a request to burn usage is not confirmation. Refresh quota first when
telemetry is available; otherwise let one required task probe the reset.

Wait for active claims in that pool to finish, read `status` for the current
revision, then run:

```console
python3 <skill-root>/scripts/route-capability.py --state <state-path> --task-id <task-id> reset-quota --expected-revision <revision> --subscription <subscription> --pool <pool> --confirmed-reset
```

Use canonical subscription and pool names from routing state, not CodexBar
provider names. The command trusts the caller's reset confirmation, as `record`
trusts reported worker outcomes. It changes only an exhausted pool to `unknown`
so one required task probes capacity. It preserves provider, route, named-agent,
and other pool failures, rejects active claims or a stale revision, and is a
no-op when the pool is not exhausted. Record the next attempt normally. A new
quota failure blocks the pool again; another recovery requires a newly confirmed
reset. Keep the existing state file rather than erasing failures.

### T3 native dispatch

`route-model.py` accepts the live `orchestrator_capabilities` result in the
optional `capabilities` field. It matches canonical upstream models to the
appropriate native driver and advertised model IDs, then returns `target` for
`delegate_task`. Unsupported models, unavailable child-task providers, and
unsupported effort values are not dispatched. Multiple matching account
instances require narrowing the catalog. Keep quota state scoped to the accounts
represented in that catalog; model identity alone does not establish billing.

Subscription constraints and task-state claims work without a gateway. A native
local CLI remains on its configured semantic profile; a different subscription
requires T3 capabilities or an explicitly configured gateway invocation. T3
targets do not use local model-named agent registrations, and native success
does not reopen a failed local named-agent surface. Claim revisions, provider
quota failures, and categorical outcomes retain the same protections.

- Google: Opus, Sonnet, and GPT-OSS share `claude-gpt`; Gemini Argon, Flash, and
  Pro share `gemini`. Run [check-google-quota](../scripts/check-google-quota.sh)
  once before Google dispatch when `codexbar` is available.
- OpenAI: Luna, Terra, Sol, and Astra share `general` conservatively. Do not
  preflight without reliable pool telemetry. A `429` opens this shared pool;
  switch providers rather than retry another OpenAI model.
- Anthropic: no reliable quota query is available in the current environment.
  Let the first required dispatch act as probe; a quota failure opens the
  Anthropic circuit.
- `exhausted`: skip that pool without dispatch. Check another pool only when its
  model is a capable fallback.
- `available`: dispatch normally.
- `unknown`: allow one required attempt; a `429` or retry-limit failure opens
  that pool circuit for the current task.
- Reuse open circuits across later phases and challenge rounds. Do not probe or
  retry another model in the same pool unless a newly confirmed quota reset
  rearms it through `reset-quota`. Skipped calls do not consume dispatch budget.
- Treat unsupported models and model-specific errors as route failures; one
  corrected route in the same pool is allowed. Treat host rejection of named
  agent types as a named-agent surface failure. Treat auth or connection failure
  as provider-wide. A provider is unavailable only when all usable pools are
  unavailable or its provider-wide circuit is open.

## Worker patience

- Give frontier reasoning seats such as Astra, Opus, Fable, Sol, or comparable
  models time to research, reason, and synthesize on large tasks. Fast models
  such as Luna, Flash, or Haiku should receive narrower packets and may be
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

Choose for capability and total retry cost. Among capable routes, favor the
primary subscriptions and then independent quota headroom. A quota fallback must
still fit the task: Luna or Haiku is suitable for a narrow mechanical packet,
not a silent downgrade for an unresolved cross-cutting design. Rescope or let
the parent continue if no capable route remains. Keep Terra explicit-only and
GPT-OSS as a legacy validation fallback, not a preferred use of Google quota.
Prefer a reviewer from another model family when available and useful; do not
duplicate routine work merely to balance subscriptions or manufacture diversity.

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
