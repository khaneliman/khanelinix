---
paths:
  - "packages/**"
  - "overlays/**"
  - "templates/**"
---

# Packages, Overlays, and Templates

Source patching and licensing rules: `CONTRIBUTING.md` ("Source Patching in
Derivations", "External Code and Licensing"). Read those before patching.

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
