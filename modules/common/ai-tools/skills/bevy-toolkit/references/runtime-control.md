# Bevy Runtime Control

Use MCP for interactive agent sessions. Use `scripts/brp-control.py` when a
repository script, CI-like probe, or exact JSON-RPC sequence needs deterministic
behavior without relying on the MCP tool catalog.

## Direct BRP Helper

Requires Python 3.10 or newer. Default endpoint is `http://127.0.0.1:15702`. The
helper resolves the base path or `/jsonrpc` with a read-only readiness probe,
pins that endpoint, and never retries a mutation on another path after ambiguous
delivery.

```bash
<skill-dir>/scripts/brp-control.py status
<skill-dir>/scripts/brp-control.py wait --seconds 120
<skill-dir>/scripts/brp-control.py call world.query \
  '{"data":{},"filter":{"with":["bevy_ecs::name::Name"]}}' --read-only
```

Arbitrary `call` defaults to mutation. `--read-only` is accepted only for the
helper's allowlisted core BRP reads; unknown and custom methods remain mutations
even when their implementation is observational. Mutations require exact
identity readback before execution:

```bash
<skill-dir>/scripts/brp-control.py \
  --identity-method world.get_resources \
  --identity-params '{"resource":"game::SessionIdentity"}' \
  --identity-expected '{"app":"my-game","session":42}' \
  keys Space --duration-ms 500
```

Identity method must be an allowlisted BRP read such as `world.get_resources` or
`world.query`, and return stable app/session/build data. Expose project-owned
identity as a reflected resource or component rather than a custom method.
`--allow-unguarded-mutation` is an explicit escape hatch for deliberate
interactive control when project identity does not exist; do not use it in CI or
unattended automation.

Use `call METHOD @params.json` for larger payloads and `call METHOD -` for
stdin. Use `--port`, `--url`, `--timeout`, and `--pretty` as needed. The helper
never launches or sends OS process signals; `shutdown` requests clean remote
shutdown. Lifecycle ownership remains with repository scripts or MCP.

Successful output is a stable JSON receipt with `schema_version`, `skill`,
`operation`, `mode`, `status`, resolved `endpoint`, identity guard result, and
BRP `result`. Exit codes:

| Code | Meaning                                                 |
| ---- | ------------------------------------------------------- |
| 0    | operation completed and receipt emitted                 |
| 2    | CLI or JSON input invalid                               |
| 3    | readiness timeout or mutation safety prerequisite unmet |
| 4    | transport, JSON-RPC, local I/O, or execution failure    |
| 5    | identity or artifact verification failed                |

## Deterministic Probe Shape

1. **Preflight** — verify target/build/features and reject occupied/wrong BRP
   session. Establish project-owned reflected identity data before scripting
   mutations.
2. **Launch/attach** — start through MCP or repository launcher; capture PID,
   port, app/session identity, log, and whether desktop/headless.
3. **Wait** — poll BRP while also checking owned process liveness and timeout.
4. **Arrange** — query current entities/resources; establish narrow mutation or
   project-owned request.
5. **Act** — use reflected mutation, event/request, or frame-aware input.
6. **Settle** — poll explicit status/request identity, not a blind long sleep.
7. **Assert** — read back state and reject wrong scene, stalled progress, or
   stale response.
8. **Capture** — request framebuffer screenshot and verify fresh nonzero file.
9. **Inspect** — view pixels/logs/diagnostics; transport success is
   insufficient.
10. **Restore/cleanup** — revert temporary state, stop watches, cleanly shut
    down only process owned by this probe.

## Launching

Prefer repository-native launchers because they own feature flags, asset roots,
dynamic-linker paths, arguments, headless compositor, and logs. If none exists,
use MCP discovery/launch rather than inventing a generic `cargo run` wrapper.

For native desktop launch, report that a window will open. For automation,
prefer an isolated headless compositor when rendering still requires GPU/window
infrastructure. A no-window ECS app cannot prove framebuffer behavior.

## Window and Input Coordinates

- Verify Bevy's reported window size and the compositor surface size.
- Resize/move the actual native surface before coordinate-based mouse input or
  compositor capture.
- On Hyprland 0.55, use Lua window dispatchers and separate key down/up dispatch
  calls when compositor-level fallback is required.
- Prefer BRP extras input over global synthetic input because it is frame-aware
  and targets the game directly.
- Do not modify only Bevy's internal physical resolution while leaving a
  mismatched surface; this can produce duplicated/tiled output.

## Capture Contract

Use unique output directories and record:

- app/session/request identity and BRP port
- camera transform and game/compositor dimensions
- launch mode and feature set
- output path, modification time, size, and hash
- state readback before and after capture

Reject pre-existing output paths unless explicit overwrite is part of the probe.
Inspect each image. Distinct hashes do not prove good framing.

## Process Safety

- Check BRP status before launch.
- Prefer clean extras shutdown.
- If MCP falls back to process termination, ensure it owns the launched PID.
- Never use broad `pkill`/name matching when multiple games or Cargo jobs may
  run.
- If a live build holds Cargo's target lock, identify the real lock owner; do
  not launch duplicate builds or kill unrelated processes.
