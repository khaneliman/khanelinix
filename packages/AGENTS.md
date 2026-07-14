# Local Packages

## Discovery and Exposure

- Package definitions use `package.nix`. `flake/packages.nix` discovers them
  recursively and filters by host availability; support/cache-only directories
  need not expose a package.
- `flake/overlays.nix` exposes locally defined packages under `pkgs.khanelinix`
  for modules; flake package outputs additionally filter by host availability.

## Ownership Boundary

- Use `packages/` for independently exposed tools, software absent from nixpkgs,
  or complex local builds.
- Keep one-off scripts and config generators owned by single module inside that
  module.
- Existing nixpkgs package overrides, pins, patches, and build-flag changes
  follow `CONTRIBUTING.md` overlay routing.

## Validation

```bash
nix build '.#<package>'
nix run '.#<package>' -- --help # when package exposes runnable main program
```

Inspect built output or exercise relevant module integration when runtime files
matter.
