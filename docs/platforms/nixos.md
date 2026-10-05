# NixOS

## Entry points

- Host configs: `systems/x86_64-linux/<host>/default.nix`
- Modules: `modules/nixos/`
- Shared system modules: `modules/common/`

For a neutral first host, use the complete public module composition in
[Start Here](../start-here.md), not a named fleet configuration.

## Typical usage

```nix
khanelinix.suites.common.enable = true;
khanelinix.suites.development.enable = true;
```

## Notes

- NixOS system options are surfaced under `khanelinix.*` in the options docs.
- Prefer NixOS modules for system services and hardware configuration.
