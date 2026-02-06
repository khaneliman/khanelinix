# NixOS

## Entry points

- Host configs: `systems/<host>/default.nix`
- Modules: `modules/nixos/`
- Shared system modules: `modules/common/`

## Typical usage

```nix
khanelinix.suites.common.enable = true;
khanelinix.suites.development.enable = true;
```

## Notes

- NixOS system options are surfaced under `khanelinix.*` in the options docs.
- Prefer NixOS modules for system services and hardware configuration.
