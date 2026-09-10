---
name: to-tickets
description: "Split a spec into self-contained tickets with dependencies."
license: Complete terms in LICENSE
disable-model-invocation: true
metadata:
  khanelinix-invocation-mode: "user-only"
---

# To Tickets

Use only after the user explicitly invokes this skill. Decompose a saved spec,
plan, or the current conversation into local, self-contained implementation
tickets. This skill drafts tickets; it does not execute them.

## Source and readiness

1. Read the supplied spec or plan and relevant repository guidance. If the
   source exists only in conversation, save a local spec snapshot first under
   `.planning/<feature>/spec.md`; do not invoke `$to-spec` automatically.
2. Preserve a resolvable source path or link, source identity, and revision in
   every ticket. Mark a ticket `ready` only when its prerequisites are verified
   complete and its material choices are settled; otherwise mark it `blocked`.
   Include an `Unresolved choices` field and never invent a decision to make a
   ticket appear ready.
3. Use an existing project convention or requested location when one exists.
   Otherwise write tickets to `.planning/<feature>/tickets/NN-slug.md`. Preserve
   unrelated snapshots and ticket files. On reruns, reuse matching tickets and
   IDs. Update task-owned drafts only when authorized; preserve unrelated and
   completed work. Allocate new IDs only for genuinely new slices. When the spec
   revision changes, flag affected tickets for revalidation before they are
   ready.

## Decompose and write

1. Create vertical, independently verifiable slices. Use an expand-contract
   sequence only when compatibility requires it.
2. Give every ticket a unique stable ID and an acyclic dependency graph. Every
   dependency reference must resolve either to a ticket in this set or to an
   existing external prerequisite ticket with a resolvable path or link.
3. No blocker does not make conflicting work safe to run simultaneously. Shared
   files, interfaces, contracts, migrations, or integration surfaces require
   serialized writes, or isolated worktrees followed by a named integration
   owner and explicit integration order. An integration ticket alone is not
   sufficient.
4. Add an integration verification ticket when behavior crosses slice
   boundaries. Use [ticket-template.md](references/ticket-template.md) for every
   ticket and read each saved ticket back for completeness. Ensure every ticket
   fits one fresh session; split a slice that needs more context or work.

Each ticket must state its source spec revision, objective and non-goals,
acceptance criteria, constraints and interfaces, blocker ticket IDs, write scope
hints to verify at implementation time, exact verification commands or checks
with expected evidence, and a fresh-session instruction routing the work to
`engineering-workflow` or the project’s existing lifecycle owner.

## Authority and publication

- Stop after drafting unless the next action is separately authorized. If
  execution, commits, publication, deployment, or activation are explicitly
  authorized, route execution to the existing project owner; this skill does not
  take over that lifecycle. Do not add a redundant approval gate for local
  drafts.
- Publish only when the user requests it. Use `github-toolkit` for GitHub, or an
  available tracker tool for another requested tracker. Preserve the local
  tickets and record publication identifiers after readback. Do not close or
  modify a parent issue as a side effect of ticket publication.
