# Anti-Patterns

## `with`

Never use `with`. It hides scope, hurts static analysis, and makes Nix harder to
read and refactor.

```nix
# BAD
meta = with lib; { license = licenses.mit; };

# GOOD
meta = { license = lib.licenses.mit; };
```

## `rec`

Avoid `rec` when `let-in` is sufficient.

Decision rule:

1. If a value only needs to feed another value, prefer `let`.
2. Use `rec` only when the attrset genuinely needs self-reference or multiple
   attributes in the same set must refer to each other in place.
3. If `rec` is only saving a small amount of typing, do not use it.

```nix
# BAD
rec {
  version = "1.0";
  name = "pkg-${version}";
}

# GOOD
let
  version = "1.0";
in {
  inherit version;
  name = "pkg-${version}";
}
```

## Chained `if/else if/else`

Treat chained conditionals as an anti-pattern in Nix.

They are usually a sign that one of the more declarative tools should have been
used instead:

- `lib.mkIf` for module config fragments
- `lib.optional*` helpers for list/string/attrset composition
- attrset lookup for static multi-branch selection

Decision rule:

1. If you are composing module config, prefer `lib.mkIf` and the module system's
   merge semantics over `if/else` returning attrsets.
2. If you are conditionally adding to a list, string, or attrset in a plain
   expression, prefer `lib.optional`, `lib.optionals`, `lib.optionalString`, or
   `lib.optionalAttrs`.
3. If you are selecting from a fixed set of static values, prefer attrset
   lookup.

Use plain `if/else` only as a last resort when those tools are unavailable or
make the result less readable.

```nix
# BAD
config = if cfg.enable then {
  services.foo.enable = true;
} else if cfg.experimental then {
  services.foo.mode = "experimental";
} else { };

# GOOD
config = lib.mkIf cfg.enable {
  services.foo.enable = true;
};

# GOOD
home.packages = [ pkgs.git ] ++ lib.optionals cfg.extraTools [
  pkgs.fd
  pkgs.ripgrep
];

# GOOD
themeFile =
  {
    dark = ./dark.nix;
    light = ./light.nix;
  }.${themeName};
```
