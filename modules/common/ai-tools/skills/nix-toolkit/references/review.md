# Reviewing Nix Changes

This reference owns when to request a change and how to suggest it. It does not
set separate Nix style or performance rules. Read the relevant
[authoring guidance](authoring.md) for the technical decision, and
[evaluation performance](eval-performance.md) for measurement and acceptance.
Repository contributor canon remains authoritative.

## Decide Whether To Raise A Finding

| Decision                 | Threshold                                                                                          | Evidence                                                                              |
| ------------------------ | -------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| Request a change         | A correctness defect, broken contract, or violated repository requirement matters to the change.   | Identify the concrete failure and validate the proposed replacement.                  |
| Suggest optional cleanup | Code already being changed has a material local clarity or consistency improvement.                | Explain the benefit and validate the replacement; do not make preference a blocker.   |
| Leave alone              | Equivalent code is readable, follows local convention, or would require unrelated stylistic churn. | Do not manufacture a finding from a different valid authoring choice.                 |
| Measure first            | The proposed change rests on evaluation time or memory claims.                                     | Apply the evaluation playbook before claiming a gain or requesting complexity for it. |

For example, a branch lost in a conditional rewrite is a correctness finding; an
equivalent qualification choice is not automatically one. An unmeasured merge
rewrite is an optimization hypothesis, not a proven improvement.

Opportunistic cleanup stays within code already being changed. Keep optional
suggestions separate from required fixes. A review does not authorize edits; an
accepted implementation uses the caller's workflow.

## Suggest A Concrete Change

1. Read the author's latest reply and answer direct questions first.
2. Load the domain reference for the affected construct. Inspect the actual
   caller, repository convention, and intended behavior before applying a
   default.
3. Validate the exact replacement against the affected path. A template or parse
   check alone does not prove behavior, merge semantics, or a performance gain.
4. Lead with the concrete problem and its consequence in one or two sentences.
   Supply an applicable suggestion block or small diff, not an abstract rewrite
   request. Identify optional polish explicitly.
5. Add one line with the focused check, exact command, and observed result.
   Include material gaps; do not describe a hypothetical check as executed.

A useful finding contains: problem and consequence; smallest validated
replacement; focused check and result. For performance findings, include the
before/after measurements and the readability or capability tradeoff required by
the evaluation playbook.

If a defect is confirmed but the fix is not validated, report the defect and
state that gap. Omit unvalidated optional suggestions. Do not recommend feature
reductions as equivalent optimizations.

## Finish The Review

Batch actionable findings. Follow up in the existing thread without repeating
answered concerns or restarting a broad review after each reply. Stop when the
substantive concerns are resolved; leave authoring preferences to the owning
guidance and repository conventions.
