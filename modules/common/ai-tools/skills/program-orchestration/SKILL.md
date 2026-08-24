---
name: program-orchestration
description: "Explicit durable control overlay for multiple independently landable work units. Use only when the user names $program-orchestration or directly asks to orchestrate a program with dependencies, leases, grants, receipts, and recovery. Existing workflow skills still own each unit."
---

# Program Orchestration

Use this skill only after explicit user invocation. It coordinates a program of
independently landable units. It does not implement, verify, review, or commit a
unit.

## Ownership Boundary

- This skill owns program state, dependencies, grants, leases, receipts,
  integration frontiers, and recovery.
- Each unit names one existing lifecycle owner. That owner keeps its full
  investigation, design, implementation, verification, review, and correction
  contract.
- `engineering-workflow` owns routine bounded mutation. `figure-it-out` owns a
  large single-goal lifecycle. This skill can coordinate several such units.
- `verified-slice` evidence remains authoritative for unit delivery.

## Load References on Demand

- Read [control-model.md](references/control-model.md) before creating units or
  changing program state.
- Read [events-v1.md](references/events-v1.md) before writing or validating a
  journal event.
- Read [authority.md](references/authority.md) before recording grants or
  opening a delivery frontier.
- Read [recovery.md](references/recovery.md) after interruption, corruption, an
  expired lease, or an uncertain writer outcome.
- Read [hook-contract.md](references/hook-contract.md) before adding provider
  context hooks.

## Start

1. Confirm explicit invocation and at least two independently landable units.
2. State one falsifiable program goal and one observable outcome per unit.
3. Give each unit one lifecycle owner, dependencies, resource scopes, required
   capabilities, predicate, and rollback boundary.
4. Record only authority the user granted and the host permits. Starting a
   program grants nothing.
5. Freeze the initial unit graph before dispatch. Add later units through a
   recorded controller decision.

## Control Loop

1. Validate the full journal and compare the expected head before each write.
2. Mark a unit ready only after every dependency lands.
3. Acquire one conflict-free lease with active matching grants.
4. Dispatch the leased unit to its named lifecycle owner with bounded scope and
   exit criteria.
5. Accept only a verified-slice receipt. Bind occurrence delivery to the
   committed digest, or bind handoff delivery to the exact patch digest.
6. Land the unit only when receipt evidence is `VERIFIED`.
7. Reconcile interrupted or expired leases before another holder can use their
   scopes.
8. Complete the program only after every unit lands or has an evidenced
   cancellation.

## Hard Stops

- Never select this skill because work is merely long, large, or delegated.
- Never infer a grant from workflow selection, a lease, or successful tool use.
- Never let a hook choose a model, skill, lifecycle owner, worker, or
  permission.
- Never break a stale lock or repair an invalid journal automatically.
- Never treat a program receipt as a replacement for unit evidence.
