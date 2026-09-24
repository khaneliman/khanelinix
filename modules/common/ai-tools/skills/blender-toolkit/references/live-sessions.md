# Live MCP sessions

For the Blender Lab bridge, the MCP server exposes tools to the agent's client,
while the Blender add-on executes `bpy` code over a local TCP connection;
starting the server alone does not make Blender reachable.

## Resolve the add-on

Confirm the installed Blender executable and a compatible add-on package before
launching. Resolve `blender-mcp` from `PATH` or an explicit
`BLENDER_MCP_EXECUTABLE`, derive its package root from the resolved executable,
and verify that `<root>/share/blender-mcp/addon` contains the add-on module and
manifest. For an unusual layout, an explicit `BLENDER_MCP_ADDON_PATH` is
sufficient; do not select an arbitrary store match or install a substitute MCP
package. If the executable is absent from `PATH`, read only the Blender server's
command from the client configuration; a missing shell command does not mean the
configured package is missing.

Record the Blender version, MCP package version, and add-on manifest minimum
version in the task evidence, and check compatibility from that manifest. Do not
copy a version or store path from another workstation, or treat an earlier local
verification as proof for a different installation.

## Bootstrap a session

For a session-only GUI bootstrap of the Lab add-on, export the resolved
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
server environment, because `blmcp` reads them on each tool call. Inspect the
installed add-on API before using this bootstrap with another implementation.

## Own the endpoint

Preflight the loopback endpoint. If it is occupied, identify the listener, test
the existing session with MCP, and reuse it when it owns the intended file; if
ownership or file identity is wrong, report the conflict instead of starting a
competing owner. Never kill an unrelated Blender or application process. Keep
startup session-only; do not change Blender preferences, autostart settings,
system services, or persistence unless asked. The bridge timer registers with
`persistent=True`, so it survives opening a blend file; verify the intended file
and owner after each open.

One Blender session exclusively owns its endpoint and edited file. Parallel
modeling needs distinct Blender PIDs, ports, named MCP client servers, and
source paths, with one writer per endpoint and source file. Start each add-on
and set its client on the same host and port, then verify each route before
editing; separate ports alone do not create separate MCP tool connections. Give
each worker its assigned connection name and source path, and schedule renders
against the machine's shared GPU and memory budget.
