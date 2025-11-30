# Home User Configuration

Per-user Home Manager configurations. User-specific overrides only - shared
defaults belong in `modules/home/`.

## Directory Structure

```
homes/
├── x86_64-linux/
│   └── {username}@{hostname}/
│       └── default.nix
├── aarch64-darwin/
│   └── {username}@{hostname}/
│       └── default.nix
```

**Example:** `khaneliman@khanelinix/default.nix`

## Basic Structure

```nix
{ config, lib, pkgs, ... }:
let
  inherit (lib.khanelinix) enabled disabled;
in
{
  khanelinix = {
    user = {
      enable = true;
      name = "username";
    };

    # User-specific overrides
    environments.home-network = enabled;

    programs.graphical.wms.hyprland = {
      enable = true;
      prependConfig = "monitor=DP-1,5120x1440@120,0x0,1";
    };

    suites = {
      common = enabled;
      desktop = enabled;
      development.enable = true;
    };

    theme.catppuccin = enabled;
  };

  home.stateVersion = "24.11";
}
```

## What Belongs Here

**User-specific configuration:**

- Username and identity
- Monitor layouts and workspace assignments
- Per-user secrets (sops paths)
- Suite selections for this user
- Program overrides specific to this user's workflow
- User-specific packages (`home.packages`)
- Email accounts, SSH keys, Git identities

**Example - User-specific overrides:**

```nix
khanelinix.programs.graphical = {
  # User's monitor setup
  wms.hyprland.prependConfig = ''
    monitor=DP-3, 3840x2160@60, 1420x0, 2
    monitor=DP-1, 5120x1440@120, 0x1080, 1
    workspace = 1, monitor:DP-3, default:true
  '';

  # User's bar configuration
  bars.waybar = {
    fullSizeOutputs = [ "DP-1" ];
    condensedOutputs = [ "DP-3" ];
  };

  # User's browser settings
  browsers.firefox = {
    gpuAcceleration = true;
    settings."media.av1.enabled" = false;
  };
};
```

## What Does NOT Belong Here

**Shared configuration** (belongs in `modules/home/`):

- Program defaults and shared settings
- Application configurations used by multiple users
- Module implementations
- Theme definitions
- Reusable patterns

**System configuration** (belongs in `systems/`):

- Hardware settings
- System services
- Network configuration
- Boot configuration

## Common Patterns

### Minimal User

```nix
{
  khanelinix = {
    user = {
      enable = true;
      name = "username";
    };
    suites.common = enabled;
  };
  home.stateVersion = "24.11";
}
```

### Power User

```nix
{
  khanelinix = {
    user = {
      enable = true;
      name = "username";
    };

    environments.home-network = enabled;

    programs.graphical.wms.hyprland = {
      enable = true;
      prependConfig = "monitor=DP-1,5120x1440@120,0x0,1";
    };

    services.sops = {
      enable = true;
      defaultSopsFile = lib.getFile "secrets/${hostname}/${username}/default.yaml";
    };

    suites = {
      common = enabled;
      desktop = enabled;
      development = {
        enable = true;
        aiEnable = true;
        dockerEnable = true;
      };
      games = enabled;
      social = enabled;
    };

    theme.catppuccin = enabled;
  };

  home.stateVersion = "24.11";
}
```

### Disabling Unwanted Programs

```nix
khanelinix.programs.terminal = {
  # Disable tools not needed by this user
  emulators.kitty.enable = false;
  tools.jujutsu.enable = false;
};
```

## Suites

Suites enable groups of related programs. Common suites:

- `common` - Essential CLI tools
- `desktop` - Desktop applications
- `development` - Dev tools (with aiEnable, dockerEnable, nixEnable, etc.)
- `games` - Gaming platforms
- `social` - Communication apps
- `music` / `video` / `photo` - Media tools

```nix
khanelinix.suites = {
  common = enabled;
  development = {
    enable = true;
    aiEnable = true;
    dockerEnable = true;
  };
};
```

## Key Decisions

### When to add configuration to homes/ vs modules/

**Add to homes/ when:**

- User-specific value (monitor layout, personal preferences)
- Applies only to this user on this host
- User-specific secrets or identities

**Add to modules/ when:**

- Shared default for all users
- Reusable configuration pattern
- Program defaults and common settings

### State Version

Set once during initial setup, never change:

```nix
home.stateVersion = "24.11";
```

## Testing

Home-manager is integrated as a module in system configuration.

```bash
# Apply changes (NixOS)
nh os switch

# Test build without activation (NixOS)
nh os build

# Apply changes (Darwin)
nh darwin switch

# Test build (Darwin)
nh darwin build
```
