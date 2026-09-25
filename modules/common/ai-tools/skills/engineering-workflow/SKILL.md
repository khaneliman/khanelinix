---
name: engineering-workflow
description: Complete routine bug fixes, features, refactors, migrations, and configuration changes. Use for implementation, not standalone diagnosis, review, or large unattended work.
license: Complete terms in LICENSE
---

# Engineering Workflow

Carry one routine software change through working implementation, verification,
accepted corrections, and authorized delivery. A first patch is not completion.

## Route First

Before the first edit, name the shape and the risk level, then read both files
below in full. They are short, and they hold the checks and done conditions this
page leaves out.

1. Read your shape's section of [task-shapes.md](references/task-shapes.md).

   | Shape         | Use for                                                  |
   | ------------- | -------------------------------------------------------- |
   | Bug fix       | restoring intended behavior                              |
   | Feature       | adding behavior                                          |
   | Configuration | changing settings, options, dependency versions, or pins |
   | Refactor      | changing structure while behavior stays identical        |
   | Modernization | replacing a legacy language, runtime, or toolchain       |
   | Prototype     | answering whether an approach works                      |
   | Evaluation    | choosing between options                                 |

2. Read [gates.md](references/gates.md). It sets the risk level, the checks and
   review each level requires, and when correction ends.

A trivial change, meaning an obvious, reversible edit with no behavior, contract,
or shared-state change, may skip both files: make it, run the focused check, and
report. Modernization also reads [modernization.md](references/modernization.md).

Read these when you reach the step:

- Before delegating any work: [delegation.md](references/delegation.md).
- Before a handoff, or while acceptance is unclear:
  [phase-handoff.md](references/phase-handoff.md).

## Scope and Authority

Architecture-only work belongs to `software-engineering`; large, cross-cutting,
or unattended work belongs to `figure-it-out`. Explanation goes to `how` or
`why`, and standalone diagnosis to `diagnosing-bugs`. A direct explanation,
diagnosis, or review request does not authorize implementation.

Honor local-commit authority from the current request or standing user policy.
Commit verified atomic slices when authorized; respect workspace-only requests.
Local authority implies no authority to push, merge, publish, deploy, open a
pull request, or perform another external write. Use existing authorization;
ask only for a missing decision or capability that blocks the requested result.
The parent retains architecture acceptance, integration, and final judgment.

## Completion

- Establish the intended behavior, affected boundary, and evidence that will
  demonstrate success, at the depth your shape sets.
- Implement the smallest complete change consistent with surrounding code.
- Verify and review as [gates.md](references/gates.md) requires for the risk
  level. Add tests only when they establish a meaningful contract.
- Resolve accepted blockers and rerun checks the corrections invalidated.
  Continue while making progress; stop for a concrete blocker, missing
  authority, or an explicit budget limit, not because the first patch or review
  finished.
- Complete authorized delivery and task-owned cleanup. Report the result, the
  checks that actually ran, and material gaps.

## Methods

Use a method when its trigger applies; resume this workflow after it returns and
do not repeat completed checks.

- Uncertain interfaces or state ownership: `architect`.
- Hard diagnosis: `diagnosing-bugs`. Historical rationale: `why`.
- Commit splitting, worktrees, and cleanup: `git-toolkit`. Coordinated slices:
  `engineering-principles`.
- Contested or high-stakes review: `interrogate`. Concrete provider routing:
  `multi-provider-sdlc`.
- Test-first work, only when requested: `tdd`.
