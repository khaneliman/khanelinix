# Home Manager User Configuration

User-space configuration using Home Manager. These modules configure user
applications, dotfiles, and user services.

## Core Principle: Home-First

**Prefer home modules over system modules whenever possible.** User-space
configuration is:

- Easier to test (no sudo required)
- More portable across systems
- Faster to apply changes
- Better for multi-user systems

Only use system modules when you need root privileges or system-level
configuration.

## Module Categories

### Programs (`programs/`)

Application configuration and dotfiles. **This is the largest category.**

#### Terminal Programs (`programs/terminal/`)

CLI tools and terminal applications.

**Key categories:**

- **Shells:** bash, zsh, fish, nushell
- **Multiplexers:** tmux, zellij
- **Editors:** neovim (khanelivim), helix, emacs
- **Tools:** git, gh, lazygit, fzf, ripgrep, bat, eza, zoxide
- **Development:** direnv, devenv, language servers
- **File managers:** yazi, ranger, lf
- **Monitoring:** btop, htop, bottom

**Pattern:**

```nix
khanelinix.programs.terminal.tools.{tool}.enable = true;
khanelinix.programs.terminal.editors.{editor}.enable = true;
khanelinix.programs.terminal.shells.{shell}.enable = true;
```

#### Graphical Programs (`programs/graphical/`)

GUI applications and desktop programs.

**Key categories:**

- **Browsers:** firefox, chromium, brave
- **Communication:** discord, slack, telegram
- **Media:** mpv, vlc, spotify
- **Development:** vscode, jetbrains
- **Window Managers:** hyprland, sway, i3
- **Bars:** waybar, eww, ags
- **Launchers:** rofi, wofi, anyrun
- **Notifications:** swaync, mako, dunst

**Wayland-specific:**

- `hyprland`: Main Wayland compositor config
- `waybar`: Status bar with module configs
- `swaync`: Notification center
- `hyprlock`: Screen locker
- `hypridle`: Idle management

**Pattern:**

```nix
khanelinix.programs.graphical.wms.hyprland.enable = true;
khanelinix.programs.graphical.bars.waybar.enable = true;
```

### Services (`services/`)

User services and daemons (systemd user units).

**Common services:**

- `keyring`: Secret management
- `ssh-agent`: SSH key management
- `syncthing`: File synchronization
- `mpd`: Music server
- `hypridle`: Idle daemon for Hyprland
- `hyprpaper`: Wallpaper daemon
- `easyeffects`: Audio effects pipeline

**Pattern:**

```nix
khanelinix.services.{service}.enable = true;

# Creates: systemd.user.services.{service}
```

### Suites (`suites/`)

Bundled configurations for workflows.

**Available:**

- `common`: Essential user tools (git, shell, editor)
- `desktop`: Full desktop environment
- `development`: Development workflow
- `wlroots`: Wayland desktop components
- `art`, `music`, `photo`, `video`: Creative workflows
- `games`: Gaming setup
- `social`: Communication apps

**Pattern:**

```nix
khanelinix.suites.development.enable = true;
# Enables: git, gh, neovim, language servers, direnv, etc.
```

### Theme (`theme/`)

Theming and visual customization.

**Modules:**

- `catppuccin`: Catppuccin theme integration
- `gtk`: GTK theme and icons
- `qt`: Qt theme
- `stylix`: System-wide theming via stylix

**Theming hierarchy (priority order):**

1. **Module-specific theme options** (highest priority)
   ```nix
   khanelinix.programs.graphical.wms.hyprland.theme = "catppuccin-mocha";
   ```

2. **Catppuccin module** (mid priority)
   ```nix
   khanelinix.theme.catppuccin.enable = true;
   khanelinix.theme.catppuccin.flavor = "mocha";
   ```

3. **Stylix** (lowest priority, fallback)
   ```nix
   khanelinix.theme.stylix.enable = true;
   ```

**Always prefer module-specific theming over generic stylix.**

### System (`system/`)

User-level system configuration.

**Modules:**

- `xdg`: XDG base directory specification
- `env`: User environment variables
- `input`: Keyboard/mouse user preferences (complement to system-level)

### User (`user/`)

User metadata and preferences.

**Example:**

```nix
khanelinix.user = {
  name = "khaneliman";
  email = "khaneliniman@example.com";
  theme = "catppuccin-mocha";
};
```

## Configuration Patterns

### Option Structure

All home options follow:

```
khanelinix.{category}.{subcategory}.{program}.{option}
```

**Examples:**

```nix
khanelinix.programs.terminal.shells.zsh.enable = true;
khanelinix.programs.graphical.wms.hyprland.settings = { };
khanelinix.services.syncthing.folders = { };
```

### Enable Patterns

Three common patterns for enabling features:

**1. Simple enable:**

```nix
khanelinix.programs.terminal.tools.git.enable = true;
```

**2. Suite enable (bundles multiple programs):**

```nix
khanelinix.suites.development.enable = true;
# Implicitly enables: git, neovim, direnv, etc.
```

**3. Conditional enable:**

```nix
khanelinix.programs.graphical.bars.waybar.enable =
  lib.mkIf config.khanelinix.programs.graphical.wms.hyprland.enable true;
```

### XDG Configuration Files

Use `xdg.configFile` for application configs:

```nix
xdg.configFile."app/config.toml".source = ./config.toml;

# Or generate from Nix:
xdg.configFile."app/config.json".text = builtins.toJSON {
  setting = "value";
};
```

### Dotfile Management

**Prefer built-in Home Manager modules when available:**

```nix
# Good: Use programs.git
programs.git.enable = true;
programs.git.userName = "khaneliman";

# Bad: Manual dotfile copying
home.file.".gitconfig".source = ./gitconfig;
```

**Only use manual dotfiles for:**

- Apps without Home Manager modules
- Complex configs better managed as files
- Configs shared across multiple machines

### Shell Integration

Many tools integrate with shells:

```nix
programs.zoxide.enable = true;
programs.zoxide.enableZshIntegration = true;
programs.zoxide.enableBashIntegration = true;
```

**Pattern:** Always enable shell integrations when available.

## Application-Specific Patterns

### Hyprland Configuration

Hyprland config uses structured Nix:

```nix
khanelinix.programs.graphical.wms.hyprland = {
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
  };
};
```

### Waybar Modules

Waybar uses a module system. Each module is configured separately:

```nix
khanelinix.programs.graphical.bars.waybar = {
  enable = true;
  modules = {
    clock.enable = true;
    cpu.enable = true;
    # Each module has its own options
  };
};
```

### Terminal Emulators

Terminal emulators (kitty, alacritty, foot) should:

- Use theme from `khanelinix.user.theme`
- Configure fonts from `khanelinix.system.fonts`
- Enable shell integration where available

## Testing Home Changes

```bash
# Build without switching
nix build .#homeConfigurations.${user}@${host}.activationPackage

# Switch to new config
home-manager switch --flake .#${user}@${host}

# Or use the wrapper (if configured)
home-manager switch
```

## Common Gotchas

1. **File collisions:** Multiple modules writing to same XDG config file. Use
   `lib.mkMerge` or priorities.
2. **Service ordering:** User services may start before system services are
   ready. Use `After=` directives.
3. **Theme inconsistency:** Ensure all themed apps use same theme source
   (`khanelinix.user.theme`).
4. **Shell rc files:** Don't mix manual and managed shell configs - choose one
   approach.
5. **Dotfile links:** Home Manager creates symlinks to /nix/store - don't expect
   to edit them in place.

## When to Create New Modules

Create a new module when:

- Configuring an application not covered by existing modules
- Building a reusable configuration pattern
- Grouping related configuration options

**Module template:**

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.khanelinix.programs.category.program;
in
{
  options.khanelinix.programs.category.program = {
    enable = mkEnableOption "program description";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.program ];

    xdg.configFile."program/config".source = ./config;
  };
}
```
