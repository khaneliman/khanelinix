# Scripted and interactive execution

## Select the control surface

Discover the installed Blender version and available tool schemas. MCP, TCP, and
WebSocket bridges are different implementations, not interchangeable Blender
protocols. Use the configured bridge and its documented capabilities; do not
install an add-on or start another server merely because a recipe uses it. If
live control is unavailable, use headless Blender when the task permits it.

Before a live edit, inspect the active file, scene, mode, selection, and unsaved
work. Scope mutations to the intended collection or objects. Keep a checkpoint
before destructive edits; never clear the user's scene as initialization.

## MCP live-start protocol

For the Blender Lab bridge, the MCP server exposes tools to the agent's MCP
client, while the Blender-side add-on executes `bpy` code through a local TCP
connection. Starting the MCP server alone does not make Blender reachable.
Confirm the installed Blender executable and compatible add-on package before
launching. Resolve `blender-mcp` from `PATH` or an explicit
`BLENDER_MCP_EXECUTABLE`, then derive its package root from the resolved
executable and verify `<root>/share/blender-mcp/addon` contains the add-on
module and manifest. If the package has an unusual layout, an explicit
`BLENDER_MCP_ADDON_PATH` is sufficient; do not select an arbitrary store match
or install a substitute MCP package. If the executable is absent from `PATH`,
read only the Blender server's command from the client's configuration. A
missing shell command does not mean the configured package is missing.

For a session-only GUI bootstrap of this Lab add-on, export the resolved
`BLENDER_MCP_ADDON_PATH`, write a task-owned Python file, and run Blender with
`--python-use-system-env --factory-startup --python /absolute/bootstrap.py`:

```python
import os, sys
from pathlib import Path
import bpy

addon = Path(os.environ["BLENDER_MCP_ADDON_PATH"]).resolve()
if not (addon / "blender_mcp_addon" / "__init__.py").is_file():
    raise RuntimeError(f"MCP addon not found at {addon}")
sys.path.insert(0, str(addon))
import blender_mcp_addon
blender_mcp_addon.register()
from blender_mcp_addon import execute_interactive, mcp_to_blender_server

host, port = "127.0.0.1", int(os.environ.get("BLENDER_MCP_PORT", "9876"))
mcp_to_blender_server.start(host, port)
bpy.app.timers.register(execute_interactive.run,
                        first_interval=mcp_to_blender_server.TIMER_INTERVAL_ACTIVE,
                        persistent=True)
```

Set `BLENDER_MCP_HOST=127.0.0.1` and the same `BLENDER_MCP_PORT` in the MCP
server environment because `blmcp` reads them for each tool call. Inspect the
installed add-on API before using this bootstrap with another implementation.

Preflight the selected loopback endpoint. If occupied, identify the listener,
test the rightful existing session with MCP, and reuse it when it owns the
intended file. If ownership or file identity is wrong, report the conflict and
refuse to start a competing owner. Never kill an unrelated Blender or
application process. Keep startup session-only; do not change Blender
preferences, autostart settings, system services, or persistence unless
explicitly requested. The interactive bridge registers its timer callback with
`persistent=True`, so it remains active across a blend-file open during the
owned session. Treat one Blender session as the exclusive owner of its endpoint
and actively edited file; verify the intended file and owner after opening it.
Parallel modeling requires distinct Blender PIDs, ports, named MCP client
servers, and source paths, with one writer per endpoint and source file. The
verified `blmcp` client reads `BLENDER_MCP_HOST` and `BLENDER_MCP_PORT` on each
tool call, while the Blender add-on must be started with the matching host and
port. Set the client and add-on port together for a separate session, and verify
each route before editing. Separate ports alone do not create separate MCP tool
connections. Give each worker its assigned connection name and source path, and
schedule renders against the machine's shared GPU and memory budget.

Prove the live path with MCP tools, not a listening socket alone. Run
`get_blendfile_summary_path_info`, then `get_objects_summary` (or equivalent
scene metadata), and capture `get_screenshot_of_window_as_image` or the relevant
`VIEW_3D` area. Metadata must identify the expected scene/file and the image
must be a real Blender viewport capture. If a call times out, query scene state
before replaying a mutation because the first request may have completed. If the
user requires MCP, report the concrete blocker and preserve that requirement
instead of silently substituting headless execution. For other tasks, choose
headless execution when the task permits it and the required checks can run.

Record the discovered Blender version, MCP package version, and add-on manifest
minimum version in the task evidence. Check compatibility from that manifest; do
not copy a version or store path from another workstation and do not treat a
previous local verification as proof for a different installation.

## Make scripts repeatable

Prefer the data API for context-independent edits. When an operator is needed,
check its installed RNA properties and polling requirements. Establish mode,
active object, selection, view layer, and any required context override
explicitly. A background process cannot supply an editor area that does not
exist.

Use stable ownership markers or an explicit generated collection so reruns
update only owned data. A retry must not duplicate objects, actions, or
materials. After a bridge timeout, query the resulting state before replaying a
mutation: a lost reply does not establish that the command failed.

For headless jobs, pass absolute source, script, and output paths. Blender
handles arguments in order: load the intended source before running the script,
and set Python failure handling before the script. A typical existing-file
invocation is:

```sh
blender --background /absolute/source.blend --python-exit-code 1 \
  --python /absolute/job.py -- --output /absolute/candidate.blend
```

The `--output` argument belongs to the task's script, not Blender; parse script
arguments after `--`. For a new isolated scene, use `--factory-startup` instead
of loading a source file. Do not enable automatic execution of embedded scripts
just to open a third-party asset.

Require both a successful process exit and the expected outputs. Keep logs and
record source path, Blender version, export settings, output paths, and
inspection results outside the installed skill. Do not swallow exceptions that
should fail a batch. Validate one representative asset before processing the
full batch; report per-asset failures without treating partial completion as
full success.

## External assets and previews

Use external libraries only when their assets meet the task. Record source URL,
asset identity, license/attribution, downloaded files, and texture dependencies.
Check scale, orientation, origin, material compatibility, and scene contents
after import. Service-specific APIs and credentials must come from available
tools, not assumed Poly Haven, Sketchfab, or generation-service access.

For thumbnails, turntables, or sprite sheets, keep camera/projection, framing,
lighting, color management, resolution, transparency, and frame range explicit.
Fix those settings across comparison renders. Judge silhouette before expensive
render sampling. Inspect the actual resulting images, including alpha and crop;
file existence alone does not prove the preview contains the asset.

## Sources

- [Blender Python API](https://docs.blender.org/api/current/), using the
  discovered local version for operators and the data API.
- [Operator context](https://docs.blender.org/api/current/info_gotchas_operators.html)
- [Command-line arguments](https://docs.blender.org/manual/en/latest/advanced/command_line/arguments.html)
