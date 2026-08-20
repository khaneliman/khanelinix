# Make Operations Idempotent

Design every mutating operation to converge on the same state when it runs
twice. Repeat the run and expect no additional effect.

**Why:** Activation scripts, migrations, installers, and hooks rerun after
retries, crashes, and rebuilds. An operation that assumes a clean start fails on
the second run, or silently doubles its effect. Convergent operations make
retries safe and make recovery boring.

**Pattern:**

- Declare the target state. Do not script a delta from an assumed start state.
- Detect already-applied state before mutating. Skip the write when the state
  already matches.
- Use create-or-update writes instead of create-only writes.
- Give each externally visible effect a stable key. A retry then replaces the
  earlier attempt instead of appending a second one.
- Keep append-only side effects out of a retried path, or deduplicate them by
  that key.
- Separate a one-time migration from the convergent path it feeds. Guard the
  migration with a recorded version marker.

**Proof:** Run the operation twice against the same starting state. Compare the
resulting state and the changes each run reports. A convergent operation reports
no changes on the second run.
