# Program State Tool

The state tool uses Python 3.11 or newer, standard-library modules, and Git. It
writes under the supplied repository root.

```sh
python3 <skill-dir>/scripts/program_state.py --help
```

Every success response is one JSON object on stdout. Every deterministic error
is one JSON object on stderr with exit status `2`.

## Initialize

Use the current full Git object ID. Initialization replaces an active pointer
only when its prior program is terminal.

```sh
python3 <skill-dir>/scripts/program_state.py init REPO \
  --program-id migration-2026 \
  --goal "Move both services to the new API." \
  --base-commit FULL_SHA \
  --actor controller \
  --event-id init-001
```

Initialization creates no grant. Add units in topological order through
`record`.

## Read

```sh
python3 <skill-dir>/scripts/program_state.py status REPO
python3 <skill-dir>/scripts/program_state.py validate REPO \
  --program-id migration-2026 \
  --event-id unit-api-001
```

`status` reports snapshot condition, expired active leases, and currently
dispatchable ready units. It does not mutate state. `validate` replays the full
journal and reports its head. With `--event-id`, it also reports whether the
stable event exists and identifies its sequence and hash.

## Record One Event

Write one payload JSON object to a file. Use an explicit event ID so uncertain
command recovery can find the event before retry.

```sh
python3 <skill-dir>/scripts/program_state.py record REPO \
  --program-id migration-2026 \
  --expected-head JOURNAL_SHA256 \
  --event-type unit_added \
  --actor controller \
  --event-id unit-api-001 \
  --payload-file /tmp/unit-api.json
```

The writer acquires the repository program lock, validates the full journal,
compares the expected head, applies one event, replaces the journal, then
replaces the snapshot. It rejects a lease base that differs from repository
`HEAD`. It verifies an occurrence commit's parent against local Git history. The
occurrence commit must remain `HEAD` until the unit lands.

Use [events-v1.md](events-v1.md) for payload fields. Arrays must be
duplicate-free and lexically sorted. Required capability objects sort by
`capability`, then `scope`.

## Recover

Start with read-only inspection:

```sh
python3 <skill-dir>/scripts/program_state.py recover-plan REPO \
  --program-id migration-2026
```

Apply only one returned action. Every action binds the observed journal head.

```sh
python3 <skill-dir>/scripts/program_state.py recover-apply REPO \
  --program-id migration-2026 \
  --expected-head JOURNAL_SHA256 \
  --action rebuild-snapshot
```

`remove-temp` also requires the exact relative path and file digest.
`remove-lock` also requires the exact lock token and an external evidence
reference that no writer remains. Recovery never edits journal bytes.

Reconcile an expired lease with a normal `lease_reconciled` event after
workspace inspection. Do not use recovery actions to transfer its scopes.
