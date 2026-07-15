# Bevy Lifecycle and Scheduling

## State Choice

- Use states for coarse application modes with distinct schedules and
  lifecycles.
- Use components/resources for orthogonal, nested, or per-entity state.
- Keep transition requests separate from transition application. Test duplicate,
  same-state, early, and conflicting requests.
- Derive APIs from the locked Bevy release; state transition hooks and messages
  change across versions.

## Setup and Teardown

- Make entry and exit symmetric. Track spawned roots, state-scoped entities,
  tasks, audio, observers, temporary assets, and remote-control requests.
- Prefer release-appropriate state-scoped entities when state owns lifetime.
  Otherwise use marker components and explicit `OnExit` cleanup.
- Audit despawn observers and relationship hooks during transitions. Teardown
  side effects can mutate resources needed by the next state.
- Clean up only entities/resources owned by the exiting domain. Broad queries
  make parallel plugin ownership fragile.
- Prove repeated entry after teardown, not only first entry from startup.

## System Sets and Ordering

- Let ECS access conflicts express ordinary parallelism.
- Add explicit ordering only for semantic dependencies the scheduler cannot
  infer, such as input sampling before intent, simulation before presentation,
  or request handling before readback.
- Name coarse system sets instead of chaining many individual systems.
- Put cross-domain ordering in one integration plugin.
- Use schedule graphs to prove ordering/conflicts; use runtime profiling to
  prove cost. Graph shape alone is not performance evidence.

## Deferred Work

- Know when commands apply relative to later systems, observers, state changes,
  and extraction/render schedules.
- Add explicit command-application boundaries only when same-schedule visibility
  is required and tested.
- Do not assume a spawned/removed component is visible to every later-looking
  system merely because source order suggests it.

## Events, Messages, and Observers

- Use buffered messages/events for decoupled fan-out and temporal buffering.
- Configure writer/reader order when one-frame latency is incorrect.
- Use observers/triggers for targeted or immediate reactions when supported by
  the locked release and re-entrancy is acceptable.
- Keep observer side effects narrow; immediate cascades can obscure lifecycle
  ownership and mutate entities during teardown.
- Gate event-only systems when idle cost is measured and meaningful, not by
  habit.

## Deterministic Tests

- Construct a minimal `App` with only owning plugins and required schedules.
- Advance schedules explicitly and inspect world state.
- Test setup, transition, teardown, repeated entry, and cancellation/shutdown.
- Use request IDs/session IDs for asynchronous runtime probes so stale
  completion cannot satisfy a newer assertion.
- Assert stable lifecycle/state contracts. Avoid exact frame counts or ordering
  between independent systems unless product behavior requires them.
