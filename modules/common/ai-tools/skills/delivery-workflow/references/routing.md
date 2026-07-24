# Routing and Quality Gates

## Agent routing

| Need                                       | Primary model agent   | Quality-first model-agent fallback          | Native semantic role | Write policy                      |
| ------------------------------------------ | --------------------- | ------------------------------------------- | -------------------- | --------------------------------- |
| obvious lookup or mechanical one-file edit | `gpt-5-3-codex-spark` | `gemini-3-6-flash`, `gpt-5-6-luna`          | `mechanic`           | read-only unless edit is explicit |
| repository discovery                       | `gemini-3-6-flash`    | `gpt-5-6-luna`, `gpt-5-3-codex-spark`       | `fact-finder`        | read-only                         |
| bounded reproduction                       | `gpt-5-6-luna`        | `gemini-3-6-flash`, `sonnet-5`              | `probe-runner`       | build artifacts only              |
| noisy validation                           | `gpt-oss-120b`        | `gemini-3-6-flash`, `gpt-5-6-luna`          | `test-runner`        | build artifacts only              |
| normal implementation                      | `sonnet-5`            | `gpt-5-6-luna`, `google-sonnet-4-6`         | `implementer`        | workspace write                   |
| ambiguous diagnosis                        | `gemini-3-1-pro`      | `gpt-5-6-terra`, `opus-4-8`                 | `debugger`           | read-only                         |
| plan or code review                        | `opus-4-8`            | `gpt-5-6-sol`, `google-opus-4-6`, `fable-5` | `reviewer`           | read-only                         |

Gateway-capable harnesses install model-agent names and pin provider/model in
each definition. Pass the name as native agent type and omit per-invocation
model override. Some harness schemas accept only their built-in model aliases at
dispatch even though custom agent definitions accept gateway IDs.

Without gateway or model-agent support, use native semantic role in table or one
native generic worker. A runtime gateway bypass such as `claude-direct` counts
as unavailable even when installed model agents contain gateway aliases. Use
parent model only after suitable alternate subscription is unavailable. If a
pinned route is throttled, dispatch first capable fallback agent instead of
retrying same route.

Priority means capability fit, not rigid order. Among equally suitable choices:

1. Prefer provider different from parent.
2. Prefer provider with more quota headroom or less recent use.
3. Rotate repeated independent tasks instead of concentrating one subscription.
4. Never select clearly weaker model, duplicate work, or expand scope only for
   quota balancing.

Use fresh workers. Keep scopes bounded and pass summaries between runs. Honor
harness-native timeout and concurrency controls.

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
