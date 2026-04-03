# Option Design

Expose the smallest option surface that solves the real problem.

## Decision Rule

1. If the implementation detail should not vary, do not expose it as an option.
2. If the user is enabling or disabling a feature, prefer a single enable
   option.
3. If the user is choosing one of several modes, prefer an enum over multiple
   booleans.
4. If a group of related settings truly varies together, use a submodule or
   attrset shape. Do not jump there for one or two trivial values.

## Preferences

- Use `mkEnableOption` for simple feature toggles.
- Use enums for mutually exclusive modes.
- Prefer a small number of meaningful options over a “future-proof” bag of
  knobs.
- Name options by what they mean, not how they are implemented.
- Keep the namespace stable and unsurprising.

```nix
# BAD
options.example = {
  useDarkTheme = lib.mkEnableOption "dark theme";
  useLightTheme = lib.mkEnableOption "light theme";
};

# GOOD
options.example.theme = lib.mkOption {
  type = lib.types.enum [ "dark" "light" ];
  default = "dark";
};
```

```nix
# BAD
options.example.wrapperBinaryName = lib.mkOption {
  type = lib.types.str;
  default = "foo";
};
```

If the wrapper name is an implementation detail and users should not care, do
not expose it.
