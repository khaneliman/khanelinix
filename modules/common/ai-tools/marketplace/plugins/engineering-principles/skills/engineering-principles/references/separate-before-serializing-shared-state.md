# Separate Before Serializing Shared State

When several writers contend for one piece of shared state, give each writer its
own state first. Add locks or queues only after separation fails.

**Why:** Serializing access to a merged value preserves the contention it
manages. A lock also binds only the writers inside your process boundary, so an
external writer still takes the same slot. Disjoint state removes the race
instead of scheduling it. It needs no lock lifetime, no cancellation design, and
no deadlock analysis.

**Pattern:**

- Ask what each writer owns. Contention over one slot is often two owners
  sharing a name.
- Give each owner a stable identity, then key its state by that identity.
- Compose disjoint parts into the shared view at read time. Do not merge them at
  write time and reconstruct owners later.
- Read an authoritative value directly when one exists. Do not poll a
  last-writer cache that any process can overwrite.
- Record the residual limitation when a single-slot resource is external and
  cannot be partitioned.

**Cost of skipping this:** A lock over a single-slot shared resource needs
cancellation semantics, lock lifetime, and failure recovery. That design is
larger than the separation it replaces, and it still loses to a writer outside
your boundary.
