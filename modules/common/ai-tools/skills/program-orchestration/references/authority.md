# Program Authority

## Intersection Rule

A recorded grant is usable only while both conditions hold:

1. the user granted the capability for the recorded scope;
2. the current host permits the intended action.

The journal proves only what the controller recorded. It cannot prove current
host permission. Recheck host permission at action time. Fail closed when either
condition is unknown, expired, or revoked.

## Capabilities

Use these separate capabilities:

| Capability        | Frontier                             |
| ----------------- | ------------------------------------ |
| `workspace-read`  | Read files inside scope              |
| `workspace-write` | Change files inside scope            |
| `local-commit`    | Create a local commit                |
| `git-push`        | Update a remote Git ref              |
| `github-write`    | Change issue, review, or check state |
| `pull-request`    | Create or update a pull request      |
| `merge`           | Merge a reviewed change              |
| `publish`         | Publish a package or artifact        |
| `release`         | Create or promote a release          |
| `deploy`          | Change a running environment         |
| `cutover`         | Move users or traffic to a new path  |

Do not infer one capability from another. In particular, `workspace-write` does
not imply `local-commit`, and `git-push` does not imply `pull-request` or
`merge`.

## Grant Record

Each grant contains:

```text
grant_id
capability
scope
issuer
evidence_ref
granted_at
expires_at
revoked_at
revocation_reason
```

Use one capability and one scope per grant. Scope matching is exact or
hierarchical on a slash boundary. A parent scope covers descendants. A sibling
prefix does not match.

Record an expiry only when the user supplied one. Expired and revoked grants
remain in history but cannot authorize readiness, leasing, or delivery.

Revocation affects new actions immediately. It does not erase prior events. If
revocation affects an active lease, reconcile that lease before further work.

## Lease Record

Each lease contains:

```text
lease_id
unit_id
holder
resource_scopes
grant_ids
base_commit
acquired_at
expires_at
status
```

Acquisition requires all of these conditions:

- program status is `active`;
- unit status is `ready`;
- every dependency is `landed`;
- selected grants satisfy every required capability and scope;
- no unresolved lease has an overlapping resource scope;
- the base commit matches the unit dispatch boundary.

Treat scopes as overlapping when either scope equals the other or contains it on
a slash boundary. Keep opaque remote scopes distinct from repository path
scopes.

Lease status is `active`, `released`, `landed`, or `blocked`. Time expiry is a
condition on an active lease, not a status transition. An expired lease still
owns its scopes until reconciliation records one outcome:

- renew with a new expiry and workspace evidence;
- release to return the unit to `ready`;
- block to move the unit to `blocked`.

Never transfer a lease automatically. A new holder needs a new lease after
reconciliation.

## Delivery Frontiers

The unit lifecycle owner produces evidence. The controller only validates
receipt shape and recorded predicates.

For occurrence delivery, require:

- commit SHA and parent SHA;
- staged content digest and committed content digest;
- explicit digest equality;
- verified-slice artifact reference and `VERIFIED` verdict.

For handoff delivery, require an exact patch artifact reference, patch digest,
and `VERIFIED` verdict. A handoff can satisfy a unit predicate but grants no
commit, push, pull-request, merge, publish, release, deploy, or cutover
authority.

Keep code delivery, remote publication, merge, deployment, and cutover as
separate controller events and grants.
