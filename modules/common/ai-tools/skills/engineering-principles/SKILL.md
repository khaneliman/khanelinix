---
name: engineering-principles
description: "Engineering principles for lean, verified agentic work. Apply when refactoring or sizing a diff, sequencing an addition or rewrite, debugging, stacking multi-step work or commits, verifying before declaring done, managing a filling context window, encoding a recurring correction, or choosing between hand edits and a tool."
---

# Engineering Principles

Twelve principles, one index. Match the situation to a row, then read that
reference in full before applying it. Each reference is short.

| Principle                                                                | Apply when                                                                               |
| ------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------- |
| [laziness-protocol](references/laziness-protocol.md)                     | Refactoring, sizing a diff, or tempted to add abstractions, layers, or signal threading. |
| [model-the-domain](references/model-the-domain.md)                       | Stateful logic, repeated shape assumptions, or branching spread across files.            |
| [boundary-discipline](references/boundary-discipline.md)                 | Validation, error handling, parsing, framework adapters, or external data.               |
| [type-system-discipline](references/type-system-discipline.md)           | Types or signatures in a statically typed language.                                      |
| [subtract-before-you-add](references/subtract-before-you-add.md)         | Sequencing an addition, refactor, or rewrite. Remove dead weight first.                  |
| [minimize-reader-load](references/minimize-reader-load.md)               | Code that requires too many layers or too much hidden state to understand.               |
| [fix-root-causes](references/fix-root-causes.md)                         | Debugging. Trace each symptom to its root cause; reproduce first.                        |
| [sequence-verifiable-units](references/sequence-verifiable-units.md)     | Multi-step work and commit or PR stacking. Verify each unit before the next.             |
| [prove-it-works](references/prove-it-works.md)                           | After completing a task, before declaring done. Check the real artifact.                 |
| [guard-the-context-window](references/guard-the-context-window.md)       | Context fills up: large outputs, long files, repeated reads, fan-out planning.           |
| [encode-lessons-in-structure](references/encode-lessons-in-structure.md) | The same instruction gets written a second time, or a correction recurs.                 |
| [build-the-lever](references/build-the-lever.md)                         | Non-trivial edits, migrations, analyses, or checks. Build the rerunnable tool.           |

Cite a principle only when it changed a concrete choice. A citation with no
decision behind it means the reference was skipped.

Workflow skills reference principles by short name, for example "the
prove-it-works principle". Resolve those names against this index.

Four principles adapt pstack guidance. Upstream terms are in [LICENSE](LICENSE).
