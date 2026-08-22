# Adversarial Review

Use for an independent, read-only review of a commit, PR, or diff. Form a fresh
judgment from repository evidence instead of extending prior review conclusions.

This workflow owns clean-room and output contracts for every Git artifact,
including architecture-heavy or systemic changes. Invoke `$software-engineering`
when architecture, state, failure, or evolution premises need its lenses; keep
this workflow's finding format and final verdict authoritative.

## Review Input

Collect or require:

- repository path and exact commit, PR, or diff target
- read-only command that exposes the full change, such as `git show <commit>`
- two to four sentences describing the problem and motivation
- design premises stated as falsifiable assertions
- hard constraints absent from the diff, including portability targets, API
  contracts, downstream consumers, and performance budgets
- domain-specific scrutiny lenses
- one specific hazard needing a sanity check

If material input is missing, state the gap and review what can still be proven.
Do not invent requirements. Reject or replace any supplied inspection command
that can mutate the worktree, history, remotes, or external state.

## Evidence Axes

Check two evidence axes before synthesizing one verdict:

- **Standards:** Compare the change with contributor canon, scoped repository
  instructions, documented coding standards, and enforced tool contracts. Cite
  the owning rule for each violation. Do not add a generic smell baseline that
  the repository did not adopt.
- **Spec:** Locate the originating issue, specification, accepted plan, or user
  requirements. Check for missing or partial requirements, scope creep, and
  behavior that appears implemented but violates the requested contract. If no
  durable spec exists, state that evidence gap.

Keep findings separated by evidence axis during validation. Integrate their
severity ordering and final verdict here. Separate workers are optional evidence
collectors, not required owners of Standards or Spec judgment.

## Clean-Room Boundary

When the harness permits, route the review to a fresh worker with only the input
above, the target artifact, repository instructions, and permission to run
read-only probes. Do not pass prior findings, suspected bugs, intended fixes, or
review verdicts. If no fresh worker exists, explicitly disregard prior review
conclusions and rebuild evidence from the repository.

Remain read-only. Do not edit files, stage changes, rewrite history, post review
comments, or change external state.

When dispatching a fresh worker, populate this brief without adding prior review
conclusions:

```text
Independent adversarial review of <COMMIT/PR/DIFF> in <REPO_PATH>.
Run `<READ-ONLY COMMAND TO VIEW FULL CHANGE>` to see the full change.
Read-only. Do NOT edit files.

You are reviewing fresh, with no knowledge of any prior reviews. Form your own
judgment.

Background: <2-4 SENTENCES: PROBLEM AND MOTIVATION>.

The change claims:
<FALSIFIABLE DESIGN PREMISES>
Verify these premises against the actual codebase, not the diff alone.

Hard constraints the code must satisfy:
<PORTABILITY, API, DOWNSTREAM, PERFORMANCE, OR OTHER HIDDEN CONSTRAINTS>

Scrutinize:
1. <DOMAIN-SPECIFIC CORRECTNESS EDGE CASES>
2. <ESCAPING, TYPING, AND BOUNDARY ISSUES>
3. <SEMANTIC CHANGES BEYOND WHAT IS DOCUMENTED>
4. <TEST QUALITY: BEHAVIORAL CLAIMS OR TEXT/IMPLEMENTATION SHAPE?>
5. Anything else that risks rejection or major rework in review.

Also sanity-check one specific hazard: <BIGGEST DOUBT>.

Report each finding with file:line, severity (blocker/major/minor/nit), and a
concrete failure scenario (inputs/state → wrong outcome). Verify empirically
where possible by running code and grepping callers rather than reasoning from
the diff alone. State explicitly if you find no blockers. End with a clear
ready / not-ready verdict.
```

## Workflow

1. Read contributor guidance and every scoped repository instruction governing
   inspected paths. Identify the Standards sources and originating Spec source.
2. Run the supplied inspection command and inspect the full change, not only a
   summary.
3. Translate each claimed premise into a check that could disprove it. Verify
   against the actual codebase with caller searches, history, tests, generated
   outputs, or focused execution where useful.
4. Verify hard constraints outside the diff. Trace affected APIs, ordering,
   serialization, escaping, typing, boundaries, portability, performance, and
   downstream consumers as relevant.
5. Scrutinize:
   - correctness edge cases specific to the domain
   - escaping, typing, and trust-boundary failures
   - undocumented semantic changes
   - whether tests validate behavioral claims instead of matching text or
     implementation shape
   - any rejection or major-rework risk not covered by supplied lenses
6. Compare the validated change against both evidence axes. Record the owning
   Standards rule or Spec requirement for each supported finding.
7. Sanity-check the named hazard directly.
8. Prefer empirical evidence. Run focused code/tests and grep callers where
   possible. Distinguish verified failures from residual risks that could not be
   reproduced.
9. Check each candidate finding against actual lines and a concrete failure
   path. Omit vague style preferences and unsupported hypotheticals.

## Output

Report findings first, ordered by severity. For each finding include:

- `file:line`
- severity: `blocker`, `major`, `minor`, or `nit`
- evidence axis: `Standards`, `Spec`, or both
- violated premise or constraint
- concrete failure scenario as `inputs/state → wrong outcome`
- verification evidence, including command or caller path when useful

Then state residual test or evidence gaps. Explicitly say whether blockers were
found. End with exactly one verdict: `ready` or `not-ready`.

## Attribution

The Standards and Spec evidence axes are adapted from Matt Pocock's
`code-review` skill. Prose is original. Upstream terms are in
[LICENSE-matt-pocock.txt](../LICENSES/LICENSE-matt-pocock.txt).
