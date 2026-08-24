# Program Events Version 1

Use schema version `1`. The machine-readable contract is
[event-v1.schema.json](../schemas/event-v1.schema.json).

The schema closes the event envelope, event names, payload fields, primitive
types, identifier shapes, capability names, and enumerated outcomes. A producer
must not add extension fields. A later contract needs a new schema version.

## Events

| Event                         | Required payload                                                                                                                                                         | Optional payload |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------- |
| `program_initialized`         | `goal`, `base_commit`                                                                                                                                                    | None             |
| `unit_added`                  | `unit_id`, `outcome`, `owner`, `dependencies`, `resource_scopes`, `required_capabilities`, `predicate`, `rollback`                                                       | None             |
| `unit_readied`                | `unit_id`                                                                                                                                                                | None             |
| `unit_blocked`                | `unit_id`, `reason`, `evidence_ref`                                                                                                                                      | None             |
| `unit_unblocked`              | `unit_id`, `reason`                                                                                                                                                      | None             |
| `unit_cancelled`              | `unit_id`, `reason`, `evidence_ref`                                                                                                                                      | None             |
| `grant_recorded`              | `grant_id`, `capability`, `scope`, `issuer`, `evidence_ref`                                                                                                              | `expires_at`     |
| `grant_revoked`               | `grant_id`, `reason`                                                                                                                                                     | None             |
| `lease_acquired`              | `lease_id`, `unit_id`, `holder`, `resource_scopes`, `grant_ids`, `base_commit`, `expires_at`                                                                             | None             |
| `lease_renewed`               | `lease_id`, `expires_at`, `evidence_ref`                                                                                                                                 | None             |
| `lease_reconciled`            | `lease_id`, `outcome`, `reason`, `evidence_ref`                                                                                                                          | None             |
| `occurrence_receipt_recorded` | `receipt_id`, `unit_id`, `lease_id`, `base_commit`, `content_digest`, `evidence_verdict`, `artifact_ref`, `commit_sha`, `parent_sha`, `committed_digest`, `digest_match` | None             |
| `handoff_receipt_recorded`    | `receipt_id`, `unit_id`, `lease_id`, `base_commit`, `content_digest`, `evidence_verdict`, `artifact_ref`                                                                 | None             |
| `receipt_invalidated`         | `receipt_id`, `reason`, `evidence_ref`                                                                                                                                   | None             |
| `unit_landed`                 | `unit_id`, `receipt_id`                                                                                                                                                  | None             |
| `unit_reopened`               | `unit_id`, `receipt_id`, `reason`, `evidence_ref`                                                                                                                        | None             |
| `program_paused`              | `reason`                                                                                                                                                                 | None             |
| `program_resumed`             | `reason`                                                                                                                                                                 | None             |
| `program_completed`           | `evidence_ref`                                                                                                                                                           | None             |
| `program_aborted`             | `reason`, `evidence_ref`                                                                                                                                                 | None             |

## Closed Values

Capabilities are `workspace-read`, `workspace-write`, `local-commit`,
`git-push`, `github-write`, `pull-request`, `merge`, `publish`, `release`,
`deploy`, and `cutover`.

Evidence verdict is `VERIFIED`, `NOT_VERIFIED`, or `INCONCLUSIVE`.
`lease_reconciled.outcome` is `released` or `blocked`.

Version 1 text, reference, and scope values exclude control characters. Arrays
have no schema item limit. Replay preserves those published acceptance rules.

The current producer profile also requires outer-whitespace-free text, canonical
relative hierarchical scopes, and at most 256 array items. The state engine
requires duplicate-free lexical ordering for dependency, scope, grant ID, and
capability arrays. JSON Schema cannot express lexical ordering, so replay
validation enforces it.

## Transition Notes

- `unit_added` dependencies must already exist. Add units in topological order.
- `unit_readied` rechecks landed dependencies and active matching grants.
- `grant_revoked` never erases prior use. It prevents new actions.
- `lease_renewed` keeps the same holder and scopes.
- `lease_reconciled` closes an active lease as released or blocked.
- Receipt events can record any evidence verdict. Only `VERIFIED` evidence can
  support `unit_landed`.
- `unit_landed` requires an occurrence commit that still resolves and remains
  reachable from repository `HEAD`. Another unit can commit first.
- `receipt_invalidated` precedes `unit_reopened`.
- Program terminal events reject every later event.
