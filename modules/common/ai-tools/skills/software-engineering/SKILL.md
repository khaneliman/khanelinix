---
name: software-engineering
description: Evidence-backed software engineering for current-state repository or subsystem architecture and maintainability evaluation; planning changes that are large or cross-cutting, including features, refactors, migrations, and technical-debt reduction; and reviewing proposed standalone software architecture or cross-component designs. Use when work needs repository-wide understanding, explicit contracts and invariants, boundary or tradeoff analysis, failure and evolution design, or an implementation-ready validation strategy. Do not use for routine localized edits, visual design, AI-configuration review, security audits, or pure implementation owned by a domain skill. Do not use as primary workflow for commit/PR/diff review; use only as secondary architecture lenses when Git review invokes it.
---

# Software Engineering

Use this skill as judgment entry point. Let repository canon define local policy
and language, framework, security, Git, and delivery skills own specialist work.

## Start from Evidence

1. Read contributor canon and every instruction file governing target paths.
2. State mode, desired outcome, constraints, stakeholders, and consequence of
   failure. Separate observed facts, inferences, assumptions, and unknowns.
3. Inspect only enough repository breadth to trace relevant entry points,
   dependencies, state, side effects, tests, deployment, and prior decisions.
4. Recover current behavioral contract before proposing structure. Treat code,
   tests, public interfaces, schemas, and operational evidence as potentially
   conflicting evidence; identify conflict instead of silently choosing.
5. Load matching domain skills before judging version-sensitive APIs or
   implementation details. If none applies, inspect manifests and current code,
   then verify against primary official documentation through available live
   tools; state evidence gap when verification is unavailable.

## Route One Primary Mode

- **current-state repository or subsystem evaluation** — audit existing
  architecture, maintainability, correctness, operability, and change readiness.
  Read [repository-evaluation.md](references/repository-evaluation.md).
- **large-change planning** — convert a feature, refactor, migration, or
  technical-debt outcome into contracts, state changes, boundaries, increments,
  rollout, and verification. Read
  [large-change-planning.md](references/large-change-planning.md).
- **proposed standalone software architecture review** — challenge a design
  proposal or ADR before implementation and outside commit/PR/diff review. Read
  [architecture-review.md](references/architecture-review.md).

Read [foundations.md](references/foundations.md) when choosing or explaining
cross-cutting engineering principles.

For secondary Git-review support, do not select a primary mode or produce a
separate verdict. Apply root lenses to supplied architecture premises and return
them to `$git-toolkit`; its clean-room, finding, and verdict contracts remain
authoritative. Use `$planning-with-files` only when task state should persist
across sessions or compaction, `$architect` for AI configuration, and security
skills for explicit security audits or threat models.

## Apply Engineering Lenses Proportionally

1. **Behavior:** inputs, outputs, errors, side effects, compatibility, and
   observable guarantees.
2. **State:** abstract value, valid states, invariants, ownership, transitions,
   mutability, persistence, and recovery.
3. **Boundaries:** cohesion, coupling, information hiding, dependency direction,
   naming, authority, and failure containment.
4. **Execution:** ordering, concurrency, idempotency, partial failure, retries,
   timeouts, resource bounds, observability, and security where relevant.
5. **Evolution:** expected change, migration, rollback, test seams, maintenance
   ownership, and removal path.
6. **Responsibility:** affected stakeholders, harm, fairness, privacy,
   accessibility, accountability, and human control in proportion to impact.

Increase depth when work changes public APIs or schemas, stored data,
authentication or trust boundaries, concurrent or remote effects, destructive
operations, or safety-, legal-, or livelihood-relevant workflows. Otherwise
sample representative paths and state evidence limits.

Do not mechanically require ADTs, immutability, SOLID patterns, hierarchical
names, adapters, distributed machinery, or approval gates. Introduce a boundary
only when it enforces an invariant, contains failure, isolates likely change,
clarifies ownership, or creates a needed test seam. Prefer smallest design that
satisfies observed requirements and keeps an explicit path for credible change.

## Produce Decision-Ready Output

- Lead with outcome and highest-risk evidence.
- Show current model before proposed delta when structure spans components.
- Tie each recommendation to requirement, evidence, invariant, failure mode, or
  measured change pressure.
- Include alternatives only where choice is material; explain rejected option
  and reversal cost.
- End with validation, rollout or follow-up, unresolved unknowns, and
  confidence.
