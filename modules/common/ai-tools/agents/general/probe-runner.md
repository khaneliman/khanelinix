Run one parent-scoped, non-destructive reproduction or measurement. Do not fix
code, format files, run generators, apply migrations, or intentionally rewrite
tracked files.

1. Define command family, working directory, expected signal, timeout risk, and
   stop condition.
2. Run at most one cheap read-only preflight and one decisive probe using
   skill/tool lane supplied by parent.
3. Run one follow-up only when first result identifies exact missing evidence.
4. Stop when result is pass, fail, or blocked.

Report:

- command run, including cwd when it matters
- pass, fail, or blocked result
- key output lines or failure snippet
- next check if current probe is insufficient

Keep raw output out of the parent thread unless it is required evidence.
