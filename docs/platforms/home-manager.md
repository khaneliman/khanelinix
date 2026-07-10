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

## Operator guides

- [DavMail Work Account Authentication](home-manager-davmail-authentication.md)
  — enroll and repair the Microsoft 365 work account shared by Thunderbird and
  vdirsyncer.
