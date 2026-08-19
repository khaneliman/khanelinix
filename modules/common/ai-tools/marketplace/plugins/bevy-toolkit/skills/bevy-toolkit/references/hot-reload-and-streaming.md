# Bevy Hot Reload and Streamed Worlds

Use this route when disk-backed assets, serialized worlds, or Rust systems may
change while spatial chunks load and unload. Confirm locked Bevy version and
repository launcher before selecting APIs.

## Contents

- Separate reload boundaries
- Gate APIs by release
- Own chunk lifecycle
- Separate model from replaceable view
- Promote reloads transactionally
- Hotpatch system logic carefully
- Stress the intersections

## Separate Reload Boundaries

| Change                                                | Mechanism                                                   | Preserve explicitly                                |
| ----------------------------------------------------- | ----------------------------------------------------------- | -------------------------------------------------- |
| Texture, shader, audio, custom asset data             | `AssetServer` plus release-appropriate watcher              | handle ownership and downstream readiness          |
| Serialized world, scene, or hierarchy                 | release-appropriate instance spawner or project transaction | stable model host and runtime deltas               |
| Rust function body                                    | first-party hotpatching when supported                      | existing world and compatible function/type layout |
| System signature, ECS type shape, plugin, or schedule | rebuild/restart or explicit schema migration                | persisted domain state through a tested migration  |

Do not call faster dynamic linking code hot reload. `dynamic_linking` can reduce
development link cost; live function replacement needs a hotpatch runtime.

## Gate APIs by Release

- Enable desktop asset watching with the locked release's watcher feature,
  commonly `file_watcher`; inspect `AssetPlugin` overrides and custom asset
  sources. Keep watcher and hotpatch features development-only by default.
- Read `AssetEvent<T>` through the release-appropriate buffered reader. On
  current Bevy it is a `Message`, not an observer-triggered `Event`. Adapt it to
  a project-owned targeted event only when reactive fan-out benefits.
- On Bevy 0.18, tracked `Scene` and `DynamicScene` instances are automatically
  despawned and recreated by `SceneSpawner` after asset modification. Do not add
  a second generic respawner unless replacing native ownership deliberately.
  Keep durable state outside that fully replaced instance, or take exclusive
  ownership of a custom transactional replacement path.
- On Bevy 0.19, legacy serialized-world APIs moved to
  `bevy_world_serialization`: `WorldAsset`, `DynamicWorld`,
  `WorldInstanceSpawner`, and `WorldInstanceReady` replace old scene names.
  Check that spawner's built-in watched-asset behavior before adding a custom
  modified-asset replacement path.
- On Bevy 0.19, `queue_spawn_scene` belongs to the new dependency-aware
  `Scene`/BSN pipeline. The release has code-driven BSN, but no first-party
  `.bsn` asset loader or glTF-to-BSN integration. Do not mix this path with
  `.scn.ron` or glTF world-instance APIs.

Treat asset I/O and dependency preparation as asynchronous, not ECS insertion.
Queued scenes/worlds still materialize entities in engine schedules; budget
large hierarchy promotion across frames or use project-owned staged spawning.

## Own Chunk Lifecycle

Represent each chunk with a stable `ChunkId`, source revision, request
generation, and explicit state such as `Absent`, `Requested`, `Pending`,
`Active`, and `Retiring`.

- Derive desired chunks from deterministic spatial coordinates. Use separate
  load and unload radii so boundary jitter does not thrash chunks.
- Bound concurrent I/O, prepared candidates, and per-frame entity/component
  insertion. Prioritize by gameplay need, not completion race.
- Include chunk ID, generation, source revision, and owning app/session in every
  asynchronous result. Reject stale completion after movement, reload, state
  exit, or a newer request.
- Cancel work where supported. Otherwise let it complete under tracked ownership
  and reject its stale result; do not detach blindly. Drop task-owned strong
  handles when work ends so abandoned chunks can leave asset storage.
- Keep one chunk root as lifecycle owner. Despawn only its owned subtree and
  verify relationship cleanup, observers, physics, navigation, audio, and
  extracted render state.

## Separate Model from Replaceable View

- Keep persistent gameplay identity and mutable domain state on stable model
  entities keyed by domain IDs. Never persist raw `Entity` values; remap saved
  IDs and validate missing targets after load.
- Put imported geometry, materials, effects, and other regenerated presentation
  beneath a replaceable view root. Decide explicitly whether collision,
  navigation, and scripts are durable model state or revision-owned derived
  data.
- Treat save plugins and `Save`/`Unload`-style markers as implementations of
  this boundary, not the boundary itself. Verify exact Bevy compatibility and
  recursive unload semantics before adopting one.
- Rebind the promoted view to surviving model state. Never restore authored
  defaults over harvested resources, opened containers, damage, inventory, or
  quest changes merely because presentation reloaded.

## Promote Reloads Transactionally

1. Map changed asset IDs or authoring revisions to affected chunk owners.
2. Start one generation-stamped candidate per owner; coalesce duplicate watcher
   messages and supersede older work.
3. Load dependencies and validate schema, stable IDs, references, ownership,
   bounds, and target compatibility without mutating the active chunk.
4. Build a tagged pending subtree behind gameplay gates and within structural
   work budgets.
5. Run post-spawn setup through the release-appropriate readiness trigger or an
   explicit project stage. Make physics/navigation/script setup idempotent.
6. At one known schedule boundary, promote the candidate, rebind model state,
   and retire the previous owned view.
7. Drop old handles, tasks, observers, caches, and derived resources. On any
   failure, destroy the pending candidate and release everything it owns before
   retaining last-known-good active state and reporting source diagnostics.

Use required components or narrow component hooks for intrinsic local
invariants. Use observers for targeted ready/lifecycle reactions. Keep both
small: hooks are synchronous lifecycle behavior, while observer cascades can be
re-entrant. Do not mutate `Assets<T>` merely to acknowledge a modification; that
can emit another modification and create a reload loop.

## Hotpatch System Logic Carefully

- Prefer Bevy's first-party `hotpatching` path when the locked release supports
  it, then verify its required Subsecond/Dioxus launcher and target constraints.
- Treat changed function signatures, system parameters, component/resource
  layout, plugin registration, and schedule topology as restart or explicit
  migration boundaries unless a tested tool documents otherwise.
- Evaluate third-party hotpatch crates only through the ecosystem-selection
  workflow. Reproduce latency claims in the real workspace; do not copy headline
  sub-second numbers or stale compatibility tables into architecture.
- After every hotpatch session, rerun a cold start. Hot state must not conceal
  missing initialization, registration, migration, or teardown.

## Stress the Intersections

- Cross load/unload boundaries repeatedly with hysteresis assertions.
- Modify one dependency while its chunk is requested, pending, active, and
  retiring; prove stale generations cannot promote.
- Inject malformed and missing assets; preserve last-known-good world.
- Mutate model state, reload view, unload/reload chunk, and save/load process;
  prove domain state and stable references survive.
- Repeat reload cycles while tracking entity counts, strong handles, tasks,
  observers, physics/navigation objects, and memory trend.
- Cap frame-time impact during worst-case chunk promotion and reload bursts.
- Compare hotpatched behavior with a clean restart on every supported target.

Cross-version evidence for this matrix:
[Bevy 0.19 assets](https://docs.rs/bevy/0.19.0/bevy/asset/),
[Bevy 0.18.1 scene spawner source](https://github.com/bevyengine/bevy/blob/v0.18.1/crates/bevy_scene/src/scene_spawner.rs),
[Bevy 0.18 to 0.19 migration](https://bevy.org/learn/migration-guides/0-18-to-0-19/),
[Bevy 0.19 scenes](https://docs.rs/bevy/0.19.0/bevy/scene/), and
[Bevy 0.19 hotpatch module](https://docs.rs/bevy/0.19.0/bevy/app/hotpatch/). Use
the consuming project's exact locked-release docs for implementation.
