# Program Recovery

## Recovery Invariants

- Keep `journal.jsonl` canonical.
- Never truncate, reorder, rewrite, or skip an invalid journal row.
- Never trust `snapshot.json` until its head matches a complete valid replay.
- Never break `.state-lock` because its PID is absent or its age is high.
- Never transfer an expired lease without workspace inspection.
- Keep inspection separate from mutation.

## Atomic Writer

Use one repository program lock at `.agent/programs/.state-lock`. The lock
directory contains a random token, PID, host, and UTC creation time.

Create the lock directory atomically. Normal exit removes it only when the token
still matches. A writer must not follow symlinks in the managed state path.

While holding the lock:

1. validate the complete journal and derived state;
2. compare the supplied expected head;
3. apply one validated event in memory;
4. write the complete new journal to a same-directory temporary file;
5. flush and fsync the file;
6. atomically replace the journal;
7. fsync the directory when the platform supports it;
8. write and replace the derived snapshot by the same method.

Journal replacement succeeds before snapshot replacement. If snapshot writing
fails, report failure and leave the valid journal as the recovery source.

Initialization writes a valid journal and snapshot before `active.json`.
Replacing a terminal active pointer with a new program requires a deliberate
initialization action under the same lock.

## Read-Only Recovery Plan

A recovery plan validates and reports:

- current journal head and first invalid row, if any;
- snapshot absence, staleness, or invalid content;
- active pointer absence or mismatch;
- lock token, owner metadata, and observed age;
- orphan same-directory temporary files;
- active expired leases and their conflicting scopes;
- interrupted delivery whose journal outcome is uncertain.

The plan proposes only deterministic actions. It does not perform them. It must
label any journal corruption as manual recovery.

## Recovery Apply

Apply one selected action. Require the journal head and every observed identity
that protects the action.

Allowed actions:

- remove an explicitly selected orphan temporary file;
- rebuild a snapshot from a complete valid replay;
- restore `active.json` to an existing validated program;
- remove a stale lock only when the caller supplies its exact token and records
  external evidence that no writer remains;
- reconcile an expired lease through a normal journal event.

Recovery apply never modifies journal history. A stale-lock removal changes only
the lock directory. After removing it, reacquire a new lock for any state write.

If the expected head, lock token, file identity, or active program changes, stop
and generate a new recovery plan.

## Interrupted Write Cases

| Observed state                          | Action                                           |
| --------------------------------------- | ------------------------------------------------ |
| Old journal, orphan temporary journal   | Remove selected temporary file                   |
| New valid journal, old snapshot         | Rebuild snapshot                                 |
| New program journal, old active pointer | Restore pointer after validation                 |
| Invalid journal                         | Stop for manual forensic recovery                |
| Existing lock with uncertain writer     | Stop and obtain external evidence                |
| Expired active lease                    | Inspect workspace, then renew, release, or block |

When a command outcome is uncertain, validate the head and search by event ID.
Retry only when the intended event is absent and the expected head still
matches.
