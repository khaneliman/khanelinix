# Gates

Scale rigor to risk. Verify against the matching real surface, never against a
proxy that cannot fail.

## Risk Levels

- **Trivial**: one file, reversible, no contract change, no shared state.
- **Normal**: multiple files within one module, or a caller-visible behavior
  change.
- **High**: cross-module reach, data or migration risk, security or permissions,
  public contract, or unclear reach.

Choose the higher level when the change sits between two levels.

## Verification Gate

Focused verification is the minimum at every risk level. Run the narrow check
that would fail if the change were wrong.

- Trivial: the focused check on the touched surface.
- Normal: the focused check plus the nearest regression surface.
- High: the focused check, the regression surface, and a reach check. Use
  `blast-radius` when reach past the diff is unclear.

Run the real command, build, or test. Do not infer a pass from reading code. Use
`verification-harness` to audit or propose when the required real surface is
missing, slow, or unreliable. Create or repair it only with explicit authority.
When installed, use `performance-forensics` when completion depends on a
measured performance claim.

## Review Gate

Fresh independent review means a reviewer that did not write the change. Every
required review opens with the premise gate from the `premise-review` method in
`engineering-principles`, then proceeds to implementation review. Green checks
are supporting evidence; a reviewer may recommend redesign or closure of a fully
green change.

- Trivial: optional.
- Normal: required.
- High: required. Use `interrogate` when the change is contested or high stakes.

## Correction Gate

- The parent classifies findings by evidence and risk. Accepted
  completion-blocking findings block handoff. Suggestions never expand scope.
- Allow one correction pass on accepted findings.
- Allow one re-review after that correction.
- If accepted completion-blocking findings remain after re-review, stop and hand
  them to the user. Report rejected and nonblocking findings with reasons. Do
  not loop.

## Evidence Gate

- Report the checks that actually ran, with their real result.
- If a worker was unavailable, say so and report what you ran directly.
- Claim only checks, reviews, and delegated results that actually happened.
- List verification gaps explicitly in the handoff.
