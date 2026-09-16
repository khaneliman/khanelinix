# Option Types

Pick the weakest type that still rejects the configurations you must reject.
Types are the cheapest place to enforce a constraint, because a type error names
the offending definition and its file; an assertion fires later with less
context, and a runtime failure names neither.

## Selection Order

Work down this list and stop at the first entry that fits.

1. **A stock `lib.types` entry.** Prefer `port`, `path`, `package`, `enum`,
   `attrsOf`, `listOf`, `nullOr`, `either`, `oneOf`, and the numeric ranges
   (`ints.between`, `ints.positive`, `numbers.nonnegative`) over hand-rolled
   checks.
2. **`lib.types.addCheck base predicate`** for a domain constraint on an
   existing type.
3. **`lib.types.submodule`** for a structured value with a known shape.
4. **`lib.types.submoduleWith`** when the submodule needs extra arguments, a
   module class, or full module semantics rather than the shorthand.
5. **`freeformType`** when upstream owns a large, fast-moving settings surface.
6. **`lib.types.deferredModule`** when the value _is_ configuration destined for
   another evaluation.
7. **`lib.mkOptionType`** only when none of the above can express the value.

## `addCheck`, Not `//`

Augment a type through `lib.types.addCheck`. Overriding `check` with an
attribute update breaks type merging, and nixpkgs detects it and throws, naming
`addCheck` in the message.

```nix
# Throws: "an ad-hoc `type // { check = ...; }' override"
type = lib.types.str // { check = value: builtins.match "[a-z]+" value != null; };

# Composes correctly
type = lib.types.addCheck lib.types.str (value: builtins.match "[a-z]+" value != null);
```

Give a checked type a description when the default reads poorly, since the
description is what users see in a type error:

```nix
type = lib.types.addCheck lib.types.str (v: builtins.match "[a-z][a-z0-9-]*" v != null)
  // {
    name = "identifier";
    description = "lowercase identifier";
  };
```

Updating `name` and `description` this way is how nixpkgs defines its own
checked types. The guard tests only whether `check` was replaced.

## Keep `check` Shallow

`check` runs on definition values during merging. Inspect the outermost
constructor only: is this an attrset, a list, a string. Deep traversal inside
`check` forces nested values earlier than the merge needs them, which turns
optional or conditionally defined fields into evaluation errors and can close a
fixpoint loop that would otherwise have stayed open.

Put structural and cross-field validation in `merge`, which runs once on the
surviving definitions and can `throw` with `lib.showOption loc` for a located
message. For anything beyond a single option's internal consistency, prefer an
assertion in the consuming module; see
[Assertions and warnings](assertions-and-warnings.md).

## `submodule` Versus `submoduleWith`

`lib.types.submodule modules` is shorthand for
`submoduleWith { shorthandOnlyDefinesConfig = true; modules = toList modules; }`.
That flag is the practical difference: with the shorthand, a bare attrset
definition means `config`, so definitions read like plain values. Reach for
`submoduleWith` when you need one of its other parameters:

| Parameter                    | Use when                                                                       |
| ---------------------------- | ------------------------------------------------------------------------------ |
| `specialArgs`                | Submodule bodies need an argument available before their own evaluation.       |
| `class`                      | The submodule belongs to a specific module class and should reject others.     |
| `description`                | The generated type description is unhelpful in documentation and errors.       |
| `shorthandOnlyDefinesConfig` | Definitions must be able to declare options or set `imports`, not just config. |

Do not reach for `submoduleWith { specialArgs = { inherit pkgs; }; }` on seeing
`attribute 'pkgs' missing`. NixOS and Home Manager already propagate `pkgs` into
submodules through `_module.args`; that error usually means the submodule is
being evaluated outside such a host, or the argument name is wrong. Fix the
propagation rather than pinning a second package set into the type.

## Open Schemas With `freeformType`

When upstream owns hundreds of settings that change every release, declaring
each one is a maintenance liability and a large option surface to merge. Declare
the settings you genuinely constrain and let the rest pass through.

```nix
options.services.example.settings = lib.mkOption {
  type = lib.types.submodule {
    freeformType = (pkgs.formats.toml { }).type;

    options = {
      listenPort = lib.mkOption {
        type = lib.types.port;
        default = 9100;
        description = "Port the daemon binds.";
      };
    };
  };
  default = { };
};
```

Prefer the `type` from a `pkgs.formats.*` generator over
`lib.types.attrsOf lib.types.anything`. The generator's type accepts exactly
what its serializer can write, so an unserializable value fails at the
definition with a located error instead of inside `generate`. Use the matching
`generate` for the file:

```nix
environment.etc."example/config.toml".source =
  (pkgs.formats.toml { }).generate "example.toml" cfg.settings;
```

Use `lib.types.lazyAttrsOf lib.types.anything` as the freeform type only when
values must stay unforced, such as a settings set whose entries reference
packages that may not be buildable on every platform.

Keep declared options for anything you validate, default, document, or read from
elsewhere in the module. Everything else belongs in the freeform bag.

## `deferredModule`

`lib.types.deferredModule` holds an unevaluated module: an attrset, a function,
or a path. Definitions merge into a single `imports` list rather than being
evaluated in place, and each contribution keeps its source location, so errors
still name the file that supplied it.

Use it when one evaluation must _carry_ configuration for a different one.
Typical cases are a flake-level module that contributes to Home Manager, a
per-guest module for containers or VMs, and any option whose value is "a module
for someone else to import".

```nix
options.myFeature.homeModule = lib.mkOption {
  type = lib.types.deferredModule;
  default = { };
  description = "Module applied to each managed Home Manager user.";
};

config.myFeature.homeModule = { pkgs, ... }: {
  home.packages = [ pkgs.ripgrep ];
};
```

The consuming side imports it inside the target evaluation, where its arguments
resolve against that evaluation's package set and module class rather than the
declaring one.

Two consequences worth remembering: contributions concatenate instead of
overriding, so `mkForce` on a `deferredModule` option does not suppress other
contributions the way it would for a scalar; and the option's own evaluation
never type-checks the module body, so mistakes surface at the import site.

Use `deferredModuleWith { staticModules = [ ... ]; }` when the deferred module
should always include a baseline and have its options appear in generated
documentation.

## Custom Types

`lib.mkOptionType` is a last resort. Before writing one, check whether
`addCheck`, `coercedTo`, `either`, or a submodule already expresses the value. A
custom type must define `name`, `description`, `check`, and `merge`, and should
define `merge` in terms of `lib.options.mergeOneOption`, `mergeEqualOption`, or
`mergeUniqueOption` rather than reimplementing priority handling.

A custom type without `functor` and `substSubModules` will not compose under
`either`, `nullOr`, or submodule substitution. If the type wraps another type,
copy the structure of a comparable nixpkgs type rather than inventing one.

## Verify

Evaluate at least: a valid definition, a definition that must be rejected, and
two definitions from different modules so the merge path runs. For a
`freeformType`, also evaluate an unknown attribute and confirm it reaches the
generated file. [Module testing](module-testing.md) covers running these as
checks rather than by hand.
