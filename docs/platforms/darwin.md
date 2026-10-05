# Darwin (macOS)

## Entry points

- Host configs: `systems/aarch64-darwin/<host>/default.nix`
- Modules: `modules/darwin/`
- Shared system modules: `modules/common/`

Use the public aggregate and arguments shown in [Start Here](../start-here.md).
Native Darwin verification is required; Linux evaluation is not runtime proof.

## Typical usage

```nix
khanelinix.suites.common.enable = true;
khanelinix.suites.desktop.enable = true;
```

## Notes

- Darwin modules handle system settings, Homebrew, and macOS services.
- Use Home Manager for user-space configuration.
