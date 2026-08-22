# Migrate Callers Then Delete Legacy APIs

When you replace an API in a bounded change, migrate every caller and delete the
old path together. Do not leave both paths live without a bounded migration.

**Why:** A surviving legacy path doubles the surface every later change must
satisfy. Callers keep selecting the old path, behavior drifts between the two,
and the deletion never gets scheduled. Deleting with the migration also keeps
the change reviewable, because the diff shows the complete new call graph.

**Pattern:**

- Pin current behavior before restructuring. Capture the observable contract
  callers depend on.
- Find every caller mechanically. Trust a search across the whole tree, not
  memory.
- Convert the old entry point into a thin adapter over the new one while you
  migrate. Delete the adapter in the same change.
- Prove equivalence at the boundary callers see, not at the internals you
  rewrote.
- Split the mechanical caller migration from any behavior change. Keep one
  concern per reviewable unit.

**For a wide refactor, use expand-migrate-contract:**

1. **Expand:** Add the new path and one compatibility adapter. Pin boundary
   parity before callers move.
2. **Migrate:** Move callers in bounded green batches. After each batch, run its
   focused check and mechanically recount remaining legacy callers.
3. **Contract:** Delete the adapter and old path when no controlled caller
   remains. Run the full boundary check after deletion.

This exception changes commit shape, not completion. Keep the migration in one
tracked stack with a named removal condition. Do not mix behavior changes into
mechanical caller batches.

**When staged removal is unavoidable:** A consumer you do not control can force
a deprecation window. Record the removal condition and owner beside the legacy
path. An unconditional "remove later" comment is not a plan.

## Attribution

The expand-migrate-contract sequence is adapted from Matt Pocock's
`implement` skill. Prose is original. Upstream terms are in
[LICENSE-matt-pocock.txt](../LICENSES/LICENSE-matt-pocock.txt).
