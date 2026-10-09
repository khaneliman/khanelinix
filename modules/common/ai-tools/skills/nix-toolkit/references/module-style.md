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

Never use `attrs // lib.mkIf cond { ... }`. `mkIf` returns a tagged attrset;
`//` copies that tag onto the whole merged definition. A false condition drops
it all, while a true condition keeps only the conditional content, losing the
base keys in either case. Use `lib.optionalAttrs` for plain attrsets when the
condition can be evaluated eagerly, or `lib.mkMerge` with only the conditional
part wrapped in `lib.mkIf` for module definitions. Search for this shape because
evaluation can succeed while silently dropping values:

```bash
grep -rnE '^\s*//\s*(lib\.)?mkIf|\}\s*//\s*(lib\.)?mkIf' modules
```

Check evaluated values, not just evaluation success. Do not use `cfg ? attr` on
an `attrsOf` or `lazyAttrsOf` option to decide whether to emit a fallback: a
false leaf `mkIf` can leave the key present, while a parent `mkForce { }`
removes it. The presence test can therefore suppress a wanted default or
reintroduce one the user removed. Keep defaults in the option and let
`mkDefault` resolve priority. For mergeable freeform settings, put soft defaults
on each leaf; a whole-attrset `mkDefault` can lose unrelated defaults when a
sibling supplies one key. Moving defaults into generated text also breaks
consumers that read the public option.

Compare evaluated values against the base configuration with probes for a false
leaf `mkIf`, a parent `mkForce { }`, an explicit value, `null` where allowed,
and a consumer that reads the option. Test overriding an existing key, not only
adding a disjoint key.

## Module Arguments

Extra arguments reach module bodies three ways. They differ in when the value
resolves and in who must supply it.

|                        | `specialArgs`                                | `_module.args`                                  | `lib.modules.importApply`                   |
| ---------------------- | -------------------------------------------- | ----------------------------------------------- | ------------------------------------------- |
| Resolved               | Before any module body evaluates.            | Inside the fixpoint, like any other option.     | Before `evalModules` receives the module.   |
| Usable in `imports`    | Yes.                                         | No; it closes a recursion loop.                 | Yes.                                        |
| Supplied by            | The `evalModules` caller.                    | Any module, at any priority.                    | The module author, where it is defined.     |
| May depend on `config` | No.                                          | Yes.                                            | No.                                         |
| Typical contents       | Flake inputs within one owned configuration. | `pkgs`, generated values, internal helper sets. | Dependencies of exported or shared modules. |

Inside one configuration whose `evalModules` calls you control, choose
`specialArgs` for anything an `imports` list must consult, and `_module.args`
for everything else, because a module can then override it. Deciding an import
from a value that came out of `_module.args` fails with
`infinite recursion encountered`; see
[Option forensics](option-forensics.md#infinite-recursion).

### Exported And Shared Modules

A module that names an argument such as `inputs` works only where the caller
supplies that name through `specialArgs` or `_module.args`. The author of a
module exported as `nixosModules`, `darwinModules`, or `homeModules`, or shared
between configurations, does not control that caller. A consumer who supplies
nothing gets `attribute 'inputs' missing`. A consumer who supplies their own
flake inputs gives the module the wrong `inputs.self` and a different set of
inputs, so it fails on a missing attribute or evaluates against the wrong
source. Keep caller-supplied arguments for configurations you own, and bind an
exported module's dependencies where it is defined:

```nix
# module.nix: the outer function receives values bound by this flake.
{ self }:
{ lib, pkgs, ... }:
{
  options.services.foo.package = lib.mkOption {
    type = lib.types.package;
    default = self.packages.${pkgs.stdenv.hostPlatform.system}.foo;
  };
}
```

```nix
# flake.nix
{
  outputs =
    { self, nixpkgs }:
    {
      nixosModules.foo = nixpkgs.lib.modules.importApply ./module.nix { inherit self; };
    };
}
```

`importApply` is `import ./module.nix { inherit self; }` that also sets `_file`,
so errors still name `module.nix`. flake-parts exports the same helper. The
consumer's `evalModules` call receives an ordinary module and supplies nothing
extra. Because the value is bound before evaluation, the module may also use it
in `imports`.

Do not set `_module.args.<name>` from a reusable module to supply its own
dependencies. `_module.args` has type `lazyAttrsOf raw`, and `raw` does not
merge, so two modules that set the same name fail with
`is defined multiple times while it's expected to be unique` even when the
values are equal. `mkForce` hides that error only by overriding the argument for
every module.

Binding also changes module identity. A module imported by path is keyed by that
path, so importing it twice is harmless and `disabledModules` can name it.
`importApply` sets `_file` but not `key`, so its result is anonymous: imported
twice, it declares its options twice (`is already declared in`), and
`disabledModules` cannot match it by path. When an exported module can reach one
configuration through several imports, or consumers must be able to disable it,
give it a key:

```nix
{
  nixosModules.foo = {
    key = toString ./module.nix;
    _file = ./module.nix;
    imports = [ (import ./module.nix { inherit self; }) ];
  };
}
```

Key by path only when every application of that file uses the same arguments.
The module system keeps the first module with a given key and silently ignores
later ones, so a second application with different arguments disappears without
an error.

## Option Surface

Do not expose options for hypothetical use cases. Keep interfaces minimal and
intentional.

Keep fixed policy in local values; expose an option when actual hosts or users
need to vary it. Removing an existing option requires an interface migration,
not merely evaluating the current default successfully. Avoid generating a large
option surface when fixed values suffice; option declaration and merging add
evaluation work.

For option migrations, inspect the repository's rename and deprecation helpers
before writing compatibility logic. Use declarative rename specifications for
path-only changes, with explicit paths for case-sensitive or dotted native keys.
For example, Home Manager exposes settings migration helpers through
`lib.hm.deprecations`. A rename does not convert enum, unit, or representation
values; prefer an existing conversion helper and justify any custom conversion
or lower-level forwarding needed for condition or priority semantics. Do not
duplicate compatibility schemas or warnings already supplied by a helper.

## Abstraction Boundaries

Extract repeated behavior when it has shared ownership and the same variation
points. Keep two short assignments explicit when a helper would need flags for
unrelated differences. Evaluate every caller, including exceptional cases.
