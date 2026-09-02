# Premise Review

Use this method at the start of every plan, diff, or pull-request review.
Decide whether the change should exist in this form before checking whether
its implementation is correct. A review that only validates changed lines can
approve a green patch that solves the wrong problem.

**Why:** Authors hand reviewers a framing: the problem, the chosen abstraction,
the extraction boundary. A reviewer who accepts that framing verifies execution
and multiplies confidence in an unchallenged premise. CI status and reviewer
count then read as evidence about design when they are evidence about
implementation only.

## Review Order

Answer each stage with evidence before the next. Stop early and recommend
redesign or closure when a stage fails.

1. Premise and demonstrated value.
2. Issue fit and scope.
3. API and architecture.
4. Diff minimality and unrelated noise.
5. Behavioral correctness and integration.
6. Tests, docs, and policy compliance.

Green checks belong to stages 5 and 6. They are supporting evidence, not the
purpose of review. A reviewer must be able to recommend closing or redesigning
a fully green change.

## Premise Gate

Record this block first in every review report, before findings and before the
verdict. Write one conventional comment per concern, in the form
`<label> [(decoration)]: <concern>: <evidence>`, with the labels and decorations
from conventionalcomments.org. Answer from repository evidence: issue text,
callers, existing options, schemas, history, and canon. Cite what was searched,
including when a concern clears.

```text
## Premise gate

note: problem: <user or maintenance problem the change claims to solve, with source>
note: solves: <whether the diff solves that problem or only an incidental subproblem>
note: issue fit: <issue or request relationship, and whether it is accurate>
note: existing capability: <none, with what was searched, or the path or option that already provides it>
note: native abstraction: <none, with what was searched, or the native shape that avoids a parallel option or data model>
note: api boundary: <whether the public API is the right long-term boundary>
note: removable diff: <none, or the parts that can go without losing the claimed value>
note: bundling: <clean, or the cosmetic, compatibility, refactor, and functional changes that are mixed>
note: handed premise: <what the author presented as fact that the review challenged>
note: reason not to merge: <none, or why a compiling, fully green patch still should not merge>
```

`note:` records a cleared concern with the evidence that clears it. When a
concern fails, change the label: `issue (blocking):` when it should stop the
merge, `suggestion (non-blocking):` or `question:` when it should not. Decorate
every `issue` and `todo` in the gate explicitly. A blocking premise comment
names the existing capability, native abstraction, or removable diff so the
author can act on it.

Any `(blocking)` premise comment fails the gate. The final verdict is then
`changes_requested`, `blocked`, or `not-ready`, with redesign or closure
recommended; `approved` and `ready` are not available. Findings after the gate
use the same conventional-comment form, so a reader sees at a glance whether
each finding blocks.

`No issues found` and `approved` mean the premise, scope, API boundary, and
minimality were checked, not only the changed lines.

Check a report with `../scripts/premise_gate_check.py review <report.md>`. It
fails on a missing or unknown concern, a comment without evidence, an
undecorated `issue` or `todo`, a gate placed after findings or the verdict, or
an approving verdict beside a blocking premise comment.

## Reviewer Packets

When the parent delegates review, build each packet from these fields:

```text
- Independence: blind | informed
- Problem: <claimed problem, with source>
- Repository context: <paths, canon, existing options, search seeds>
- Target: <read-only command that shows the full change>
- Author claims: <falsifiable claims; informed packets only>
- Constraints: <contracts outside the diff>
- Write policy: read-only
- Lane: <skills and tools>
- Required evidence: premise gate, findings as conventional comments, verdict
- Exit criteria: <what ends the review>
```

At least one reviewer receives a `blind` packet: the problem statement,
repository context, and target, without the author's claims, the chosen
solution, or the extraction boundary presented as correct. Do not phrase a
blind packet as "verify that <solution> works".

Reviewers that share one unchallenged premise are one reviewer. Count
agreement as independent evidence only when the agreeing reviewers answered the
premise gate from different packets and at least one was blind. A premise
finding from one blind reviewer outranks implementation consensus from informed
reviewers.

Check a packet with `../scripts/premise_gate_check.py packet <packet.md>`. It
fails when a packet lacks the problem statement, repository context, read-only
write policy, or the premise-gate evidence requirement, and when a blind packet
carries author claims or a chosen solution.

## Regression Case

Home Manager draft PR #9893 added `programs.msmtp.accountOrder`. Several
reviewers verified behavior, tests, compatibility, and contribution policy,
accepted the extraction premise, and approved a green patch. The gate records
`issue (blocking): native abstraction:` naming an msmtp-owned account model
with DAG ordering, `issue (blocking): removable diff:` for the whole new option,
and the verdict `changes_requested`. The fixtures under
`../tests/fixtures/premise-review/` keep that case next to non-Nix cases so the
contract does not depend on one ecosystem.
