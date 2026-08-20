# Migrate Callers Then Delete Legacy APIs

When you replace an API, migrate every caller and delete the old path in the
same change. Do not leave both paths live.

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

**When staged removal is unavoidable:** A consumer you do not control can force
a deprecation window. Record the removal condition and the owner beside the
legacy path. An unconditional "remove later" comment is not a plan.
