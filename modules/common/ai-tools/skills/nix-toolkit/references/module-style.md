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

- Define strict option types. [Option types](option-types.md) covers selection,
  `addCheck`, `freeformType`, and submodules.
- In `mkOption`, use `default = ...;` for the option's default value.
- In config, use a normal assignment when the behavior should require an
  explicit override.
- Use `lib.mkDefault` only for soft defaults that should silently yield to a
  normal assignment from another module.
- Use `lib.mkForce` only for targeted fixes or must-win overrides.
- Use `mkBefore`/`mkAfter` for list ordering, not override priority. Ordering
  retains contributions that `mkForce` could discard.

Priority and order are independent axes. Every definition carries an override
priority, and the merge keeps only the definitions at the strongest priority
present; ordering then arranges the survivors.

| Wrapper                | Priority | Meaning                                                 |
| ---------------------- | -------- | ------------------------------------------------------- |
| `mkOptionDefault`      | 1500     | The option's own declared `default`.                    |
| `mkDefault`            | 1000     | Soft default, yields to any plain assignment.           |
| plain assignment       | 100      | The normal case.                                        |
| `mkImageMediaOverride` | 60       | Image and installer profiles; still loses to `mkForce`. |
| `mkForce`              | 50       | Must-win override.                                      |
| `mkVMOverride`         | 10       | `build-vm` and test harnesses.                          |
| `mkOverride n`         | n        | Arbitrary tier.                                         |

Lower numbers win. `mkBefore` and `mkAfter` are `mkOrder 500` and `mkOrder 1500`
on the separate ordering axis, where unordered values sit at 1000; their numbers
look like priorities but never discard anything.

Two definitions at the same priority must be mergeable by the option's type. For
a scalar type they are not, which is the usual source of the "defined multiple
times" and "conflicting definition values" errors. Diagnose those with
[Option forensics](option-forensics.md) rather than guessing which module wins.

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

## Module Arguments

Extra arguments reach module bodies two ways, and the difference is when they
resolve.

|                        | `specialArgs`                                     | `_module.args`                                  |
| ---------------------- | ------------------------------------------------- | ----------------------------------------------- |
| Resolved               | Before any module body evaluates.                 | Inside the fixpoint, like any other option.     |
| Usable in `imports`    | Yes.                                              | No; it closes a recursion loop.                 |
| Settable by a module   | No, it is fixed by the `evalModules` caller.      | Yes, including `mkDefault` and `mkForce`.       |
| May depend on `config` | No.                                               | Yes.                                            |
| Typical contents       | Flake inputs, target system, architectural flags. | `pkgs`, generated values, internal helper sets. |

Choose `specialArgs` for anything an `imports` list must consult, and
`_module.args` for everything else, because a module can then override it.
Deciding an import from a value that came out of `_module.args` fails with
`infinite recursion encountered`; see
[Option forensics](option-forensics.md#infinite-recursion).

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
