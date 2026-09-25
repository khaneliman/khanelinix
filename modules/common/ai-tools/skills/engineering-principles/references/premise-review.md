# Premise Review

This is the review contract for every review kind. Plan, local change, pull
request, multi-model, and reach reviews share its packet, review order, premise
gate, evidence axes, test-value boundary, finding format, and verdict. Each kind
adds only its target, extra inputs, and output destination.

Use this method at the start of every plan, diff, or pull-request review.
Decide whether the change should exist in this form before checking whether
its implementation is correct. A review that only validates changed lines can
approve a green patch that solves the wrong problem.

**Why:** Authors hand reviewers a framing: the problem, the chosen abstraction,
the extraction boundary. A reviewer who accepts that framing verifies execution
and multiplies confidence in an unchallenged premise. CI status and reviewer
count then read as evidence about design when they are evidence about
implementation only.

## Review Kinds

| Kind           | Target                                         | Adds                                                                                     | Entry, when installed              |
| -------------- | ---------------------------------------------- | ---------------------------------------------------------------------------------------- | ---------------------------------- |
| Plan or design | Plan, proposal, or ADR                         | Stages 1 to 3 carry the verdict; check missing dependencies, validation gaps, sequencing | `reviewer` worker, `software-engineering` |
| Local change   | Read-only command that shows a commit or diff  | Clean-room dispatch                                                                      | `git-toolkit` adversarial-review   |
| Pull request   | Current PR head and its full thread history    | Duplicate gate, contributor replies, public comment format                               | `github-toolkit` pr-review         |
| Multi-model    | One packet sent to several model families      | Seat selection, adversarial lenses, lead synthesis                                       | `interrogate`                      |

A kind never redefines the packet, finding format, or verdict. When a new review
need appears, add a row here instead of writing another contract. Reach analysis
beyond the diff, such as `blast-radius`, is a probe method rather than a review
kind; its confirmed risks feed a review's scrutiny.

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

## Evidence Axes

Read the reviewed repository's contributor guidance and every scoped instruction
file governing the inspected paths, then check two evidence axes before
synthesizing one verdict:

- **Standards:** Compare the change with the reviewed repository's contributor
  canon, scoped instructions, documented coding standards, and enforced tool
  contracts. Cite the owning rule for each violation. Do not add a generic smell
  baseline that the repository did not adopt.
- **Spec:** Compare the change with the requirements the packet names: the
  originating issue, specification, accepted plan, or the user's stated request.
  Check for missing or partial requirements, scope creep, and behavior that
  appears implemented but violates the requested contract. If no requirement
  source exists, state that evidence gap.

Keep findings separated by evidence axis during validation, then integrate their
severity ordering into one verdict. Separate workers are optional evidence
collectors, not required owners of Standards or Spec judgment.

The Standards and Spec evidence axes are adapted from Matt Pocock's
`code-review` skill. Prose is original. Upstream terms are in
[LICENSE-matt-pocock.txt](../LICENSES/LICENSE-matt-pocock.txt).

## Scrutiny

After the premise gate, check what the change does, including the part the diff
does not spell out:

- correctness edge cases specific to the domain, on success and failure paths
- escaping, typing, and trust-boundary failures
- undocumented semantic changes, and hard constraints outside the diff such as
  API consumers, ordering, serialization, portability, and performance budgets
- security defects you can trace from input to sink
- the one hazard the packet names, checked directly
- anything else that would get the change rejected or reworked in review, even
  when no supplied lens names it

Translate each author claim into a check that could disprove it. Verify it
against the codebase with caller searches, history, generated outputs, or a
hypothesis-driven probe, not against the diff alone. Distinguish verified
failures from residual risks you could not reproduce.

## Test Value and Execution Boundary

Assess the usefulness of tests and checks, not their current pass status. Read
their assertions, fixtures, mocks, and CI wiring. Judge which realistic defects
they catch, whether they would fail for the reported bug or a plausible broken
implementation, and which integration or compatibility boundaries they miss.
Identify vacuous assertions, implementation-mirroring tests, and redundant
coverage when they create false confidence or maintenance cost. Tie each
coverage finding to a concrete behavior and the check that should detect it.

Do not rerun existing tests, builds, linters, or other mechanical checks to
confirm the current PR state; CI owns that signal. Do not present passing
checks as review findings or review progress. Run a targeted experiment only
to resolve a specific review hypothesis that existing CI evidence cannot
answer. State the hypothesis first and report what the experiment establishes,
not merely its exit status. Routine validation belongs to the implementation
or CI-check lane, not the reviewer.

## Premise Gate

Record this block first in internal review reports, before findings and before
the verdict. Keep cleared concerns and the full checklist out of public reviews;
publish only actionable findings in the concise review-authoring format.
Write one conventional comment per internal concern, in the form
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
`changes_requested` or `blocked`, with redesign or closure recommended;
`approved` is not available. Findings after the gate use the same
conventional-comment form, so a reader sees at a glance whether each finding
blocks.

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
- Requirements: <durable source, or quoted requirement statements; see below>
- Repository context: <paths, canon, existing options, search seeds>
- Target: <read-only command that shows the full change, or the plan path>
- Author claims: <falsifiable claims, including that the change should exist in this form; informed packets only>
- Constraints: <contracts outside the diff>
- Hazard: <the one specific doubt to sanity-check, when there is one>
- Lenses: <domain-specific scrutiny beyond the contract list, when the domain has non-obvious constraints>
- Write policy: read-only
- Lane: <skills and tools>
- Review boundary: assess test value; no routine CI reruns or passing-check reports;
  execute only to resolve a stated hypothesis unanswered by existing evidence
- Required evidence: premise gate, findings as conventional comments, verdict
- Exit criteria: <what ends the review>
```

Fill the Requirements field by context. When the requirement lives in a durable
artifact, such as an issue, PR description, spec, or plan file, give its link or
path and let the reviewer read it. When it exists only in the conversation,
quote the user's own words for the asks, accepted scope changes, and stated
non-goals; a parent paraphrase carries the parent's framing, which is what an
independent reviewer is meant to test. Quote those requirement statements only,
not the conversation. In a blind packet, keep the requirement and drop wording
that names the chosen solution.

Include the test-value and execution boundary in every dispatched review packet,
including named-model and fallback workers. Do not pass only the premise-gate
report template: it omits this boundary. Apply it to review progress and final
synthesis as well as worker findings.

At least one reviewer receives a `blind` packet: the problem statement,
requirements, repository context, and target, without the author's claims, the
chosen solution, or the extraction boundary presented as correct. Do not phrase
a blind packet as "verify that <solution> works".

Reviewers that share one unchallenged premise are one reviewer. Count
agreement as independent evidence only when the agreeing reviewers answered the
premise gate from different packets and at least one was blind. A premise
finding from one blind reviewer outranks implementation consensus from informed
reviewers.

Keep every packet clean-room: do not pass prior findings, suspected bugs,
intended fixes, or earlier verdicts. When no fresh worker is available, set
prior review conclusions aside and rebuild the evidence from the repository.

Check a packet with `../scripts/premise_gate_check.py packet <packet.md>`. It
fails when a packet lacks the problem statement, repository context, read-only
write policy, or the premise-gate evidence requirement, and when a blind packet
carries author claims or a chosen solution.

## Findings

Keep only highly likely defects and concrete, evidenced suggestions. Revalidate
every finding against the current target state, including the current PR head
when reviewing a pull request. Keep one defect per finding and write it as a
conventional comment, `<label> (blocking|non-blocking): <subject>`, using
`issue`, `suggestion`, `question`, `nitpick`, `note`, or `todo` as the label.
Decorate `(blocking)` when the defect would stop the merge: incorrect behavior
on a reachable path, data loss, a traced security defect, a violated hard
constraint, or a failed premise concern. Use `(non-blocking)` for design or
maintenance risks that are not yet broken, and include a `nitpick` only when it
is useful. Order findings by severity, blocking first. Each finding carries:

- **Location:** exact `file:line`, or the plan section for a design review.
- **Axis:** `Standards`, `Spec`, or both, when one applies, citing the owning
  rule or requirement.
- **Failure:** the trigger or input, the current behavior, and the expected
  behavior, as a concrete scenario of `inputs/state → wrong outcome`.
- **Evidence:** what was checked and what it showed: the caller path, history,
  generated output, or the stated hypothesis and probe result. A finding
  without evidence is a residual risk, not a finding.
- **Fix:** one concrete correction with the applicable code shape, exact
  condition, type, or module assignment. State precedence and compatibility
  behavior when relevant. If repository behavior does not establish one fix,
  state the unresolved choice and viable alternatives instead of guessing.
- **Proof:** a focused regression test that fails before the correction; for a
  design, the check that would expose the failure.

Each finding answers what breaks, why it breaks, the replacement code shape, and
the proof test. Cite prior art only when it clarifies intent. Prefer this
repository; use an external repository only when it owns the protocol or
behavior being consumed, linking a pinned commit and exact lines and saying why
it applies. Do not restate the diff, flag style preferences, pre-existing
problems, or cases without a reachable path, or leave abstract repair verbs
without an exact operation.

## Verdict

End every review with exactly one verdict: `approved`, `changes_requested`, or
`blocked`. Use `blocked` only when missing evidence or capability prevents a
reliable verdict. A `(blocking)` finding or premise comment rules out
`approved`. State explicitly whether blockers were found, then list residual
test or evidence gaps. A kind that publishes, such as pull-request review,
renders this verdict in its venue's format instead of adding another
vocabulary. Reviewers return findings and the verdict; they do not fix
findings, advance phases, or own the correction decision.

## Regression Case

Home Manager draft PR #9893 added `programs.msmtp.accountOrder`. Several
reviewers verified behavior, tests, compatibility, and contribution policy,
accepted the extraction premise, and approved a green patch. The gate records
`issue (blocking): native abstraction:` naming an msmtp-owned account model
with DAG ordering, `issue (blocking): removable diff:` for the whole new option,
and the verdict `changes_requested`. The fixtures under
`../tests/fixtures/premise-review/` keep that case next to non-Nix cases so the
contract does not depend on one ecosystem.
