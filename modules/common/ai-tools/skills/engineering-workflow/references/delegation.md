# Delegation

Delegate bounded work. Keep planning, integration, and final judgment in the
parent thread.

## Worker Packet

Give every worker exactly these fields. Omit conversational context.

- **Task**: one bounded outcome.
- **Paths**: files or directories in scope.
- **Verified context**: only decisions and facts required for this task.
- **Constraints**: what must not change, plus repository rules that apply.
- **Write policy**: read-only, or the exact paths the worker may write. Missing
  write permission means read-only.
- **Skill or tool lane**: the allowed skills and commands. A matching specialist
  skill may run inside the lane, such as `writing-nix` for Nix edits or
  `rust-toolkit` for Rust edits.
- **Required evidence**: exact findings, checks, artifacts, or changed paths the
  parent must inspect.
- **Exit criteria**: the evidence that ends the task.

## Worker Selection

Select semantic roles before concrete models:

- Obvious mechanical edit or one focused known check: `mechanic` or `checker`.
- Repository discovery or factual lookup: `explorer` or `fact-finder`.
- Implementation: `implementer` or `worker`.
- Reproduction or broad validation: `probe-runner` or `test-runner`.
- Ambiguous diagnosis: `debugger`.
- Plan or code review: read-only `reviewer`. Build review packets per the
  `premise-review` method in `engineering-principles`: at least one reviewer is
  blind to the chosen solution, and reviewers that share one unchallenged
  premise count as one.

Do not select a named-model agent from diff size, latency, or write access.

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
- Use `multi-provider-sdlc` when provider diversity, named-model intent, quota
  fallback, or route retry matters. It returns one phase packet; this skill
  keeps phase order and completion.
- Use `swarm` only when the user explicitly requests independent parallel
  fan-out. It returns evidence packets; this skill keeps integration and final
  judgment.

## When Workers Are Unavailable

Do the work directly. Never claim delegated evidence that did not run. State
that delegation was unavailable and report the checks you ran yourself.
