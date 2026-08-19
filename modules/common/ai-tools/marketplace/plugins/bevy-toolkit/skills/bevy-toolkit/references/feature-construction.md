# Bevy Feature Construction

Use this route when adding a first-party Bevy feature rather than integrating a
third-party framework. Start from the smallest source-owned vertical slice and
make its decision boundaries and proof obligations explicit.

## Route by Boundary

- **UI layout, focus, accessibility, and text:** define layout ownership, focus
  traversal, keyboard/gamepad navigation, semantic labels or roles,
  localization/text measurement, and window-scale behavior before styling. Prove
  both interaction state and rendered text; do not treat pixels as an
  accessibility check.
- **Input mapping and controllers:** separate raw device events, action mapping,
  intent, and controller state. Define precedence, rebinding, pause/focus
  behavior, fixed-step versus frame-step ownership, and a headless injection
  path before wiring gameplay systems.
- **Cameras and windows:** specify camera ownership, projection, viewport,
  window scale, resize, focus, and multi-window routing. Validate transforms
  against the actual target surface, not assumed desktop coordinates.
- **Main world and render world:** keep gameplay/state authority in the main
  world and pass only explicit render-facing data across extraction/prepare/
  queue boundaries. Verify schedule ordering, visibility, and cleanup for
  entities that appear or disappear during state changes.
- **Assets and shaders:** identify asset source, loader, handle lifetime,
  dependency readiness, hot-reload behavior, shader inputs, bind groups, and
  backend feature requirements. Keep fallback/error states observable.

## Construction Contract

1. Confirm locked Bevy version, enabled Cargo features, target platforms, and
   existing first-party plugins before selecting APIs.
2. Define the owning plugin, data types, schedules, states, and source-of-truth
   assets. Keep registration separate from runtime systems and debug tooling.
3. Build the smallest vertical slice with explicit failure and teardown paths.
   Add reflection, BRP, or editor hooks only when the feature requires them.
4. State feature gates and validate every relevant combination: default,
   development/debug, headless, native-window, and target-specific renderer or
   platform features. Do not infer coverage from one successful build.

## Proof Contract

- **Headless proof:** use minimal app composition, injected inputs, ECS state,
  asset readiness, scene load, serialization, and focused tests for behavior
  that does not require a GPU or compositor.
- **Visual proof:** use a real target surface or framebuffer for layout, camera,
  rendering, shader, resize, and text appearance. Record target, window/surface
  size, camera state, and fresh capture identity; inspect pixels.
- **Cross-boundary proof:** when UI, input, assets, or render-world data meet,
  verify lifecycle ordering, stale handles/events, focus transitions, and
  cleanup in addition to the happy path.

Treat transport success, a clean compile, and a fresh image hash as evidence of
their own layer only. Report unproven layers and unsupported feature gates.
