# Provider and Agent Routing

## Subscription map

| Subscription         | Model agents                                                                                 |
| -------------------- | -------------------------------------------------------------------------------------------- |
| OpenAI (Codex)       | `gpt-5-3-codex-spark`, `gpt-5-6-luna`, `gpt-5-6-terra`, `gpt-5-6-sol`                        |
| Google (Antigravity) | `gpt-oss-120b`, `google-opus-4-6`, `google-sonnet-4-6`, `gemini-3-6-flash`, `gemini-3-1-pro` |
| Anthropic            | `opus-5`, `sonnet-5`                                                                         |

Prefer `opus-5` for Anthropic work; use `sonnet-5` only when explicitly
requested. Keep Gemini fallback-only. Every subscription requires a live route
and current authentication.

## Preferred routes

| Need                                       | Primary               | Fallback                                  | Semantic role  | Write policy                      |
| ------------------------------------------ | --------------------- | ----------------------------------------- | -------------- | --------------------------------- |
| obvious lookup or mechanical one-file edit | `gpt-5-3-codex-spark` | `gpt-5-6-luna`, `gemini-3-6-flash`        | `mechanic`     | read-only unless edit is explicit |
| repository discovery                       | `gpt-5-6-luna`        | `gpt-5-3-codex-spark`, `gemini-3-6-flash` | `fact-finder`  | read-only                         |
| bounded reproduction                       | `gpt-5-6-luna`        | `opus-5`, `gemini-3-6-flash`              | `probe-runner` | build artifacts only              |
| noisy validation                           | `gpt-oss-120b`        | `gpt-5-6-luna`, `gemini-3-6-flash`        | `test-runner`  | build artifacts only              |
| implementation                             | `opus-5`              | `gpt-5-6-luna`                            | `implementer`  | workspace write                   |
| ambiguous diagnosis                        | `opus-5`              | `gpt-5-6-sol`, `gemini-3-1-pro`           | `debugger`     | read-only                         |
| plan or code review                        | `opus-5`              | `gpt-5-6-sol`, `google-opus-4-6`          | `reviewer`     | read-only                         |

For explicit three-provider deliberation, use Anthropic `opus-5`, Google
`google-opus-4-6` with `gemini-3-1-pro` fallback, and OpenAI `gpt-5-6-sol`.

Choose for capability and total retry cost. Among equal routes, prefer a
provider different from parent, then quota headroom. Do not duplicate work only
to balance subscriptions.

Confirm agent type before dispatch and omit model overrides. Unknown type means
use its semantic role or one bounded native worker. Connection, auth, or
throttle failure means try one capable alternate provider and report
degradation. Never launch another harness. Use only write-capable routes for
mutation; task prompts must still make deliberation and review read-only.

## Risk

- Trivial: focused validation; fresh review optional.
- Normal: bounded plan, implementation, validation, fresh diff review, then one
  correction and re-review maximum.
- High: architecture, security, destructive migration, public API or schema,
  concurrency, authentication, or broad behavior. Add plan review, boundary
  validation, and final review. Persist autonomously only when recovery helps.
