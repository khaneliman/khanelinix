---
paths:
  - "patches/**"
  - "packages/**"
  - "overlays/**"
  - "templates/**"
---

# Patches, Packages, Overlays, and Templates

Canon: `CONTRIBUTING.md` ("Patch and Package Routing", "Source Patching" hash
guidance, "External Code and Licensing") and `patches/README.md`.

Common mistake: root `patches/` is for flake input trees, not package overrides.
For existing nixpkgs packages, use `overlays/`; use `packages/` only for new
custom derivations.

## packages/

Custom derivations exposed as `pkgs.khanelinix.{name}`.

**Create in packages/ when:** new custom derivation not in nixpkgs, or a complex
build needing its own derivation.

**Use overlays/ instead when:** overriding, patching, version-pinning, or
changing build flags of an existing nixpkgs package.

**Use a module instead when:** simple script with no build, config-file
generation, or a one-off tool specific to a single module.

### Testing

```bash
nix build .#my-tool
nix run .#my-tool
nix build .#my-tool && ls -la result/
```

## templates/

Flake project templates, registered in root `flake.nix` under `templates.{name}`
with `path`, `description`, and `welcomeText`.

Layout: `templates/{name}/` with `flake.nix`, `.envrc` (direnv), and minimal
sample sources. Keep templates minimal; support Linux + Darwin systems.

### Testing

```bash
cd $(mktemp -d)
nix flake init -t ~/khanelinix#rust
nix develop && nix build
```
