# Dependency Forensics

Use this playbook when a derivation contains a dependency that looks wrong,
closure size jumped, or a package moved a dependency from build-time to runtime.

## Eval-Failing Systems

When a system build fails during evaluation because a package is broken,
insecure, unsupported on the platform, unfree, or unavailable, do not start by
building the system closure. Probe narrower package-bearing options first.

Scan a known package-list option:

```bash
scripts/package-option-scan.sh \
  path:/path/to/flake#nixosConfigurations.host.config.environment.systemPackages \
  curl
```

Repeat against other known list options such as
`homeConfigurations.user@host.config.home.packages` or a module-specific package
option from the error trace. This evaluates only that list and prints names plus
drv paths; it does not realize package outputs.

If the bad dependency is not in a direct package-list option, try a bounded
derivation-graph grep. This still does not build outputs, but it may require
instantiating a large system derivation graph:

```bash
timeout 60s scripts/drv-graph-grep.sh --allow-meta \
  path:/path/to/flake#nixosConfigurations.host.config.system.build.toplevel \
  curl
```

Use `--allow-meta` only for diagnosis. It temporarily sets
`NIXPKGS_ALLOW_BROKEN`, `NIXPKGS_ALLOW_INSECURE`,
`NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM`, and `NIXPKGS_ALLOW_UNFREE` so Nix can
instantiate the graph far enough to inspect drv names. Do not carry those flags
into the fix.

## Scripted Trace

Start with the bundled script:

```bash
scripts/dependency-trace.sh nixpkgs#hello nixpkgs#glibc
```

It resolves outputs, prints direct references, summarizes the recursive closure,
runs runtime `why-depends`, runs derivation `why-depends`, and searches for
matching package names when multi-output paths differ.

## Runtime vs Build-Time

- If `nix why-depends <target-out> <dep-out>` finds a path, the dependency is in
  the runtime closure.
- If only `nix why-depends --derivation <target> <dep>` finds a path, the edge
  may be build-time only.
- If the system closure cannot be built, use `package-option-scan.sh` or
  `drv-graph-grep.sh` first; use `why-depends` only after you can instantiate
  the relevant target and dependency derivations.
- If direct references include the dependency but `why-depends` against an
  installable says no, resolve exact outputs first. Multi-output packages often
  make `nixpkgs#pkg` point at `bin` while the closure contains `out` or `lib`.

## Embedded Store Paths

After resolving the output, search likely files before changing Nix code:

```bash
out="$(nix build --no-link --print-out-paths nixpkgs#hello)"
strings "$out/bin/hello" | rg '/nix/store|glibc'
ldd "$out/bin/hello"
rg -a '/nix/store' "$out" | head
```

Use `strings` and `ldd` for ELF binaries. Use `rg -a` for scripts, generated
metadata, wrappers, pkg-config files, desktop files, and text-like binary
payloads.

## Common Causes

- `propagatedBuildInputs` used where `nativeBuildInputs` or `buildInputs` would
  be enough.
- Wrappers embedding tools that are only needed for optional code paths.
- `substituteAll`, `makeWrapper`, or generated config files embedding a broad
  package path instead of a specific executable or data directory.
- `.pc`, CMake, Python, GI, Qt, or desktop metadata retaining build-time paths.
- ELF interpreter, RPATH, or linked libraries pulling a dependency directly.

## Fix Direction

- If the edge is runtime and intentional, document it or accept the closure.
- If the edge is runtime but accidental, find the embedded path and narrow the
  wrapper/config/linkage.
- If the edge is build-time only, do not optimize it as a closure regression.
- If the fix requires Nix code changes, switch to `writing-nix` before editing.
