# Anti-Patterns

These are authoring defaults, not automatic review findings. Apply repository
canon first. Use [Review scenarios](review-scenarios.md) to distinguish useful
local cleanup from equivalent styles worth leaving alone.

## `with`

Avoid top-level, block-level, and wide-scope `with`. Those forms hide scope,
hurt static analysis, and make Nix harder to read and refactor.

Expression-local `with` is fine when it applies to one value and makes a dense
expression clearer than repeated prefixes. This is common for option types.

```nix
# Consider simplifying
meta = with lib; { license = licenses.mit; };

# Preferred authoring form
meta = { license = lib.licenses.mit; };

# Preferred authoring form
type = with lib.types; nullOr (either str path);
```

Decision rule:

1. Prefer explicit qualification when `with` wraps a module body or config
   block, or leaves name origins unclear across unrelated fields.
   Expression-local package lists may follow local canon.
2. Allow `with` when it is scoped to a single assignment/expression and every
   unqualified name clearly comes from that scope.
3. Prefer `lib.types.*` or `inherit (lib.types) ...` only when that is clearer
   than expression-local `with`.

```nix
# Consider simplifying
options.foo = with lib; {
  enable = mkEnableOption "foo";
  mode = mkOption { type = types.enum [ "a" "b" ]; };
};

# Preferred authoring form
options.foo = {
  enable = lib.mkEnableOption "foo";
  mode = lib.mkOption { type = lib.types.enum [ "a" "b" ]; };
};
```

## `rec`

Avoid `rec` when `let-in` is sufficient.

Decision rule:

1. If a value only needs to feed another value, prefer `let`.
2. Use `rec` only when the attrset genuinely needs self-reference or multiple
   attributes in the same set must refer to each other in place.
3. If `rec` is only saving a small amount of typing, do not use it.

```nix
# Consider simplifying
rec {
  version = "1.0";
  name = "pkg-${version}";
}

# Preferred authoring form
let
  version = "1.0";
in {
  inherit version;
  name = "pkg-${version}";
}
```

## Chained `if/else if/else`

For chains that obscure composition, consider:

- `lib.mkIf` for module config fragments
- `lib.optional*` for list/string/attrset composition
- attrset lookup for static multi-branch selection

Decision rule:

1. If you are composing module config, prefer `lib.mkIf` and the module system's
   merge semantics over `if/else` returning attrsets.
2. If you are conditionally adding to a list, string, or attrset in a plain
   expression, prefer `lib.optional`, `lib.optionals`, `lib.optionalString`, or
   `lib.optionalAttrs`.
3. If you are selecting from a fixed set of static values, prefer attrset
   lookup.

Keep plain `if/else` when it expresses a value choice clearly. Preserve branch
exclusivity and fallback behavior when changing conditional structure.

```nix
# Consider simplifying
config = if cfg.enable then {
  services.foo.enable = true;
} else if cfg.experimental then {
  services.foo.mode = "experimental";
} else { };

# Preferred authoring form
config = lib.mkMerge [
  (lib.mkIf cfg.enable { services.foo.enable = true; })
  (lib.mkIf (!cfg.enable && cfg.experimental) {
    services.foo.mode = "experimental";
  })
];

# Preferred authoring form
home.packages = [ pkgs.git ] ++ lib.optionals cfg.extraTools [
  pkgs.fd
  pkgs.ripgrep
];

# Preferred authoring form
themeFile =
  {
    dark = ./dark.nix;
    light = ./light.nix;
  }.${themeName};
```
