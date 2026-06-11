---
paths:
  - "**/*.nix"
---

# khanelinix Nix Nudges

Style canon: `CONTRIBUTING.md` "Nix Code Style" + the `writing-nix` skill. This
file holds only repo-specific patterns neither documents.

## Module Template

```nix
{
  config,
  lib,
  pkgs,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.category.name;
in
{
  options.khanelinix.category.name.enable = mkEnableOption "Description";

  config = mkIf cfg.enable {
    # implementation
  };
}
```

- Always extract `cfg` from the `config.khanelinix.*` path; option pattern is
  `khanelinix.{category}.{subcategory}.{name}`.
- HM modules use `osConfig ? { }` to access the host system's configuration.
- Check `lib.khanelinix` for common helpers (`enabled`, `disabled`,
  `getFile "secrets/..."`).

## Option Wrapping

- Wrap settings in `khanelinix.*` options only when they must be toggled or
  customized across hosts/users. Otherwise use upstream NixOS / nix-darwin /
  Home Manager options directly — do not wrap for "consistency".

## PATH vs Store Paths

- Add required tools to `home.packages` / `environment.systemPackages` so
  configs use plain command names; avoid inlining `lib.getExe`/`getExe'` store
  paths in aliases or config strings unless a fixed store path is explicitly
  needed.

## File Organization

Split a module when it exceeds ~200 lines or covers multiple related programs:
`default.nix` imports sibling submodules (e.g. `shells/{default,bash,zsh}.nix`).
