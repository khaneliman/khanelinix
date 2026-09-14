# Agent and build memory policy

On Linux, T3's managed provider processes run separately from its backend in
per-provider scopes under `app-agent-workloads.slice`. Ordinary tool commands
inherit that slice. Explicit build runners move a command to a sibling slice.

The only memory ceiling is a hard cap on the shared agent slice, configurable
as `khanelinix.programs.terminal.tools.t3code.resourceControl.memoryMax`. It
defaults to `75%` of physical memory. systemd accepts sizes such as `40G` too.

```nix
khanelinix.programs.terminal.tools.t3code.resourceControl.memoryMax = "40G";
```

There is deliberately no soft threshold. cgroup `memory.high` does not fail a
process; it puts every allocating process in the scope to sleep, including the
agent's own event loop. Two large Nix evaluations under a 6 GiB soft limit
turned into an hour-long silent hang with no error anywhere. A hard cap kills
the largest process in the scope instead, and the runners use
`OOMPolicy=continue` so the agent survives and sees a failed tool result.

## Build lane

The build lane exists for CPU and IO priority and to escape the agent hard cap,
not for a memory budget. From a T3 tool command, prefix the build with
`t3code-build`:

```sh
t3code-build nix build .#my-package
t3code-build cargo build --release
```

For shell syntax, pass a shell explicitly:

```sh
t3code-build bash -lc 'cd /path/to/project && cargo build --release'
```

Outside T3, use `build-run` instead. Use `agent-run` to place a manual command
under the agent slice. These commands are installed when T3 resource control is
enabled on Linux.

The runners preserve arguments, working directory, environment, standard
streams, and exit status. `t3code-build` scopes stop when the T3 backend
stops. Stopping only a provider does not necessarily stop its separate build
scopes. `build-run` has no backend lifetime dependency.

## Boundaries

Nix daemon builds run separately from their clients under the system
`resources-limiter` slice, which has its own soft threshold. Client evaluation
runs in the caller's scope.

System-wide memory exhaustion can still interrupt workloads through earlyoom
or the kernel. Ancestor cgroup limits, if configured elsewhere, also apply.

Agent scopes run with `TMPDIR=/var/tmp` unless the caller already exported
`TMPDIR`. The default `/tmp` is a tmpfs, so build scratch left there stays
resident until reboot; `/var/tmp` is disk backed and cleaned by tmpfiles after
30 days.

Wrapping applies to Nix-managed canonical provider paths; custom provider
instances configured through the GUI are not covered automatically.
