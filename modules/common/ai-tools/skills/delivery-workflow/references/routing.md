# Routing and Quality Gates

## Subscription map

Each model agent bills exactly one subscription. Agent name does not imply
owner: `google-*` agents run Claude models on Google quota, and `gpt-oss-120b`
runs on Google quota despite its prefix.

| Subscription         | Model agents                                                                                 |
| -------------------- | -------------------------------------------------------------------------------------------- |
| OpenAI (Codex)       | `gpt-5-3-codex-spark`, `gpt-5-6-luna`, `gpt-5-6-terra`, `gpt-5-6-sol`                        |
| Google (Antigravity) | `gemini-3-6-flash`, `gemini-3-1-pro`, `google-sonnet-4-6`, `google-opus-4-6`, `gpt-oss-120b` |
| Anthropic            | `opus-5`, `sonnet-5`                                                                         |

Resolve provider preference against this table, not against model family. Under
a Claude parent, `opus-5` and `sonnet-5` reuse parent subscription, while
`google-opus-4-6` and `google-sonnet-4-6` keep Claude-family capability on a
different subscription.

For Anthropic routing, use `opus-5`; never select `sonnet-5` automatically.
Optimize for total token use and completed-work efficiency: stronger first-pass
reasoning usually costs fewer retries, corrections, and repeated context. When
`opus-5` is unavailable or throttled, use a capable alternate subscription or
native semantic fallback and report the degraded route. Use `sonnet-5` only when
the user explicitly requests it.

Every subscription needs its own current gateway authentication. One expired
login removes that whole row from routing without affecting the others.

## Multi-provider council

Use these read-only seats when `multi-provider-council` is explicitly invoked:

| Provider subscription | Native agent type | Perspective                                                   |
| --------------------- | ----------------- | ------------------------------------------------------------- |
| Anthropic             | `opus-5`          | architecture coherence, intent, and long-term tradeoffs       |
| Google                | `gemini-3-1-pro`  | adversarial alternatives, edge cases, and hidden dependencies |
| OpenAI                | `gpt-5-6-sol`     | implementation feasibility, integration, and validation       |

Dispatch all available seats concurrently with the same bounded fact packet and
without peer answers. Council mode is best-effort: disclose every unavailable
seat, continue with two provider responses as degraded consensus, and refuse the
council label when fewer than two providers respond. Never silently replace a
failed provider with the parent subscription.

Run at most one challenge round against seats involved in material unresolved
issues. Council agents remain read-only and never execute the resulting plan;
after explicit approval, the normal delivery risk gates own implementation,
validation, and review.

## Agent routing

| Need                                       | Primary model agent   | Quality-first model-agent fallback    | Native semantic role | Write policy                      |
| ------------------------------------------ | --------------------- | ------------------------------------- | -------------------- | --------------------------------- |
| obvious lookup or mechanical one-file edit | `gpt-5-3-codex-spark` | `gemini-3-6-flash`, `gpt-5-6-luna`    | `mechanic`           | read-only unless edit is explicit |
| repository discovery                       | `gemini-3-6-flash`    | `gpt-5-6-luna`, `gpt-5-3-codex-spark` | `fact-finder`        | read-only                         |
| bounded reproduction                       | `gpt-5-6-luna`        | `gemini-3-6-flash`, `opus-5`          | `probe-runner`       | build artifacts only              |
| noisy validation                           | `gpt-oss-120b`        | `gemini-3-6-flash`, `gpt-5-6-luna`    | `test-runner`        | build artifacts only              |
| normal implementation                      | `opus-5`              | `gpt-5-6-luna`, `google-opus-4-6`     | `implementer`        | workspace write                   |
| ambiguous diagnosis                        | `gemini-3-1-pro`      | `gpt-5-6-terra`, `opus-5`             | `debugger`           | read-only                         |
| plan or code review                        | `opus-5`              | `gpt-5-6-sol`, `google-opus-4-6`      | `reviewer`           | read-only                         |

Gateway-capable harnesses install model-agent names and pin provider, model,
reasoning effort, and sandbox mode in each definition. Pass the name as native
agent type and omit per-invocation model override. Some harness schemas accept
only their built-in model aliases at dispatch even though custom agent
definitions accept gateway IDs.

Priority means capability fit, not rigid order. Among equally suitable choices:

1. Use `opus-5` for Anthropic routing; exclude `sonnet-5` unless user-requested.
2. Prefer provider different from parent.
3. Prefer provider with more quota headroom or less recent use.
4. Rotate repeated independent tasks instead of concentrating one subscription.
5. Never select clearly weaker model, duplicate work, or expand scope only for
   quota balancing.

Use fresh workers. Keep scopes bounded and pass summaries between runs. Honor
harness-native timeout and concurrency controls.

## Availability

Projection is harness-specific. Gateway-enabled Claude Code, Codex, and OpenCode
install model-agent names; without the gateway they install native semantic
roles. GitHub Copilot CLI always installs native semantic roles because it has
no gateway model-agent projection. Never infer one harness's roster from another
harness on the same host.

Check the harness's available agent-type list before dispatch and route to the
set that is actually present. Installed name is still not a proven live route:
the gateway daemon must be listening on its loopback port and the row's
subscription must hold current authentication, and the current process must use
the gateway endpoint.

Claude execution surfaces can expose an installed gateway roster without a live
gateway route:

- Gateway-routed CLI sessions can dispatch every installed model agent whose
  subscription row is healthy.
- `claude-direct` sessions use Anthropic's first-party endpoint. Gateway-only
  model agents are unavailable; only `opus-5` and `sonnet-5` resolve there.
- Claude Desktop also pins the first-party endpoint and ignores the CLI gateway
  environment. It has the same `opus-5` and `sonnet-5` limit even when the
  generated user roster contains every gateway model agent.

Distinguish the two failure modes:

- Unknown agent type: gateway projection is not installed. Use native semantic
  role in the table, or one native generic worker with same scope, permissions,
  and exit criteria.
- Dispatch resolves but gateway refuses connection, errors, or returns auth
  failure: daemon or subscription problem, not a routing problem. Report it
  instead of retrying the same route, and do not quietly absorb the work into
  the parent subscription when the user expected another one.

A runtime gateway bypass such as `claude-direct` counts as unavailable even when
installed model agents contain gateway aliases. `opus-5` and `sonnet-5` are the
only first-party routes, but `sonnet-5` remains user-request-only. Use parent
model only after suitable alternate subscription is unavailable. If a pinned
route is throttled, dispatch first capable fallback agent instead of retrying
same route.

## Risk gates

### Trivial

- One obvious low-risk surface; no architecture, schema, security, migration,
  concurrency, or broad behavior change.
- Use `gpt-5-3-codex-spark` for lookup or explicit one-file mechanical edit.
- Run focused validation. No mandatory Sol review.

### Normal

- Parent forms bounded plan.
- Implementation route handles one approved batch.
- Validation route runs noisy suites.
- Fresh review route checks current diff.
- Implementation route fixes clear findings. One fresh review rerun maximum.

### High-risk

- Includes architecture, security, destructive migration, public API/schema,
  concurrency, authentication, or broad multi-module behavior.
- Create user-approved `.planning/<id>` plan using planning-with-files.
- Fresh review route checks plan before implementation.
- Implementation route handles approved batches; validation route checks
  boundaries.
- Fresh review route checks final diff. One fresh rerun maximum after
  corrections.

## Review handling

- `critical` or `major`: fix or stop with explicit user decision.
- `minor`: fix when scoped and low-risk; otherwise report.
- `suggestion`: optional. Never expand scope only to satisfy it.
- Conflicting findings return to parent for judgment.
