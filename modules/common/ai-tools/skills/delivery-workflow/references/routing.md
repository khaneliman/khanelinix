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

Every subscription needs its own current gateway authentication. One expired
login removes that whole row from routing without affecting the others.

## Agent routing

| Need                                       | Primary model agent   | Quality-first model-agent fallback    | Native semantic role | Write policy                      |
| ------------------------------------------ | --------------------- | ------------------------------------- | -------------------- | --------------------------------- |
| obvious lookup or mechanical one-file edit | `gpt-5-3-codex-spark` | `gemini-3-6-flash`, `gpt-5-6-luna`    | `mechanic`           | read-only unless edit is explicit |
| repository discovery                       | `gemini-3-6-flash`    | `gpt-5-6-luna`, `gpt-5-3-codex-spark` | `fact-finder`        | read-only                         |
| bounded reproduction                       | `gpt-5-6-luna`        | `gemini-3-6-flash`, `sonnet-5`        | `probe-runner`       | build artifacts only              |
| noisy validation                           | `gpt-oss-120b`        | `gemini-3-6-flash`, `gpt-5-6-luna`    | `test-runner`        | build artifacts only              |
| normal implementation                      | `sonnet-5`            | `gpt-5-6-luna`, `google-sonnet-4-6`   | `implementer`        | workspace write                   |
| ambiguous diagnosis                        | `gemini-3-1-pro`      | `gpt-5-6-terra`, `opus-5`             | `debugger`           | read-only                         |
| plan or code review                        | `opus-5`              | `gpt-5-6-sol`, `google-opus-4-6`      | `reviewer`           | read-only                         |

Gateway-capable harnesses install model-agent names and pin provider, model,
reasoning effort, and sandbox mode in each definition. Pass the name as native
agent type and omit per-invocation model override. Some harness schemas accept
only their built-in model aliases at dispatch even though custom agent
definitions accept gateway IDs.

Priority means capability fit, not rigid order. Among equally suitable choices:

1. Prefer provider different from parent.
2. Prefer provider with more quota headroom or less recent use.
3. Rotate repeated independent tasks instead of concentrating one subscription.
4. Never select clearly weaker model, duplicate work, or expand scope only for
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
installed model agents contain gateway aliases. Treat `opus-5` and `sonnet-5` as
the only first-party exceptions. Use parent model only after suitable alternate
subscription is unavailable. If a pinned route is throttled, dispatch first
capable fallback agent instead of retrying same route.

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
