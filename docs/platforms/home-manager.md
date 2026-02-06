# Home Manager

## Entry points

- User configs: `homes/<user>/default.nix`
- Modules: `modules/home/`

## Typical usage

```nix
khanelinix.suites.common.enable = true;
khanelinix.programs.terminal.shells.zsh.enable = true;
```

## Notes

- Home Manager is the preferred place for user-space tools, shells, and apps.
- Home modules may read `osConfig` to align with system services.
