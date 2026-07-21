# Routing and Quality Gates

## Model ladder

| Need                                   | Lane                         | Model profile | Write policy                                     |
| -------------------------------------- | ---------------------------- | ------------- | ------------------------------------------------ |
| obvious lookup or tiny mechanical edit | `spark`                      | Spark         | read-only; `--write` permits one mechanical file |
| repository discovery                   | `discover`                   | Luna/quick    | read-only                                        |
| bounded reproduction                   | `probe`                      | Luna/quick    | build artifacts only                             |
| noisy validation                       | `test`                       | Luna/quick    | build artifacts only                             |
| normal implementation                  | `implement`                  | Luna/quick    | workspace write                                  |
| plan or code review                    | `plan-review`, `code-review` | Sol/deep      | read-only                                        |
| ambiguous diagnosis                    | `debug`                      | Sol/deep      | read-only                                        |

All runs are strict-config, ephemeral, rooted at repository top, web-off, and
hard-limited to 600 seconds. Set `CODEX_LANE_TIMEOUT_SECONDS` to a smaller
positive integer for tighter scopes. Do not resume worker threads. Pass
summaries or commit boundaries between fresh runs.

## Risk gates

### Trivial

- One obvious low-risk surface; no architecture, schema, security, migration,
  concurrency, or broad behavior change.
- Use Spark for lookup or explicit one-file mechanical edit.
- Run focused validation. No mandatory Sol review.

### Normal

- Fable forms bounded plan in main thread.
- Luna implements and validates.
- Fresh Sol performs one code review against current diff.
- Luna fixes clear findings. One fresh review rerun maximum.

### High-risk

- Includes architecture, security, destructive migration, public API/schema,
  concurrency, authentication, or broad multi-module behavior.
- Create user-approved `.planning/<id>` plan using planning-with-files.
- Fresh Sol reviews plan before implementation.
- Luna implements approved batches and validates each boundary.
- Fresh Sol reviews final diff. One fresh rerun maximum after corrections.

## Sonnet 5 fallback

Invoke Claude `implementer` only when correction batch is non-mechanical or
multi-file, Codex quota is throttled/unavailable, or user requests Claude-native
implementation. Sonnet never owns first-pass normal implementation, planning,
review verdict, or publishing.

## Review handling

- `critical` or `major`: fix or stop with explicit user decision.
- `minor`: fix when scoped and low-risk; otherwise report.
- `suggestion`: optional. Never expand scope only to satisfy it.
- Conflicting findings return to Fable for judgment.
