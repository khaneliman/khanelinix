# Bevy World Authoring and Iteration

Design world, level, UI, asset, or runtime feedback loops here. Confirm locked
versions before choosing format, watcher, reflection, or remote APIs.

## Select the Feedback Loop

| Change                                               | Primary loop                                                   | Minimum proof                                        |
| ---------------------------------------------------- | -------------------------------------------------------------- | ---------------------------------------------------- |
| System or observer body                              | Repository hotpatch launcher when supported; otherwise rebuild | Cold-start behavior still passes                     |
| Component/resource shape, plugin setup, or schedules | Rebuild and restart                                            | Migration, setup, transition, and teardown tests     |
| Texture, shader, audio, or custom authored data      | Asset hot reload                                               | Dependencies ready; affected output/state updates    |
| Scene or hierarchy data                              | Release-appropriate scene/world asset or project loader        | Owned subtree updates without duplicate state        |
| Live diagnosis or parameter tuning                   | Inspector or BRP                                               | Mutation readback plus explicit persistence decision |
| Geometry, tilemap, or level source                   | DCC/map editor through deterministic importer                  | Export, import, reload, and cold-start parity        |

Do not standardize on RON, BSN, glTF, or another format only because Bevy can
load it. Choose by source ownership, round-trip needs, target support, and
migration cost.

## Declare the Source of Truth

- Name the authority for each field: Rust defaults, authored asset, DCC project,
  runtime save, or temporary live override.
- Define synchronization direction. For round-trip editing, define conflict
  detection and merge ownership before allowing both sides to write.
- Keep gameplay identity and mutable runtime state on stable host entities. Put
  editor-owned presentation or geometry under replaceable owned roots.
- Treat raw runtime `Entity` values as session-local. Map persisted source IDs
  to current entities after every load.
- Keep unsaved inspector or BRP changes visibly distinct from persisted edits.

## Make Reload Transactional

1. Assign app/session and source revision IDs to the reload request.
2. Load candidate data and recursive dependencies into pending state.
3. Validate schema/version, stable IDs, references, relationships, and
   ownership.
4. Build or reconcile the pending subtree without exposing partial authoring
   state to normal gameplay systems; tag or gate pending roots explicitly.
5. Promote at a known schedule boundary only when validation succeeds.
6. Remove the previous owned subtree and release old task-owned strong handles
   after promotion.
7. On failure, retain the last-known-good world and surface actionable
   diagnostics.

Reject stale completions from older revisions. Cancel pending work when its host
or state exits. Prefer whole-subtree replacement for editor-owned presentation;
use explicit reconciliation when runtime state must survive.

## Define the External Tool Contract

- Generate or export editor schemas from the locked application type registry or
  an equivalent project-owned contract. Include app, schema, and format
  versions; reject stale schemas instead of guessing.
- Allowlist authorable types and fields. Reflection availability does not imply
  safe persistence or arbitrary construction.
- Define axis, handedness, units, scale, naming, and asset-path conversion. Test
  fixtures with known transforms and dimensions.
- Make exports deterministic and imports idempotent. Support incremental export
  only with a full-rebuild fallback.
- Route persistent edits through authoring commands or transactions that can
  support validation, undo/redo, dirty state, and save failure.
- Keep drag/gizmo previews out of persisted data and undo history. Commit one
  transaction on completion; cancel or expire previews on disconnect.
- Report parse, dependency, conversion, and unsupported-type errors at the
  source object when possible.

## Bound BRP and Runtime Editors

- Treat the running app as authority for current ECS state, not automatically
  for persisted authoring data.
- Prefer narrow watches for selected entities/components over broad polling.
  Bound watch lifetime and recover from disconnect or dropped updates.
- Use type introspection before mutation, read back every change, and expose a
  separate explicit commit path when edits should persist.
- Carry target, port, app/session, source revision, and stable object identity
  when one editor can attach to multiple processes.
- For multi-target editing, persist one authoritative revision, then synchronize
  disposable replicas. Track each target's applied revision and recover with a
  full snapshot; do not claim cross-process atomicity.

## Validate the Pipeline

- Prove missing, malformed, and stale input preserves the last-known-good world.
- Prove out-of-order reloads cannot install an older revision.
- Repeat reload and undo/redo cycles; reject duplicate entities, observers,
  assets, and leaked handles.
- Prove preview cancellation, disconnect recovery, and partial multi-target
  failure leave persisted data and healthy targets coherent.
- Prove stable host state survives editor-owned subtree replacement.
- Verify exported artifacts reproduce the edited result from a cold start.
- Capture fixed-view visual evidence for spatial changes and assert state for
  behavior changes.
- Test the riskiest target/backend and the development-only feature boundary.

Start from [Bevy assets](https://docs.rs/bevy/latest/bevy/asset/),
[Bevy Remote Protocol](https://docs.rs/bevy/latest/bevy/remote/), and the
[Bevy migration guides](https://bevy.org/learn/migration-guides/). Select docs
matching the locked release before API work.
