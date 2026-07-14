# Home Manager Modules

## Main Areas

- `programs/terminal/`: shells, editors, terminal emulators, CLI tools
- `programs/graphical/`: GUI apps, browsers, window managers, bars, launchers
- `services/`: user systemd units on Linux and LaunchAgents on Darwin
- `suites/`: capability bundles; use `mkDefault` so individual program and
  service settings remain overridable
- `roles/`: user roles that compose suites and related defaults
- `environments/`: reusable environment-specific behavior
- `host/`, `user/`, `system/`: Home Manager integration and shared user/system
  state
- `theme/`: theme families plus GTK, Qt, Stylix, and wallpaper integration

## Integration Rules

- Prefer native Home Manager program/service options over `home.file` or
  generated config. Use `xdg.configFile` when no native module surface exists.
- Keep user services here: systemd user units on Linux and LaunchAgents on
  Darwin.
- Accept `osConfig ? { }` when host configuration is needed. Use
  `pkgs.stdenv.hostPlatform` for platform branches.
- Gate shell integration against each configured shell instead of enabling it
  unconditionally.

  ```nix
  programs.zoxide.enableZshIntegration =
    config.khanelinix.programs.terminal.shell.zsh.enable;
  ```

## Theme Priority

- Theme precedence is explicit khanelinix theme, then Stylix fallback, then
  upstream module default.

## Validation

```bash
nix build '.#homeConfigurations."<user>@<host>".activationPackage'
```

For integrated homes, validate owning NixOS or Darwin configuration too.
