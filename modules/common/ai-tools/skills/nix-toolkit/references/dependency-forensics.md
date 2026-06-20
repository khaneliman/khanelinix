# Dependency Forensics

## Eval-Failing Systems

When a system build fails during evaluation (broken/insecure/unfree/unsupported
package), probe narrower options before building the system closure.

Scan a known package-list option:

```bash
scripts/package-option-scan.sh \
  path:/path/to/flake#nixosConfigurations.host.config.environment.systemPackages \
  curl
```

Repeat against other list options
(`homeConfigurations.user@host.config.home.packages`, module-specific options
from error trace). Evaluates only that list; does not realize outputs.

If not in a direct option, try bounded drv-graph grep:

```bash
timeout 60s scripts/drv-graph-grep.sh --allow-meta \
  path:/path/to/flake#nixosConfigurations.host.config.system.build.toplevel \
  curl
```

`--allow-meta` sets `NIXPKGS_ALLOW_BROKEN/INSECURE/UNSUPPORTED_SYSTEM/UNFREE`
temporarily so Nix can instantiate the graph far enough to inspect drv names. Do
not carry those flags into the fix.

## Scripted Trace

```bash
scripts/dependency-trace.sh nixpkgs#hello nixpkgs#glibc
```

Resolves outputs, prints direct references, summarizes recursive closure, runs
runtime `why-depends`, runs derivation `why-depends`, searches for matching
package names when multi-output paths differ.

## Runtime vs Build-Time

- `nix why-depends <target-out> <dep-out>` finds path → runtime closure.
- Only `nix why-depends --derivation <target> <dep>` finds path → build-time
  edge only.
- System closure unbuildable → use `package-option-scan.sh` or
  `drv-graph-grep.sh` first.
- `nixpkgs#pkg` often points to `bin` while closure contains `out` or `lib` —
  resolve exact output first.

## Embedded Store Paths

```bash
out="$(nix build --no-link --print-out-paths nixpkgs#hello)"
strings "$out/bin/hello" | rg '/nix/store|glibc'
ldd "$out/bin/hello"
rg -a '/nix/store' "$out" | head
```

`strings`/`ldd` for ELF; `rg -a` for scripts, wrappers, pkg-config, desktop
files, text-like binary payloads.

## Common Causes

- `propagatedBuildInputs` where `nativeBuildInputs` or `buildInputs` would
  suffice.
- Wrappers embedding tools only needed for optional code paths.
- `substituteAll`, `makeWrapper`, or generated config embedding broad package
  path vs specific executable/data dir.
- `.pc`, CMake, Python, GI, Qt, or desktop metadata retaining build-time paths.
- ELF interpreter, RPATH, or linked libraries.

## Fix Direction

- Runtime + intentional → document or accept.
- Runtime + accidental → find embedded path, narrow wrapper/config/linkage.
- Build-time only → not a closure regression.
- Nix code changes needed → switch to `writing-nix`.
