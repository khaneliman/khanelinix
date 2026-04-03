# Imports And Arguments

Keep module headers explicit and only accept the arguments you actually use.

## Preferences

- Prefer module headers like `{ config, lib, pkgs, ... }:` with only the needed
  names spelled out.
- Use `osConfig ? {}` in Home Manager modules only when the module genuinely
  needs to inspect system configuration.
- Group related imports or inherited names together.
- Avoid giant `let` blocks that exist only to rename imports.
- Do not use `with lib;`.

## Decision Rule

1. If a function argument is unused, drop it.
2. If a Home Manager module needs host-level facts, use `osConfig ? {}`.
3. If an imported value is used once or twice, prefer inline access over a
   rename.
4. If several related imported names are reused locally, a small `inherit (...)`
   is fine.

```nix
# GOOD
{ config, lib, pkgs, osConfig ? {}, ... }:
let
  cfg = config.example;
in {
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.ripgrep ];
  };
}
```
