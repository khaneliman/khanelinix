# Bevy MCP and BRP

`bevy_brp_mcp` is an MCP stdio server used by the coding agent. The running game
exposes Bevy Remote Protocol over HTTP. Keep these two connections distinct when
diagnosing discovery, tool availability, or game reachability.

## Contents

- [Compatibility and App Setup](#compatibility-and-app-setup)
- [Lifecycle Workflow](#lifecycle-workflow)
- [Introspection Before Mutation](#introspection-before-mutation)
- [Queries and Reads](#queries-and-reads)
- [Mutations and Events](#mutations-and-events)
- [Input, Capture, and Diagnostics](#input-capture-and-diagnostics)
- [Watches, Logs, and Cleanup](#watches-logs-and-cleanup)
- [Failure Routing](#failure-routing)

## Compatibility and App Setup

Inspect installed MCP/extras and locked Bevy versions before editing. The
khanelinix package currently uses `bevy_brp_mcp` 0.20.1, whose upstream
compatibility table targets Bevy 0.19. Treat this as current configuration, not
a permanent compatibility rule.

Core BRP requires Bevy's remote feature and remote plugins. `bevy_brp_extras`
can register core BRP plus screenshots, diagnostics, keyboard/mouse input,
window title, and clean shutdown. Keep either setup development-only when remote
control must not ship in normal/release binaries.

Defaults and caveats:

- Default port: `15702`; extras supports `BRP_EXTRAS_PORT`.
- Bind to loopback unless remote access is explicit and secured.
- Extras screenshots require Bevy's `png` feature.
- Extras diagnostics require its `diagnostics` feature (default-on upstream).
- Custom `RemoteHttpPlugin` owns transport/port; extras port settings are then
  ignored.

## Lifecycle Workflow

Prefer this sequence:

1. `brp_list_bevy` — discover declared apps/examples, package identity, BRP
   support level, profiles, build status, and paths.
2. `brp_status` — detect existing process/port before launch.
3. `brp_launch` — launch chosen app/example, supplying package/path/features,
   profile, args, and port deliberately.
4. Poll `brp_status` until `running_with_brp`; read returned log path when
   launch or startup fails.
5. Perform inspect/control/verification work.
6. `brp_shutdown` — prefer extras clean shutdown; MCP may fall back to its owned
   process termination.

Do not launch a second app onto an occupied BRP port. For multiple instances,
assign sequential/explicit ports and carry port plus app/session identity into
every tool call.

## Introspection Before Mutation

- Use `brp_type_guide` for every component/resource type being spawned,
  inserted, or mutated. Pass fully qualified reflected type names.
- Check `reflect_types`: `Component` and `Resource` determine supported
  operations; mutation also requires mutable reflected fields.
- Use `registry_schema` or `brp_all_type_guides` only when broad schema
  discovery is needed; their responses can be large.
- Use `rpc_discover` when diagnosing available BRP methods or extras mismatch.
- Prefer project-owned `Name`, marker components, request/session resources, and
  stable IDs over entity numbers copied from an older run.

## Queries and Reads

Pass MCP parameters as objects, not JSON strings.

For `world_query`:

- `data: {}` returns matching entity IDs only.
- `data.components` requires and returns listed component data.
- `data.option` returns optional components; `"all"` is broad and expensive.
- `data.has` returns presence booleans.
- `filter.with` and `filter.without` constrain matching entities.

Use `world_get_components` after resolving current entity IDs. Use
`world_get_resources` for global/config/request state. Read the smallest useful
set and record pre-state before control actions.

## Mutations and Events

Use type-guide mutation paths exactly:

- root replacement: `""`
- nested field: `.translation.y`
- array: `.points[2]`
- tuple: `.0`
- map: `.scores['player1']`

Prefer `world_mutate_components` / `world_mutate_resources` over whole-value
replacement. Verify result with a get/query call. Restore temporary mutation
after capture or diagnosis.

Use `world_trigger_event` only for events registered/reflected for BRP and when
observer semantics are intended. Prefer project-owned request resources for
long-running actions because they can carry request ID, status, progress, and
error state across frames.

## Input, Capture, and Diagnostics

With `bevy_brp_extras`:

- `brp_extras_send_keys` sends a simultaneous chord and complete
  press-hold-release cycle. Use Bevy `KeyCode` names such as `KeyA`, `Space`, or
  `ShiftLeft`; set `duration_ms` for held input.
- `brp_extras_type_text` queues characters one per frame. Use it for text
  fields, not chords.
- Mouse move supports absolute position or delta; click/drag/scroll operate in
  game-window coordinates. Verify actual window and compositor size first.
- `brp_extras_screenshot` writes a game framebuffer image. Use a unique absolute
  path, then verify existence, nonzero size, freshness, and pixels.
- `brp_extras_get_diagnostics` returns current/average/smoothed FPS and frame
  time. Warm the scenario before comparing measurements.

## Watches, Logs, and Cleanup

Component/list watches run asynchronously and write logs. Track returned watch
IDs/log paths, bound observation duration, stop watches, and delete only logs
owned by the current task. Do not leave a watcher as an implicit assertion.

Use `brp_list_logs` / `brp_read_log` for MCP-launched game and watch logs. Use
the trace-level tools only for bounded MCP/BRP protocol diagnosis; restore
normal tracing and remove task-owned trace logs afterward.

## Failure Routing

| Symptom                                  | Check                                                                 |
| ---------------------------------------- | --------------------------------------------------------------------- |
| MCP tool absent                          | khanelinix `enabled_tools`, deployed config, new agent session        |
| App listed with `brp_level: none`        | remote feature/plugin registration for target source                  |
| `running_no_brp`                         | launched wrong binary/features or remote plugin disabled              |
| Connection refused                       | port/process, readiness timeout, game log                             |
| Method not found                         | extras absent/version mismatch; inspect `rpc_discover`                |
| Unknown type/path                        | current registry/type guide and fully qualified type name             |
| Mutation succeeds but behavior unchanged | wrong entity/session, deferred logic, owner system overwrote field    |
| Input missed                             | use frame-aware extras calls; verify focus/window/state and read back |
| Screenshot empty                         | `png` feature, render-capable app, destination permissions            |
| Tiled/duplicated native capture          | resize compositor surface, not only Bevy resolution                   |

Upstream source: [natepiano/bevy_brp](https://github.com/natepiano/bevy_brp).
