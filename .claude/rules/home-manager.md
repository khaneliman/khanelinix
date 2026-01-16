---
paths:
  - "modules/home/**"
---

# Home Manager Modules

User-space configuration via Home Manager.

## Core Principle: Home-First

**Prefer home modules over system modules.** User-space config is:

- Easier to test (no sudo required)
- More portable across systems
- Faster to apply changes
- Better for multi-user systems

## When to Use home/

**Use modules/home/ when:**

- User-space configuration (dotfiles, user programs)
- User services (systemd user units, LaunchAgents)
- Application configs that don't need root
- User-specific defaults (targets.darwin.defaults on macOS)

**Use modules/nixos/ or modules/darwin/ when:**

- Requires root/system privileges
- System-wide configuration affecting all users
- System services (systemd system units, LaunchDaemons)

**Use modules/common/ when:**

- System-level config shared between NixOS and Darwin
- Not user-space (that's what home/ is for)

## Categories

- **programs/terminal/**: shells, editors, CLI tools
- **programs/graphical/**: GUI apps, WMs, bars
- **services/**: user systemd units (Linux) or LaunchAgents (macOS via HM)
- **suites/**: bundled configs (common, desktop, development)
- **theme/**: catppuccin, gtk, qt, stylix

## Option Pattern

```nix
khanelinix.programs.terminal.shells.zsh.enable = true;
khanelinix.programs.graphical.wms.hyprland.enable = true;
khanelinix.suites.development.enable = true;
```

**When to create `khanelinix.*` options:**

- Only when you need customization between different users/hosts
- Only when the option needs to be toggled or configured at module level
- Not for wrapping every Home Manager option

**Use Home Manager directly when:**

- No need for cross-system customization
- One-off user-specific configuration

## Config Patterns

### Prefer Home Manager Modules

```nix
# Good: Use built-in HM module
programs.git = {
  enable = true;
  userName = "user";
  userEmail = "user@example.com";
};

# Bad: Manual dotfile
home.file.".gitconfig".source = ./gitconfig;
```

Use `xdg.configFile` only when no HM module exists.

### Shell Integrations

Enable shell integrations conditionally:

```nix
programs.zoxide = {
  enable = true;
  enableBashIntegration = config.khanelinix.programs.terminal.shells.bash.enable;
  enableZshIntegration = config.khanelinix.programs.terminal.shells.zsh.enable;
  enableFishIntegration = config.khanelinix.programs.terminal.shells.fish.enable;
};
```

### Platform-Specific Config

Use `osConfig` parameter to access system config:

```nix
{
  config,
  lib,
  pkgs,
  osConfig ? {},
  ...
}:
{
  # Conditional on system service
  programs.hyprland.enable = osConfig.programs.hyprland.enable or false;
}
```

Use `pkgs.stdenv.hostPlatform` for platform checks:

```nix
programs.bash.initExtra = lib.mkIf pkgs.stdenv.hostPlatform.isLinux ''
  # Linux-specific bash config
'';
```

## Theme Priority (highest to lowest)

1. **Explicit custom theme** (highest) - When user enables
   `khanelinix.theme.catppuccin` or similar
2. **Stylix** (mid) - Automatic theming fallback when no custom theme chosen
3. **Module defaults** (lowest) - Base defaults in each module

When implementing theming in modules:

- Provide sensible defaults
- Let stylix apply when enabled
- Allow explicit theme choice to override everything

## Suites vs Individual Programs

**Use suites when:**

- Enabling common workflows (development, desktop, gaming)
- User wants bundle of related tools

**Enable individual programs when:**

- User needs specific tool without bundle
- Fine-grained control over enabled programs

Suites are just conveniences that enable multiple programs. Users can still
override individual programs within suites.

## Testing

```bash
nh os switch      # NixOS (applies system + home)
nh darwin switch  # Darwin (applies system + home)

# Build without applying
nh os build
nh darwin build
```
