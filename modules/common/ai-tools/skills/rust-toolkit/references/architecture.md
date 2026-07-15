# Rust Project Architecture

Use this mode for module, crate, workspace, API, dependency, feature, and error
boundaries. Start from current constraints; architecture is a response to change
pressure, not a template.

## Contents

- [Intake](#intake)
- [Module or Crate?](#module-or-crate)
- [Dependency Direction](#dependency-direction)
- [Public Surface](#public-surface)
- [Errors and Observability](#errors-and-observability)
- [New Project Decisions](#new-project-decisions)
- [Review Questions](#review-questions)

## Intake

Record before editing:

- package and workspace members, target kinds, edition, MSRV, and resolver
- binary, library, proc-macro, build-script, FFI, and generated-code boundaries
- supported targets and feature combinations
- public API and SemVer commitments
- CI commands, release packaging, and deployment units
- dependency direction and current compile-time bottlenecks

Use `scripts/project-context.py <path>` for the mechanical inventory, then read
the manifests and call sites that own the decision.

## Module or Crate?

Keep code in one crate by default. Split only when at least one boundary needs
independent enforcement:

| Signal                                                        | Prefer                              |
| ------------------------------------------------------------- | ----------------------------------- |
| Internal organization only                                    | Private modules                     |
| Narrow internal surface                                       | `pub(crate)` / `pub(super)` modules |
| Shared by multiple packages                                   | Library crate                       |
| Procedural macro                                              | Dedicated proc-macro crate          |
| Distinct target, feature, MSRV, release, or dependency budget | Dedicated crate                     |
| Measured recompilation fan-out from stable code               | Crate boundary after timings        |
| Domain split with constant cross-boundary churn               | Keep together                       |

Avoid catch-all `common`, `shared`, or `utils` crates. Name a boundary for the
capability or invariant it owns. A shared-types crate is justified only when
types form a stable, dependency-light contract; otherwise it becomes a coupling
hub.

## Dependency Direction

- Keep policy/domain code independent from transport, storage, UI, runtime, and
  engine adapters when that separation supports testing or replacement.
- Put traits at the side that owns the abstraction. Do not create a trait only
  to hide one concrete implementation.
- Pass narrow values or capability interfaces across boundaries. Avoid a
  globally imported application context.
- Check feature unification and duplicate dependency versions before blaming
  source layout for build cost.
- Reject cycles by moving the shared contract inward, merging unstable
  boundaries, or introducing messages/data—not by adding a miscellaneous crate.

Layered, hexagonal, or clean architecture is optional vocabulary. Preserve the
useful invariant—dependencies point toward stable policy—without reproducing a
framework-shaped directory tree.

## Public Surface

- Keep items private until a consumer requires visibility.
- Re-export intentionally from a small facade; do not expose internal module
  layout accidentally.
- Mark extension points deliberately (`#[non_exhaustive]`, sealed traits,
  private fields, builders) based on compatibility needs.
- Keep feature flags additive when possible. Test important combinations and
  avoid features that silently change type meaning.
- Treat error variants, trait methods, auto-trait behavior, and generic bounds
  as API commitments for published libraries.

## Errors and Observability

- Use typed errors where callers can recover or classify failure.
- Add context at abstraction boundaries. Preserve original sources.
- Use opaque application errors at the executable boundary when callers do not
  need variant-level control; avoid exporting implementation-specific errors.
- Separate operator diagnostics from stable user-facing messages.
- Do not log and return the same error at every layer. Log once where ownership
  of handling ends, with identifiers needed to trace the operation.
- Reserve panic for violated internal invariants or unrecoverable startup
  assumptions, not ordinary input, I/O, or network failure.

## New Project Decisions

- Start with the smallest package shape that satisfies known outputs. Do not
  mandate a workspace for a single cohesive target.
- Add a workspace when packages need independent target kinds, dependencies,
  release units, or reuse. Centralize shared package metadata and dependency
  versions where it reduces drift.
- Pin a toolchain or MSRV only when reproducibility or support policy requires
  it. Keep CI aligned with that declaration.
- Choose async runtime, serializer, error stack, logging stack, allocator,
  linker, and codegen backend from actual constraints. Do not bake ecosystem
  preferences into scaffolding.

## Review Questions

1. What invariant does each boundary enforce?
2. Which changes trigger recompilation or coordinated releases across it?
3. Can invalid dependency direction be expressed or tested mechanically?
4. Is the public surface smaller and clearer than the implementation surface?
5. Does the proposed abstraction have at least two meaningful behaviors, or a
   strong testing/ownership reason before the second arrives?
