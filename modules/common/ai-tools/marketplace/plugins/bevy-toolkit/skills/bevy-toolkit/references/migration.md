# Bevy Migration Workflow

Use this route for Bevy version changes, plugin upgrades, API removals, or a
multi-release workspace jump. Keep claims tied to the repository's locked state
and official migration material; do not turn this into a release encyclopedia.

## Intake and Baseline

1. Record the current and intended Bevy versions from `Cargo.lock`, workspace
   manifests, overlays, and any repository version matrix. Treat a requested
   version as a target hypothesis until source or lock evidence confirms it.
2. Capture a baseline before edits: `cargo check` for affected targets, focused
   tests, asset/scene loading checks, reflection or BRP probes, and visual or
   headless evidence where the feature needs it. Record commands and failures.
3. Identify enabled Bevy feature flags, default-feature changes, platform
   targets, development-only plugins, asset loaders, shader paths, and generated
   or serialized data that may encode old APIs.

## Guide and Compatibility Chain

- For a multi-release jump, read official migration guides in version order;
  apply and verify each boundary instead of collapsing advice across releases.
- Resolve Cargo dependency, feature, and plugin compatibility together. Check
  direct and transitive Bevy crates, render backends, asset loaders, reflection
  crates, examples, and target-specific dependencies before changing versions.
- Prefer the smallest compatible set. Do not upgrade an unrelated plugin merely
  to match a newer example; document an intentional compatibility exception.

## Checkpoints

After each migration boundary, run the narrowest useful compile or test target,
then expand only when it passes:

- workspace or package `cargo check` for affected features and targets;
- focused tests, minimal headless app, and scene/asset loading probes;
- reflection registration, serialized scene/entity data, and BRP type/query
  checks when reflected APIs changed;
- native-window, framebuffer, or screenshot proof only for visual behavior.

Treat compile success as API proof, not runtime or visual proof. Keep failures
attributed to the boundary that introduced them.

## Data and Reversibility

- Migrate scenes, assets, reflection registrations, shader inputs, and BRP
  payloads as source-owned data. Check load, reload, serialization, and
  round-trip behavior rather than only changing Rust call sites.
- Put each release boundary in a reversible change unit. Preserve the prior
  lockfile and source format until the next checkpoint passes; use adapters or
  dual-read paths when data cannot be rewritten atomically.
- Define rollback before destructive conversion: what can revert by lockfile,
  source change, generated artifact, or data restore, and what requires a
  one-way migration or manual recovery.

## Final Target Matrix

Finish with a compact matrix covering each supported target and feature set:
locked Bevy version, Cargo features, plugin versions, platform/backend,
compile/check result, headless result, visual result when applicable, and known
exceptions. Include the baseline-to-target delta and remaining follow-up work.
