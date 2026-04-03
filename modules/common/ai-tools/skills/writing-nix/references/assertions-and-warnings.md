# Assertions And Warnings

Use assertions and warnings sparingly, and only when the module system cannot
express the constraint more directly.

## Decision Rule

1. If the constraint can be expressed with the option type, do that first.
2. If the configuration is invalid and should stop evaluation, use an assertion.
3. If the configuration is still supported but deserves a user-visible nudge,
   use a warning.
4. If a configuration is valid, any warning about it should be silencable
   through user configuration or by selecting the non-legacy path.
5. Prefer using option priority and explicit values to silence warnings before
   introducing a separate override option.
6. If priority cannot express the override cleanly, introduce an option that
   changes the underlying behavior, not a `suppressWarning` toggle.
7. Do not use warnings or assertions as a substitute for clearer option design.

## Preferences

- Keep messages specific and actionable.
- Mention the exact conflicting options or values.
- Prefer one good assertion over many repetitive micro-assertions.
- Prefer warnings for deprecations, ignored settings, or surprising but valid
  combinations.
- Do not emit a warning forever for a valid configuration with no way for the
  user to acknowledge, silence, or migrate away from it.
- For default-transition warnings, prefer detecting whether the user is still on
  the implicit path by checking option priority, then silence the warning when
  the user pins either the legacy or new behavior explicitly.
- If a warning is attached to a legacy or compatibility mode, make sure the user
  can disable that mode or opt into the replacement behavior.
- If you need an extra option, it should be a real behavior override or force
  knob, not a warning-only escape hatch.
- Do not add a separate `suppressWarning`-style option just to hide a warning
  when normal assignment, `mkDefault`, or `mkForce` can already express the
  desired override.

```nix
assertions = [
  {
    assertion = !(cfg.enable && cfg.package == null);
    message = "example.enable requires example.package to be set.";
  }
];
```

```nix
warnings = lib.optionals (
  cfg.enable
  && options.example.mode.highestPrio >= 1500
) [
  ''
    The default value of `example.mode` will change in a future release.
    You are currently using the legacy default because no explicit value was set.
    To silence this warning and keep legacy behavior, set:
      example.mode = "legacy";
    To adopt the new behavior, set:
      example.mode = "modern";
  ''
];
```

```nix
options.example.autoEnableSources = lib.mkOption {
  type = lib.types.bool;
  default = true;
};

config = lib.mkIf (cfg.enable && cfg.autoEnableSources) {
  warnings = lib.optional (lib.types.isRawType cfg.sources) ''
    example.sources is raw Lua, so source auto-enablement cannot be inferred.
    To keep raw sources and silence this warning, set:
      example.autoEnableSources = false;
  '';
};
```

Use a separate override option only when the warning is about behavior that is
not cleanly represented by the warned option itself, such as automatic
inference, auto-enablement, or compatibility shims. The extra option should
change the behavior that caused the warning, not merely hide the message.
