# Agent and build memory policy

On Linux, T3's managed provider processes run separately from its backend.
Ordinary commands inherit their provider's limits. Large builds need an explicit
build runner; commands are not classified automatically.

The budgets are configurable under
`khanelinix.programs.terminal.tools.t3code.resourceControl`. The options are
strings because systemd accepts values such as `6G` directly. Set
`agent.memoryHigh`, `agent.memoryMax`, and `agent.memorySwapMax` for each scope;
`agentAggregate.memoryHigh`, `agentAggregate.memoryMax`, and
`agentAggregate.memorySwapMax` for the shared agent slice; and
`build.memoryHigh` for build scopes and their shared slice.

```nix
khanelinix.programs.terminal.tools.t3code.resourceControl = {
  agent.memoryMax = "10G";
  agentAggregate.memoryMax = "20G";
  build.memoryHigh = "24G";
};
```

The existing limits below are the defaults.

| Workload                                    | Soft memory threshold | Hard memory limit | Swap limit      |
| ------------------------------------------- | --------------------- | ----------------- | --------------- |
| Each managed provider or `agent-run` scope  | 6 GiB                 | 8 GiB             | 2 GiB           |
| All ordinary agent scopes together          | 12 GiB                | 16 GiB            | 4 GiB           |
| Each build scope and the shared build slice | 16 GiB                | None configured   | None configured |

## Large builds

From a T3 tool command, prefix the build with `t3code-build`:

```sh
t3code-build nix build .#my-package
t3code-build cargo build --release
```

For shell syntax, pass a shell explicitly:

```sh
t3code-build bash -lc 'cd /path/to/project && cargo build --release'
```

Outside T3, use `build-run` instead. Use `agent-run` for a manually capped
ordinary command. These commands are installed when T3 resource control is
enabled on Linux.

The build runners preserve arguments, working directory, environment, standard
streams, and exit status. They move execution outside the provider's hard-capped
slice. Soft memory pressure can slow builds; it does not impose a memory
ceiling.

`t3code-build` scopes stop when the T3 backend stops. Stopping only a provider
does not necessarily stop its separate build scopes. `build-run` has no backend
lifetime dependency.

## Boundaries

Nix daemon builds run separately from their clients. Khanelinix's daemon slice
has a 16 GiB soft threshold and no hard memory or swap cap. Client evaluation
still inherits ordinary provider limits unless launched through the build
runner. The `nixre-fast` alias retains its explicit concurrency overrides.

Oomd monitors ordinary agent scopes, not the build slice or backend. System-wide
memory exhaustion can still interrupt builds through earlyoom or the kernel.
Ancestor cgroup limits, if configured elsewhere, also apply.

The provider limit covers the whole process tree, not each tool command
individually. Wrapping applies to Nix-managed canonical provider paths; custom
provider instances configured through the GUI are not covered automatically.
