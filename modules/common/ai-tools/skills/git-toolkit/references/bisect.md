# Regression Bisect

Use only with a clean worktree, known good ref, known bad ref, and reproducible
pass/fail test. Stop and request the missing prerequisite instead of guessing.

## Automated Path

For a deterministic test, use the isolated helper:

```bash
python3 "<path-to-skill>/scripts/bisect_run.py" \
  --repo . \
  --good "$good" \
  --bad "$bad" \
  -- ./test-command arg
```

Test command must follow Git bisect's exit-code contract. Helper refuses dirty
worktrees, checks that good is an ancestor of bad, creates a temporary detached
worktree, verifies the test executable before starting bisect, and cleans up
after success, failure, or interruption. Exit 126/127 abort instead of marking a
revision bad. It reports first bad commit plus bounded tested/skipped evidence
and bounded stdout/stderr tails as stable JSON; use `--format text` for a
compact human report. Adjust `--max-tested-revisions`, `--max-body-chars`, or
`--max-bisect-output-bytes` only when default evidence bounds are insufficient.

## After Isolation

1. Inspect first-bad patch and directly relevant context before claiming
   causality.
2. Report tested range, skipped commits, uncertainty, and smallest useful next
   check.

Use manual `git bisect good|bad|skip` only when judgment cannot be expressed as
a deterministic command. Record original ref and always reset when done.

Do not edit source, create commits, or leave repository in bisect state during
diagnosis.
