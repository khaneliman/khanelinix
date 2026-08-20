---
name: verification-harness
description: "Create or audit a portable project-local deterministic verification harness with Create and Audit modes, feature/check maps, observable outcomes, rerunnable commands, maintenance rules, and explicit gaps. Use when a verification surface is missing or unreliable. Do not use only to run an existing check."
license: Complete terms in LICENSE
---

# Verification Harness

Create or audit one project-local verification surface. Keep the surface
deterministic, portable, observable, minimal, and rerunnable.

## Modes

- **Create.** Build a missing harness from the feature/check map. Repair an
  unreliable harness when the caller requests repair.
- **Audit.** Inspect an existing harness, exercise its real outcomes, and list
  maintenance and coverage gaps without changing it unless repair is requested.

## Workflow

1. Confirm project scope, Create or Audit mode, supported environments, and exit
   criteria. Stop when the request mixes modes without a clear boundary.
2. Build a feature/check map. Record each behavior, observable outcome, minimal
   command, fixture or input, owner, and known gap.
3. In Create mode, add the smallest portable commands and fixtures that prove
   real outcomes. Prefer project-native tools and deterministic test data.
4. In Audit mode, run each mapped check and compare expected outcomes with
   observed outcomes. Mark missing, flaky, environment-bound, or stale checks.
5. Re-run changed checks from a clean invocation. Record commands, exit status,
   observable evidence, and unverified conditions.
6. After behavior changes, update the feature/check map and affected checks. Do
   not claim coverage when the map or maintenance evidence is stale.

## Output

Return the selected mode, feature/check map, changed or audited commands,
observable results, rerun commands, maintenance actions, and explicit gaps.
Separate harness creation or repair from ordinary check execution.

If the caller only asks to run an existing check, return that request to the
caller's normal verification method. This skill does not own ordinary check
execution.

## Boundaries

The caller owns lifecycle, architecture, final judgment, and external writes.
Keep this skill focused on the verification surface and its evidence.

This skill adapts pstack's `create-verification-skill` and
`maintain-verification-skill`. The included `LICENSE` preserves the exact
upstream MIT license text.
