# Live MCP sessions

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

## Bootstrap a session

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

## Own the endpoint

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

## Record versions

Record the discovered Blender version, MCP package version, and add-on manifest
minimum version in the task evidence. Check compatibility from that manifest; do
not copy a version or store path from another workstation and do not treat a
previous local verification as proof for a different installation.
