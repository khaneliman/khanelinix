# Start Here

## Quickstart

Build the docs:

```bash
nix build .#docs-html
```

Open the docs in your browser:

```bash
nix run .#docs
# or
nix run .#docs-html
```

If you built locally, the output lives at `./result/index.html`.

## Minimal examples

### NixOS

```nix
# systems/my-host/default.nix
{ ... }:
{
  khanelinix.suites.common.enable = true;
  khanelinix.suites.desktop.enable = true;
}
```

### Darwin

```nix
# systems/my-mac/default.nix
{ ... }:
{
  khanelinix.suites.common.enable = true;
  khanelinix.suites.desktop.enable = true;
}
```

### Home Manager

```nix
# homes/my-user/default.nix
{ ... }:
{
  khanelinix.suites.common.enable = true;
  khanelinix.programs.terminal.shells.zsh.enable = true;
}
```

## Repo map

- `flake.nix` — inputs/outputs, system wiring
- `modules/` — core module library
  - `common/` — cross-platform system modules
  - `nixos/` — NixOS system modules
  - `darwin/` — macOS system modules
  - `home/` — Home Manager user modules
- `systems/` — per-host configurations
- `homes/` — per-user configurations
- `lib/` — helper functions and overlays
- `docs/` — mdBook content and scripts
