# Architecture

KhaneliNix is organized around modular, platform-specific configuration with a
single option namespace: `khanelinix.*`.

## Core principles

- **Modular architecture**: small modules combined via suites and archetypes.
- **Namespace scoping**: all custom options live under `khanelinix.*`.
- **Home-first**: prefer Home Manager modules for user-space config.

## Configuration hierarchy (7 levels)

1. **Flake entry points** (`flake.nix`) — inputs and outputs.
2. **Shared library** (`lib/`) — helpers and overlays.
3. **Common modules** (`modules/common/`) — shared system-level pieces.
4. **Platform modules** (`modules/nixos/`, `modules/darwin/`) — system config.
5. **Home modules** (`modules/home/`) — user-space config.
6. **Suites & archetypes** — bundled defaults and opinionated stacks.
7. **Host/user configs** (`systems/`, `homes/`) — concrete deployments.

## Option namespace

All custom options are scoped under `khanelinix.*` and are generated into the
options docs automatically. If you add new options, ensure they live under this
namespace so they show up in the docs.

## Input patching

System builders call `lib/system/common.nix` to patch selected flake inputs
before constructing NixOS, nix-darwin, or standalone Home Manager
configurations. This keeps temporary upstream backports close to input plumbing
instead of hiding them in host modules.

Supported inputs are `nixpkgs`, `nixpkgs-unstable`, `nixpkgs-master`,
`home-manager`, and `nix-darwin`.

Patch sources for each input:

- `patches/<input>/*.patch`: committed local patch files.
- `patches/<input>/default.nix`: extra patch expressions, usually `fetchpatch2`
  URL/hash entries.
- `extraInputPatches.<input>`: call-site override passed to `mkSystem`,
  `mkDarwin`, or `mkHome`.

`mkDarwin` can patch every supported input. `mkSystem` and `mkHome` patch
`nixpkgs`, `nixpkgs-unstable`, `nixpkgs-master`, and `home-manager`; they skip
`nix-darwin` because those builders do not evaluate it.

Example `patches/nix-darwin/default.nix`:

```nix
{ ... }:
[
  {
    url = "https://github.com/nix-darwin/nix-darwin/pull/123.patch";
    hash = "sha256-...";

    # Optional; defaults to "fetchpatch2".
    fetcher = "fetchpatch";

    # Optional; extra attributes pass through to selected fetcher.
    stripLen = 1;
  }
]
```

Entries with `url` use `pkgs.fetchpatch2` unless `fetcher` overrides it. Direct
patch paths and patch derivations are also accepted. Use `hash = lib.fakeHash;`,
build once, and replace it with the `got:` SRI hash.
