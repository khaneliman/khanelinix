---
description: "Lock the current task_plan.md content with a SHA-256 attestation. Prompt hooks warn when the file diverges without injecting its changed content. Use --show to print the stored hash, --clear to remove the attestation."
disable-model-invocation: true
allowed-tools: "Bash"
---

Run the plan attestation helper for the active plan.

Steps:

1. Resolve the active plan: prefer `${PLAN_ID}` env var, then
   `.planning/.active_plan`, then newest `.planning/<dir>/`, then legacy
   `./task_plan.md`.
2. Compute the SHA-256 of the resolved `task_plan.md`.
3. Write the hex digest to `.planning/<active-plan>/.attestation` (parallel-plan
   mode) or `./.plan-attestation` (legacy mode).
4. Confirm to the user with the short hash (first 12 hex chars) and the storage
   path.

Implementation:

- On Linux/macOS/Git Bash: `sh ${CLAUDE_PLUGIN_ROOT}/scripts/attest-plan.sh`
- On Windows PowerShell:
  `& "$env:USERPROFILE\.claude\skills\planning-with-files\scripts\attest-plan.ps1"`

Flags:

- `--show` — print the currently stored hash and where it lives.
- `--clear` — remove the attestation (re-open the plan to free editing).

After running this command, the prompt hook compares `task_plan.md` against the
stored hash. If they diverge, it emits a short warning and never injects the
changed body. Re-run `/plan-attest` whenever you intentionally edit and
re-approve the plan.
