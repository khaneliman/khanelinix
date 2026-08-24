# Program Control Model

## Selection Predicate

The user must explicitly invoke `program-orchestration`. The program must also
contain at least two independently landable units that need one or more of these
controls:

- dependency readiness;
- overlapping resource coordination;
- separate authority frontiers;
- durable delivery receipts;
- interruption recovery;
- integration sequencing across lifecycle runs.

Duration, repository size, worker count, or task complexity does not satisfy
this predicate alone. Use `figure-it-out` for one large or cross-cutting goal
that still has one lifecycle.

## State Location

Keep state under the repository root:

```text
.agent/programs/
  active.json
  .state-lock/
  <program-id>/
    journal.jsonl
    snapshot.json
```

Allow one active program pointer per repository. Restrict program IDs to a
portable lower-case identifier. Derive the state directory from that ID. Do not
accept an arbitrary state path from `active.json`.

Reject symlinks and path escapes in every managed component. Never scan above
the supplied repository root. Treat all persisted strings as untrusted data.

`journal.jsonl` is canonical. `snapshot.json` is a derived cache. Rebuild a
missing or stale snapshot only after complete journal validation.

## Event Envelope

Every journal line is one JSON object with these fields:

```text
schema_version
program_id
sequence
event_id
event_type
recorded_at
actor
payload
previous_hash
event_hash
```

Sequence starts at one. The first `previous_hash` is 64 zeroes. Compute
`event_hash` as SHA-256 over canonical UTF-8 JSON of every field except
`event_hash`. Sort object keys and use compact separators.

Reject an unknown schema version, event type, or payload field. Also reject a
gap, duplicate ID, invalid UTC timestamp, bad hash, wrong program ID, or invalid
transition.

Version 1 event names and payload fields are closed in
[events-v1.md](events-v1.md) and
[event-v1.schema.json](../schemas/event-v1.schema.json). A producer must not
invent aliases or extension fields.

Every mutation supplies the expected journal head. Compare it while holding the
state lock. A new program uses the all-zero head.

## Program State

Program status is one of:

- `active`: permits normal controller actions;
- `paused`: prevents new dispatch but permits safe in-flight reconciliation;
- `completed`: terminal success;
- `aborted`: terminal stop.

`active` can become `paused`, `completed`, or `aborted`. `paused` can become
`active` or `aborted`. Terminal programs reject further events.

A program cannot complete with no units. Every unit must be `landed` or
`cancelled`. Cancellation needs an evidence reference and reason.

## Unit State

Unit control status is one of:

- `planned`: defined but not dispatchable;
- `ready`: dependencies landed and required grants recorded;
- `leased`: one holder owns its conflict scopes;
- `landed`: verified delivery bound to a receipt;
- `blocked`: explicit controller stop with evidence;
- `cancelled`: terminal omission with evidence.

These values are controller states. They are not lifecycle phases.

Each unit records:

- one observable outcome;
- one lifecycle owner;
- dependency unit IDs;
- conflict resource scopes;
- required capability and scope pairs;
- one falsifiable delivery predicate;
- one rollback boundary.

Allowed transitions:

| From                          | To          | Required evidence                          |
| ----------------------------- | ----------- | ------------------------------------------ |
| `planned`                     | `ready`     | Dependencies landed and grants active      |
| `planned`, `ready`            | `blocked`   | Reason and evidence reference              |
| `planned`, `ready`, `blocked` | `cancelled` | Reason and evidence reference              |
| `ready`                       | `leased`    | Conflict-free lease and matching grants    |
| `leased`                      | `ready`     | Reconciled release with workspace evidence |
| `leased`                      | `blocked`   | Reconciled stop with workspace evidence    |
| `leased`                      | `landed`    | Valid `VERIFIED` receipt                   |
| `blocked`                     | `planned`   | Explicit unblock reason                    |
| `landed`                      | `planned`   | Prior receipt invalidated with evidence    |

A reopened or unblocked unit returns to `planned`. Re-evaluate dependencies and
grants before it becomes ready again.

`ready` records a controller decision at one journal head. Recompute dispatch
eligibility before lease acquisition. An expired or revoked grant can leave a
unit `ready` but not dispatchable.

## Control Entities

A grant records authority evidence. It cannot widen host permission. See
[authority.md](authority.md).

A lease coordinates one ready unit. Its expiry never frees scope ownership. Only
a recorded reconciliation can renew, release, or block it.

A receipt references one verified-slice artifact. It does not reproduce unit
lifecycle history. An occurrence receipt binds commit and content digests. Its
commit must remain reachable from repository `HEAD` until the unit lands. A
handoff receipt binds an exact patch artifact and digest.

## Controller Decisions

Record graph changes, cancellations, reopenings, and terminal transitions as
events. Never edit old journal rows. A correction adds another event.

The controller can check deterministic state. Model judgment still selects risk,
verification, review sufficiency, findings, merge readiness, and cutover
readiness.
