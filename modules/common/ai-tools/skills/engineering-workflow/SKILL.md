---
name: engineering-workflow
description: Complete routine bug fixes, features, refactors, migrations, and configuration changes. Use for implementation, not standalone diagnosis, review, or large unattended work.
license: Complete terms in LICENSE
---

# Engineering Workflow

Carry a routine software change through working implementation, verification,
accepted corrections, and authorized delivery. A first patch is not completion.
Choose the amount of investigation and structure the task needs, not a fixed
sequence of documents or specialist invocations.

## Scope and Authority

Architecture-only work belongs to `software-engineering`; large, cross-cutting,
or unattended work belongs to `figure-it-out`. A direct explanation, diagnosis,
or review request does not authorize implementation.

Honor local-commit authority from the current request or standing user policy.
Commit verified atomic slices when authorized; respect workspace-only requests.
Local authority implies no authority to push, merge, publish, deploy, open a
pull request, or perform another external write. Use existing authorization;
ask only for a missing decision or capability that blocks the requested result.
The parent retains architecture acceptance, integration, and final judgment.

## Completion

- Establish the intended behavior, affected boundary, and evidence that will
  demonstrate success. Keep these in working context unless handoff or recovery
  needs a durable artifact.
- Implement the smallest complete change consistent with surrounding code.
  Use domain guidance for non-obvious constraints, not generic programming steps.
- Run relevant existing checks and any checks required by contributor canon.
  Verify new behavior and affected regressions. Add tests when they establish
  a meaningful contract; do not manufacture tests for low-impact edits.
- Review the diff for correctness and scope. Fresh independent review is
  required when requested, for high-risk changes, or when correctness or impact
  uncertainty remains after investigation. Routine changes otherwise do not
  require a worker. See [gates.md](references/gates.md) for risk and correction
  criteria when these decisions need more detail.
- Resolve accepted blockers and rerun checks invalidated by corrections.
  Continue while making progress; investigate repeated unchanged failures.
  Stop for a concrete blocker, missing authority, or an explicit budget limit,
  not merely because the first implementation or review finished.
- Complete authorized delivery and task-owned resource cleanup. Report the
  result, actual checks, and material gaps without claiming unobserved success.

## Guidance When Needed

- For unclear acceptance or a handoff, use
  [phase-handoff.md](references/phase-handoff.md).
- For task-specific completion criteria, including bounded modernization, use
  [task-shapes.md](references/task-shapes.md). Its phases are planning vocabulary,
  not mandatory checkpoints for every change.
- For uncertain interfaces or state ownership, use `architect`. For difficult
  diagnosis, use `diagnosing-bugs`; for historical rationale, use `why`.
- For commit splitting or task-owned worktree creation and cleanup, use
  `git-toolkit`. For coordinated slices, use `engineering-principles`.
- Before delegating, read [delegation.md](references/delegation.md). Use
  `interrogate` for contested or high-stakes review, and `multi-provider-sdlc`
  only when concrete provider routing is needed.
- Use `tdd` when explicitly requested. Other specialist methods are optional
  unless the task or repository requires them. Resume unfinished work after a
  specialist returns; do not repeat completed checks to satisfy a phase label.
