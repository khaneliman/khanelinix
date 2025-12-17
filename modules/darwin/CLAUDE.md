# nix-darwin macOS Configuration

macOS-specific system configuration using nix-darwin. These modules configure
macOS system preferences and services.

## Module Categories

### Archetypes (`archetypes/`)

System profiles for different macOS use cases.

**Available:**

- `personal`: Personal Mac configuration
- `workstation`: Development workstation setup
- `vm`: VM optimizations (UTM, Parallels)

**Pattern:**

```nix
khanelinix.archetypes.workstation.enable = true;
```

### Desktop (`desktop/`)

Window managers and desktop environment configuration.

**Modules:**

- `wms`: Window management (Yabai, Aerospace, etc.)

**macOS window management:**

- Yabai requires SIP disabled (not recommended for daily driver)
- Aerospace: Native Swift alternative, no SIP disable needed
- Use skhd for keybindings

### Nix (`nix/`)

Nix-specific macOS configuration.

**Important modules:**

- `linux-builder`: Remote Linux builder for building Linux packages on macOS
- `nix-rosetta-builder`: Use Rosetta 2 for x86_64 builds on Apple Silicon

**Pattern for Apple Silicon:**

```nix
khanelinix.nix.nix-rosetta-builder.enable = true;
# Enables fast x86_64 emulation via Rosetta 2
```

### System (`system/`)

macOS system preferences and configuration.

**Modules:**

- `input`: Keyboard, mouse, trackpad settings
- `interface`: Dock, menu bar, finder preferences
- `networking`: Network configuration
- `logging`: System logging
- `fonts`: System fonts

**Key patterns:**

```nix
# Use nix-darwin's system.defaults
system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
system.defaults.dock.autohide = true;

# Wrap in khanelinix options for consistency
khanelinix.system.interface.dock.autohide = true;
```

### Tools (`tools/`)

macOS-specific tools and utilities.

**Homebrew (`tools/homebrew/`):** Use Homebrew for:

- GUI apps not in nixpkgs
- Apps that require macOS-specific integration
- Apps that self-update (browsers, etc.)

**Pattern:**

```nix
khanelinix.tools.homebrew.enable = true;
khanelinix.tools.homebrew.casks = [ "firefox" "discord" ];
```

**Avoid Homebrew for:**

- CLI tools available in nixpkgs
- Development tools
- Things that can be managed declaratively in Nix

### Services (`services/`)

macOS-specific services and daemons.

**Available:**

- `skhd`: Hotkey daemon for keybindings
- `jankyborders`: Window border highlighting
- `openssh`: SSH server
- `tailscale`: VPN mesh networking

**Service patterns:**

```nix
# LaunchAgents run as user
khanelinix.services.skhd.enable = true;

# LaunchDaemons run as system
khanelinix.services.tailscale.enable = true;
```

### Suites (`suites/`)

Bundled configurations for common macOS workflows.

**Available:**

- `common`: Essential tools
- `desktop`: Full desktop setup
- `development`: Dev environment
- `art`, `music`, `photo`, `video`: Creative work suites
- `business`: Business applications
- `social`: Communication apps

## macOS-Specific Patterns

### System Preferences

nix-darwin uses `system.defaults.*` for macOS preferences. Wrap these in
`khanelinix.*` options for consistency:

```nix
# modules/darwin/system/interface/dock/default.nix
{
  options.khanelinix.system.interface.dock = {
    autohide = mkEnableOption "dock autohide";
  };

  config = lib.mkIf cfg.enable {
    system.defaults.dock.autohide = cfg.autohide;
  };
}
```

### Activation Scripts

Use activation scripts for settings not covered by nix-darwin:

```nix
system.activationScripts.postActivation.text = /* Bash */ ''
  # Example: Set hidden preferences
  defaults write com.apple.finder ShowPathbar -bool true
'';
```

**Caution:** Activation scripts run on every rebuild. Keep them idempotent.

### SIP (System Integrity Protection)

Some tools require disabling SIP (e.g., Yabai). Document clearly:

```nix
# ⚠️  WARNING: This module requires SIP to be disabled
# Only use on non-production machines
```

## Cross-Platform Considerations

### Sharing with NixOS

Common configs go in `modules/common/`, platform-specific in `modules/darwin/`:

**Example: Git config**

- Base config: `modules/common/programs/terminal/git/`
- macOS keychain: `modules/darwin/programs/terminal/git/`
- Linux credential helper: `modules/nixos/programs/terminal/git/`

### Path Differences

macOS uses different paths:

- Home: `/Users/$USER` (not `/home/$USER`)
- Homebrew: `/opt/homebrew` (Apple Silicon) or `/usr/local` (Intel)
- Applications: `/Applications`

Use `pkgs.stdenv.isDarwin` for conditional logic:

```nix
xdg.configFile."app/config".source =
  if pkgs.stdenv.isDarwin
  then ./darwin-config
  else ./linux-config;
```

## Testing Darwin Changes

```bash
# Build without switching
nix build .#darwinConfigurations.${host}.system

# Build and check
nix flake check

# Apply configuration
darwin-rebuild switch --flake .#${host}

# Check for activation errors
sudo launchctl list | grep nix-darwin
```

## Common Gotchas

1. **Homebrew state:** Homebrew installs are stateful. Remove old casks manually
   if needed.
2. **Sudo password:** Some activation scripts may prompt for sudo password.
3. **SIP conflicts:** Tools requiring SIP disabled won't work on locked-down
   systems.
4. **File permissions:** macOS is strict about file permissions in certain
   directories.
5. **Rosetta 2:** Must be installed separately:
   `softwareupdate --install-rosetta`
