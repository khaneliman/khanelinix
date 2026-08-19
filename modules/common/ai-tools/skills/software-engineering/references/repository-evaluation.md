# Repository Evaluation

Evaluate current repository or subsystem against stated purpose and likely
change. It is not a generic style review or a proposed design.

## Procedure

1. Define evaluation question, scope, excluded areas, time horizon, and evidence
   limits. “Evaluate repository” defaults to architecture and change readiness.
   It does not cover security or every line unless the request says so.
2. Map contributor canon, package or workspace boundaries, executable entry
   points, public interfaces, data stores, external systems, build and
   deployment paths, ownership clues, and validation commands.
3. Trace two to five representative flows from input to observable effect.
   Select normal path plus highest-risk or most change-prone paths.
4. Recover key state models and invariants. Identify where validation,
   authority, persistence, concurrency, and cleanup are owned.
5. Compare documented architecture with dependency and runtime evidence. Check
   whether boundaries actually isolate change and failure.
6. Sample tests, CI, release process, logging/metrics, migrations, and incident
   or issue history where available. Do not infer quality from test count alone.
7. Rank findings by user or operator impact, reach, likelihood, recovery cost,
   and evidence strength. Distinguish current defect, structural risk, and
   future opportunity.

Apply root engineering lenses across selected flows. Emphasize credible change
scenarios, cost concentration, operational ownership, and whether actual module
boundaries contain those pressures.

## Output

1. Scope, evidence inspected, and confidence limits.
2. Current architecture summary; include compact component/flow view only when
   relationships are otherwise hard to follow.
3. Strengths worth preserving.
4. Ranked findings with evidence, impact, and affected flows.
5. Recommended sequence: urgent corrections, enabling refactors, then optional
   evolution. Keep each recommendation independently valuable where possible.
6. Unknowns and next probes that could materially change recommendation.

Avoid maturity grades, pattern-count scorecards, or repository-wide rewrites
without a defined target property and migration path.
