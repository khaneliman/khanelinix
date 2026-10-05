# Home Manager

## Entry points

- User configs: `homes/<system>/<user>@<host>/default.nix`
- Modules: `modules/home/`

[Start Here](../start-here.md) supplies complete neutral Linux and Darwin home
examples. Named standalone homes inherit their matching host context. Building
them does not authorize activating a standalone profile for an integrated user.

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
  covers enrollment and repair of the Microsoft 365 work account shared by
  Thunderbird and vdirsyncer.
