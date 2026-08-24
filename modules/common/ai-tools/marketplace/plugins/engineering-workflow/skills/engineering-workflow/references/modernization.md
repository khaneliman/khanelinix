# Modernization

Use this shape for a bounded replacement of a legacy language, runtime,
framework, build system, package format, or repository toolchain. Preserve the
contracts that matter. Remove the obsolete path when controlled consumers move.

## Owner Boundary

`engineering-workflow` owns one routine, bounded modernization lifecycle.
Program-scale means any large, cross-cutting, or unattended run, including
multiple independent cutovers, repositories, systems, or teams. Route
program-scale modernization to `figure-it-out` before writes. Use
`software-engineering` to shape repository-wide architecture inside that owner.

Treat source edits, local commits, package publication, production migration,
cutover, and rollback execution as separate authority. A code or commit grant
does not authorize an external cutover.

## Freeze the Compatibility Contract

Inventory before translation. Use small fact-finding workers for independent
inventories. Keep contract synthesis and cutover judgment with the lifecycle
owner.

Express the observable contract as a compatibility matrix. Add these rows when
they exist:

- observable behavior and error semantics;
- public API, CLI, protocol, and configuration contracts;
- persisted data, serialization, schema, and migration versions;
- build, package, install, upgrade, and developer workflows;
- runtime, deployment, monitoring, and operational signals;
- controlled callers and external consumers;
- supported platforms, toolchain versions, and performance limits.

For each row, name the current evidence, target contract, allowed difference,
owner, and parity check. Capture the baseline on the legacy implementation. A
test that never observes the old path cannot prove old-to-new parity.

## Shape the Migration

Define target module boundaries and dependency direction before code. Use
`architect` for a non-trivial boundary change. Separate these concerns:

1. verification scaffold and baseline;
2. target scaffold that stays green alone;
3. mechanical translation or generated conversion;
4. deliberate behavior change;
5. caller or data migration;
6. authorized cutover;
7. post-cutover stabilization evidence on the target path;
8. legacy deletion after stabilization evidence.

Apply expand-migrate-contract from `engineering-principles`. Move controlled
callers in bounded green slices. After each slice, mechanically recount remaining
legacy references. Keep modernization cutover, post-cutover stabilization, and
legacy deletion as separate green ordered slices. Do not delete the legacy path
until stabilization evidence passes and the rollback boundary remains viable.
Build a rerunnable lever for repetitive edits, but inspect and verify every
produced slice.

An adapter, feature flag, shadow path, or dual write needs a named owner, removal
condition, and bounded lifetime. It is migration scaffolding, not a second
permanent architecture. Keep mechanical translation and behavior change in
separate slices. If one cannot remain green alone, one slice may contain both
only with separate compatibility-matrix entries, checks, and reviewer verdicts.

## Prove and Cut Over

Run old and new paths against identical fixtures at their observable boundaries.
Classify each difference as required, allowed, or a defect. Compilation and unit
tests alone do not prove semantic parity.

Verify the relevant build, package, install, upgrade, integration, and operator
paths. Make data and activation operations idempotent and resumable. Run each
applicable operation twice and prove the second run converges without another
effect.

Before an authorized cutover, prove rollback from the last durable checkpoint.
A backup is not rollback evidence until restoration works. Define the stop signal
and decision owner before changing traffic, data, publication, or production
state.

## Completion

Complete the bounded modernization only when:

- the compatibility matrix has no unexplained difference;
- all controlled consumers use the target path;
- the target is the sole supported path in scope;
- tests, CI, docs, development, packaging, and release paths use the target;
- cutover succeeds and stabilization evidence passes before legacy deletion;
- obsolete adapters, flags, dependencies, files, and legacy code are deleted in
  a later green slice;
- a mechanical search reports no unexpected remaining legacy references;
- cutover and rollback evidence identifies every external action not yet run.

If an external consumer forces a deprecation window, record its owner, deadline,
and removal condition beside the compatibility boundary. Do not report legacy
removal complete while that exception remains.
