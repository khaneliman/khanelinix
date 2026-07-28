# Validation

Run checks proportional to changed behavior and risk.

- Use focused checks for trivial work; add broad or boundary suites for normal
  and high-risk changes.
- Route noisy logs to the validation lane. Workers may create build artifacts
  but must not edit source.
- Use a separate provider or model from implementation when useful. Keep Gemini
  fallback-only.
- Summarize command, result, failure signal, and relevant log excerpt; do not
  return raw output.
- On failure, reproduce once, then route ambiguous cause to diagnosis. Do not
  retry the same failing route without new evidence.

Validation failure blocks completion, not implementation progress already made.
Fix scoped causes, rerun affected checks, and report environmental failures
separately from product failures.
