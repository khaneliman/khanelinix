# Anti-Patterns

Choose explicit expressions that fit repository canon. The alternatives below
explain syntax and scope choices; valid local idioms need not be normalized.

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

When replacing `with`, resolve each identifier first. Lexical bindings take
precedence over names introduced by `with`; blindly adding the `with` prefix can
change the value. See the
[Nix language reference](https://nix.dev/manual/nix/2.35/language/syntax).

## `rec`

Prefer `let` for private intermediate values and `rec` for clear relationships
within an exported attrset. Both are valid; neither syntax proves a speedup.

Decision rule:

1. Use `let` when an intermediate should not be exported.
2. Keep `rec` when exported attributes refer to each other clearly and local
   canon permits it. Remove `rec` when no attribute needs that scope.
3. When changing forms, compare both exported names and values.

```nix
# Clear relationship between exported attributes
rec {
  version = "1.0";
  name = "pkg-${version}";
}

# Equivalent let form
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
exclusivity and fallback behavior when changing conditional structure. A value
selection such as `port = if cfg.tls then 443 else 80;` differs from conditional
module definitions; see
[Module conditionals](module-style.md#conditional-definitions).

```nix
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
