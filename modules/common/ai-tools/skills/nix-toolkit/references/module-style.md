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
- Use `mkBefore`/`mkAfter` for list ordering, not override priority. Ordering
  retains contributions that `mkForce` could discard.

Test default-only, normal-override, and conflicting definitions when changing
priority. Compare list contents and order with a second contributing module.
These choices affect behavior, not just style. See the
[NixOS option-definition manual](https://nixos.org/manual/nixos/stable/#sec-option-definitions).

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

For a single condition, use `mkIf enabled fragment`, not
`mkMerge [ (mkIf enabled fragment) ]`. Keep
`mkMerge [ base (mkIf extra additions) ]` when definitions must merge. Evaluate
both feature states and contributions from another module.

## Conditional Definitions

Use `mkIf` when conditional module definitions depend on final configuration. A
module-level `config = if config.feature.enable then ... else {};` can recurse
through the configuration being constructed. Delayed conditions address that
hazard; ordinary value selections do not need the same transformation.

Preserve all branches and their exclusivity. These module-body templates express
the same branch selection when `cfg` supplies the two Boolean values:

```nix
{
  config = if cfg.enable then {
    services.foo.enable = true;
  } else if cfg.experimental then {
    services.foo.mode = "experimental";
  } else { };
}
```

```nix
{
  config = lib.mkMerge [
    (lib.mkIf cfg.enable { services.foo.enable = true; })
    (lib.mkIf (!cfg.enable && cfg.experimental) {
      services.foo.mode = "experimental";
    })
  ];
}
```

Evaluate all four Boolean combinations with the owning option types. The
experimental definition must remain absent whenever `cfg.enable` is true. Use
the delayed form when `cfg` comes from `config`.

## Option Surface

Do not expose options for hypothetical use cases. Keep interfaces minimal and
intentional.

Keep fixed policy in local values; expose an option when actual hosts or users
need to vary it. Removing an existing option requires an interface migration,
not merely evaluating the current default successfully. Avoid generating a large
option surface when fixed values suffice; option declaration and merging add
evaluation work.

## Abstraction Boundaries

Extract repeated behavior when it has shared ownership and the same variation
points. Keep two short assignments explicit when a helper would need flags for
unrelated differences. Evaluate every caller, including exceptional cases.
