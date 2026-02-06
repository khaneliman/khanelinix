# Darwin (macOS)

## Entry points

- Host configs: `systems/<host>/default.nix`
- Modules: `modules/darwin/`
- Shared system modules: `modules/common/`

## Typical usage

```nix
khanelinix.suites.common.enable = true;
khanelinix.suites.desktop.enable = true;
```

## Notes

- Darwin modules handle system settings, Homebrew, and macOS services.
- Use Home Manager for user-space configuration.
