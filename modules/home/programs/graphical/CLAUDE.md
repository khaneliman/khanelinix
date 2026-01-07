# Graphical Programs Configuration

GUI applications, window managers, and desktop components configured via Home
Manager.

## Structure

```
graphical/
├── wms/                   # Window managers (hyprland, sway, aerospace)
├── bars/                  # Status bars (waybar, ironbar, ashell, sketchybar)
├── launchers/             # App launchers (anyrun, rofi, wofi, walker)
├── screenlockers/         # Screen lockers (hyprlock, swaylock)
├── browsers/              # Web browsers (firefox, chromium)
├── apps/                  # Standalone apps (discord, mpv, obs, zathura)
├── addons/                # Desktop utilities (swaync, mako, kanshi, mangohud)
├── editors/               # GUI editors (vscode)
└── desktop-environment/   # Full DEs (gnome)
```

**Pattern:**

```nix
khanelinix.programs.graphical.{category}.{program}.enable = true;
```

## Configuration Patterns

### Module Structure

Graphical programs follow this pattern:

```nix
{
  config,
  lib,
  pkgs,
  osConfig ? { },  # Optional system config access
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.programs.graphical.{category}.{program};
in
{
  options.khanelinix.programs.graphical.{category}.{program} = {
    enable = mkEnableOption "{program}";
  };

  config = mkIf cfg.enable {
    # Configuration...
  };
}
```

### Theme Integration

**Priority order (highest to lowest):**

1. **Module-specific themes:**

```nix
# Best: Explicit theme files per program
xdg.configFile."program/theme.conf".source =
  ./themes + "/${config.khanelinix.user.theme}.conf";
```

2. **Catppuccin module:**

```nix
# Good: Use catppuccin module when available
programs.waybar = {
  enable = true;
  catppuccin.enable = config.khanelinix.theme.catppuccin.enable;
};
```

3. **Stylix fallback:**

```nix
# Fallback: Let stylix handle it
stylix.targets.waybar.enable = true;
```

### Split Configuration

Complex programs split into multiple files:

```nix
# main module: wms/hyprland/default.nix
imports = [
  ./apps.nix          # App-specific rules
  ./binds.nix         # Keybindings
  ./layers.nix        # Layer rules
  ./windowrules/      # Window rules by app
  ./workspacerules.nix # Workspace config
];
```

**Benefits:**

- Easier to navigate
- Logical grouping
- Parallel edits
- Clearer git diffs

### Conditional Styling

Switch styles based on theme:

```nix
let
  # Choose style directory based on theme
  styleDir = if config.khanelinix.theme.catppuccin.enable
    then ./styles
    else ./base16-style;

  style = builtins.readFile "${styleDir}/style.css";
in
{
  xdg.configFile."waybar/style.css".text = style;
}
```

### System Config Access

Access NixOS configuration in home modules:

```nix
{
  osConfig ? { },  # Receive system config
  ...
}:
{
  config = mkIf cfg.enable {
    # Check if system service is enabled
    wayland.windowManager.hyprland = mkIf (osConfig.programs.hyprland.enable or false) {
      # Config...
    };
  };
}
```

### Hyprland Settings Structure

Use structured Nix instead of raw config strings:

```nix
wayland.windowManager.hyprland = {
  enable = true;

  settings = {
    general = {
      gaps_in = 5;
      gaps_out = 10;
    };

    bind = [
      "SUPER, Return, exec, kitty"
      "SUPER, Q, killactive"
    ];

    windowrule = [
      "match:class ^(pavucontrol)$, float on"
      "match:class ^(firefox)$, workspace 2"
    ];
  };
};
```

### Waybar Modular System

Each widget is a separate module:

```nix
khanelinix.programs.graphical.bars.waybar = {
  enable = true;

  modules = {
    clock.enable = true;
    cpu.enable = true;
    # Module-specific config
  };
};
```

### Wayland Support

Enable Wayland for Electron/Chromium apps:

```nix
home.sessionVariables = {
  NIXOS_OZONE_WL = "1";
};
```

## When to Create New Module

Create a new graphical program module when:

- App is GUI-based and used regularly
- App requires desktop integration (notifications, tray, etc.)
- App needs theme/compositor integration
- App has significant configuration

**Don't create module for:**

- Simple GUI apps with no config
- One-time use apps
- Apps better installed system-wide

## Module Template

```nix
{
  config,
  lib,
  pkgs,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.programs.graphical.{category}.{program};
in
{
  options.khanelinix.programs.graphical.{category}.{program} = {
    enable = mkEnableOption "{program} - brief description";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.{program} ];

    # If HM module exists:
    programs.{program} = {
      enable = true;
      # Configuration...
    };

    # XDG desktop file if needed:
    xdg.desktopEntries.{program} = {
      name = "{Program}";
      exec = "${pkgs.{program}}/bin/{program} %U";
      terminal = false;
    };
  };
}
```
