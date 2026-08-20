# Validation

Run checks proportional to changed behavior and risk.

- Use focused checks for trivial work; add broad or boundary suites for normal
  and high-risk changes.
- Route one known test, lint, evaluation, or build command to `checker`; route
  broad or noisy suites to `test-runner`.
- Route noisy logs to the validation lane. Workers may create build artifacts
  but must not edit source.
- Use a separate provider or model from implementation when useful. Keep Gemini
  fallback-only.
- Summarize command, result, failure signal, and relevant log excerpt; do not
  return raw output.
- On failure, reproduce once, then route ambiguous cause to diagnosis. Do not
  retry the same failing route without new evidence.

Return pass, fail, or blocked evidence to the lifecycle owner. Separate
environmental failures from product failures. Do not correct source or advance
to review.
