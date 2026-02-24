## Core Principles

1. **Home-First**: Prefer Home Manager (`modules/home`) for user-space configs
   (dotfiles, programs) over system modules.
2. **Namespace Scoping**: Always place options under `khanelinix.*`.
3. **Explicit Imports**: Never use `with lib;`. Use `inherit (lib) ...` or
   explicit `lib.<fn>`.
4. **Modular & Composable**: Split large modules (>200 lines) into sub-modules
   in a directory.

## Coding Style & Patterns

- **Naming**: `camelCase` for Nix variables/options, `kebab-case` for files and
  directories.
- **Option Path**: `khanelinix.{category}.{subcategory}.{name}`.
- **Home Manager + System Access**: HM modules use `osConfig ? {}` to access the
  host system's configuration.
- **Conditionals**: Prefer `lib.mkIf` for entire configuration blocks.
- **Secrets**: Use `sops-nix`. Never commit secrets in plaintext. Use
  `lib.getFile "secrets/..."` helpers.
- **Custom Helpers**: Check `lib.khanelinix` for common helpers like `enabled`
  and `disabled`.

## Module Template

```nix
{ config, lib, pkgs, osConfig ? {}, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.khanelinix.category.name;
in {
  options.khanelinix.category.name.enable = mkEnableOption "Description";
  config = mkIf cfg.enable {
    # implementation
  };
}
```
