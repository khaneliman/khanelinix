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
