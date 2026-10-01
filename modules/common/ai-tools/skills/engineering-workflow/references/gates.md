# Gates

Scale rigor to risk. Verify against the matching real surface, never against a
proxy that cannot fail.

## Risk Levels

- **Trivial**: obvious, reversible edits with no substantive behavior or
  contract change and no shared-state risk. File count alone does not raise risk.
- **Normal**: substantive implementation or caller-visible behavior changes
  within a known boundary.
- **High**: consequential changes across modules, data or migration risk,
  security or permissions, breaking public contracts, or unresolved uncertainty
  about what the change can affect.

Investigate uncertainty before raising the risk level. Touching a shared helper
or several files alone does not make a change high risk.

## Verification Gate

Focused verification is the minimum at every risk level. Choose evidence that
can expose a wrong result, using existing checks before adding new ones.

- Trivial: the focused check on the touched surface.
- Normal: the focused check plus the nearest regression surface.
- High: the focused check, the regression surface, and a reach check. Use
  `blast-radius` when reach past the diff is unclear.

Run the relevant command, build, or test when it provides meaningful evidence.
Direct inspection can establish a trivial edit or an obvious source,
documentation, or input/output contract mismatch. Describe that evidence as
inspection, not as an executed check. For complicated behavior, make serious
attempts to reproduce the issue and exercise the affected path.

Add regression coverage for meaningful behavior and plausible failures, not
every equivalent permutation or a test that mirrors a trivial edit. A focused
manual check or temporary reproduction can suffice when permanent coverage
would need disproportionate machinery; report what was checked and the remaining
automation gap. Use `verification-harness` to audit or propose when the needed
surface is missing, slow, or unreliable. Create or repair only what the
authorized task needs, using repository tools and conventions first.
When installed, use `performance-forensics` when completion depends on a
measured performance claim.

## Review Gate

Fresh independent review means a reviewer that did not write the change. Every
required review opens with the premise gate from the `premise-review` method in
`engineering-principles`, then proceeds to implementation review. Green checks
are supporting evidence; a reviewer may recommend redesign or closure of a fully
green change. Apply the method's test-value and execution boundary to reviewers
and review summaries. The Verification Gate belongs to implementation and
correction, not a second mechanical validation pass by the reviewer.

- Trivial: optional unless requested.
- Normal: one fresh independent reviewer. Check intended behavior, correctness,
  unnecessary complexity, maintenance burden, and the value and CI cost of tests.
- High: required. Use `interrogate` when the change is contested or high stakes.

## Correction Gate

- The parent classifies findings by evidence and risk. Accepted
  completion-blocking findings block handoff. Suggestions never expand scope.
- Correct accepted blockers within scope, then revalidate invalidated evidence.
- Request re-review for the corrected concerns; do not restart cleared review
  work without new evidence.
- Continue while evidence improves or accepted blockers shrink. If the same
  failure repeats without progress, re-ground the cause or escalate the method.
- Stop only for a concrete blocker, exhausted explicit budget, missing authority,
  or a material decision that requires the user. Report remaining blockers and
  rejected or nonblocking findings with reasons.

## Evidence Gate

- Report the checks that actually ran, with their real result.
- If a worker was unavailable, say so and report what you ran directly.
- Claim only checks, reviews, and delegated results that actually happened.
- List verification gaps explicitly in the handoff.
