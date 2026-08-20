# Delegation

Delegate bounded work. Keep planning, integration, and final judgment in the
parent thread.

## Worker Packet

Give every worker exactly these fields. Omit conversational context.

- **Task**: one bounded outcome.
- **Paths**: files or directories in scope.
- **Constraints**: what must not change, plus repository rules that apply.
- **Write policy**: read-only, or the exact paths the worker may write. Missing
  write permission means read-only.
- **Skill or tool lane**: the allowed skills and commands. A matching specialist
  skill may run inside the lane, such as `writing-nix` for Nix edits or
  `rust-toolkit` for Rust edits.
- **Exit criteria**: the evidence that ends the task.

## Worker Selection

When the current harness exposes these classes and semantic roles:

- Obvious mechanical edit or one focused known check: Spark-class `mechanic` or
  `checker`.
- Average repository work, implementation, reproduction, or broad and noisy
  validation: Luna-class `explorer`, `fact-finder`, `worker`, `implementer`,
  `probe-runner`, or `test-runner`.
- Simple factual lookup: use the Luna-class semantic `fact-finder` when it is
  available.
- Ambiguity, architecture, or review: escalate to Sol.
- Terra stays explicit-only.

If a named class is unavailable, use the smallest capable current-harness worker
with the same write policy and lane.

## Write Safety

- Keep one write owner per batch. Parallel writers to the same paths corrupt
  each other.
- Read-only probes may run in parallel with a single writer.
- Preserve unrelated work in the tree.

## Boundaries

- Workers never own architecture, final judgment, or external delivery.
- Workers never commit, push, merge, publish, deploy, or open a pull request.
- Review the worker diff or artifact yourself. Write your own summary. Do not
  pass through a worker self-report.
- Use `multi-provider-sdlc` only when the user explicitly requests provider or
  model diversity. It returns one phase packet; this skill keeps phase order and
  completion.

## When Workers Are Unavailable

Do the work directly. Never claim delegated evidence that did not run. State
that delegation was unavailable and report the checks you ran yourself.
