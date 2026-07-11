# Regression Bisect

Use only with a clean worktree, known good ref, known bad ref, and reproducible
pass/fail test. Stop and request the missing prerequisite instead of guessing.

## Workflow

1. Record original ref, good ref, bad ref, and exact success/failure signal.
2. Start bisect with bad then good. Prefer `git bisect run <test-command>` when
   test is deterministic; otherwise ask for each manual good/bad judgment.
3. When Git identifies first bad commit, inspect its patch and directly relevant
   context before claiming causality.
4. Always run `git bisect reset`, including after an inconclusive or failed run.
5. Report first bad commit, evidence, tested range, skipped commits,
   uncertainty, and smallest useful next check.

Do not edit source, create commits, or leave repository in bisect state during
diagnosis.
