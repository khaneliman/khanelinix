---
paths:
  - "modules/home/**"
---

# Home Manager Modules

Placement rules (home-first preference): `CONTRIBUTING.md` "Module
Organization". Repo-specific nudges only below.

## Categories

- **programs/terminal/**: shells, editors, CLI tools
- **programs/graphical/**: GUI apps, WMs, bars
- **services/**: user systemd units (Linux) or LaunchAgents (macOS via HM)
- **suites/**: bundled configs (common, desktop, development) — conveniences
  that enable multiple programs; individual programs stay overridable
- **theme/**: catppuccin, gtk, qt, stylix

## Repo Nudges

- Prefer built-in HM modules (`programs.git = { ... }`) over manual dotfiles
  (`home.file`); use `xdg.configFile` only when no HM module exists.
- Enable shell integrations conditionally per enabled shell:

  ```nix
  programs.zoxide.enableZshIntegration =
    config.khanelinix.programs.terminal.shells.zsh.enable;
  ```

- Access system config via the `osConfig ? { }` module arg
  (`osConfig.programs.hyprland.enable or false`); platform checks via
  `pkgs.stdenv.hostPlatform.isLinux` / `.isDarwin`.

## Theme Priority (highest to lowest)

1. Explicit custom theme (`khanelinix.theme.catppuccin` etc.)
2. Stylix fallback when enabled
3. Module defaults

## Testing

```bash
nh os switch      # NixOS (system + home)
nh darwin switch  # Darwin (system + home)
```
