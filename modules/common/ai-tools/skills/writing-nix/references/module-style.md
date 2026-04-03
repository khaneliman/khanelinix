# Module Style

Use clear, explicit module structure.

```nix
{ config, lib, ... }:
let
  cfg = config.some.path;
in {
  options.some.path.enable = lib.mkEnableOption "description";

  config = lib.mkIf cfg.enable {
    # implementation
  };
}
```

## Options And Merge Priority

- Define strict option types.
- In `mkOption`, use `default = ...;` for the option's default value.
- In config, use a normal assignment when the behavior should require an
  explicit override.
- Use `lib.mkDefault` only for soft defaults that should silently yield to a
  normal assignment from another module.
- Use `lib.mkForce` only for targeted fixes or must-win overrides.

Common pattern:

```nix
# Generic theme defaults
programs.kitty.settings.background_opacity = lib.mkDefault 0.9;

# Specialized theme override
programs.kitty.settings.background_opacity = 1.0;

# Targeted fix that must win
programs.kitty.settings.confirm_os_window_close = lib.mkForce 0;
```

## `mkMerge`

- Use `lib.mkMerge` only when composing multiple attrset fragments that need to
  merge together.
- Do not reach for `lib.mkMerge` for a single conditional block.
- Prefer the smallest composition that expresses the intent clearly.

## Option Surface

Do not expose options for hypothetical use cases. Keep interfaces minimal and
intentional.
