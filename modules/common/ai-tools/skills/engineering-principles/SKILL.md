---
name: engineering-principles
description: "Methods inside a caller-owned lifecycle: diff sizing, work sequencing, refactoring, debugging, commit stacks, verification, context pressure, recurring corrections, and tool choice."
---

# Engineering Principles

Sixteen principles, one index. Match the situation to a row, then read that
reference in full before applying it. Each reference is short.

| Principle                                                                                          | Apply when                                                                               |
| -------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| [laziness-protocol](references/laziness-protocol.md)                                               | Refactoring, sizing a diff, or tempted to add abstractions, layers, or signal threading. |
| [model-the-domain](references/model-the-domain.md)                                                 | Stateful logic, repeated shape assumptions, or branching spread across files.            |
| [separate-before-serializing-shared-state](references/separate-before-serializing-shared-state.md) | Multiple writers contend for one slot, cache, or merged config value.                    |
| [boundary-discipline](references/boundary-discipline.md)                                           | Validation, error handling, parsing, framework adapters, or external data.               |
| [make-operations-idempotent](references/make-operations-idempotent.md)                             | Activation, migration, install, retry, or hook paths that can run twice.                 |
| [type-system-discipline](references/type-system-discipline.md)                                     | Types or signatures in a statically typed language.                                      |
| [subtract-before-you-add](references/subtract-before-you-add.md)                                   | Sequencing an addition, refactor, or rewrite. Remove dead weight first.                  |
| [migrate-callers-then-delete-legacy-apis](references/migrate-callers-then-delete-legacy-apis.md)   | Replacing an API or call path. Migrate callers and delete the old path together.         |
| [minimize-reader-load](references/minimize-reader-load.md)                                         | Code that requires too many layers or too much hidden state to understand.               |
| [fix-root-causes](references/fix-root-causes.md)                                                   | Debugging. Trace each symptom to its root cause; reproduce first.                        |
| [sequence-verifiable-units](references/sequence-verifiable-units.md)                               | Multi-step work and commit or PR stacking. Verify each unit before the next.             |
| [verified-slice](references/verified-slice.md)                                                     | Implementing one reviewable, reversible unit with evidence and commit authority.        |
| [prove-it-works](references/prove-it-works.md)                                                     | After completing a task, before declaring done. Check the real artifact.                 |
| [guard-the-context-window](references/guard-the-context-window.md)                                 | Context fills up: large outputs, long files, repeated reads, fan-out planning.           |
| [encode-lessons-in-structure](references/encode-lessons-in-structure.md)                           | The same instruction gets written a second time, or a correction recurs.                 |
| [build-the-lever](references/build-the-lever.md)                                                   | Non-trivial edits, migrations, analyses, or checks. Build the rerunnable tool.           |

Cite a principle only when it changed a concrete choice. A citation with no
decision behind it means the reference was skipped.

Workflow skills reference principles by short name, for example "the
prove-it-works principle". Resolve those names against this index.

Seven principles adapt pstack guidance. Upstream terms are in
[LICENSE](LICENSE).
