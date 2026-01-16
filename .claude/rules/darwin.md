---
paths:
  - "modules/darwin/**"
---

# nix-darwin macOS Modules

System-level macOS configuration using nix-darwin.

## When to Use darwin/

**Use darwin/ when:**

- Requires root/system privileges (LaunchDaemons, system services)
- macOS system preferences (`system.defaults.*`)
- System-wide configuration (networking, fonts, global settings)
- Homebrew packages (system-level installation)

**Use modules/home/ when:**

- User-space configuration (dotfiles, user programs)
- LaunchAgents (user services - Home Manager handles these)
- Application configs that don't need root
- User-specific defaults (`targets.darwin.defaults`)

**Use modules/common/ when:**

- System config that works identically on NixOS and Darwin
- No platform-specific APIs needed

## Categories

- **archetypes/**: personal, workstation, vm
- **desktop/wms/**: yabai, aerospace, skhd
- **nix/**: linux-builder, nix-rosetta-builder
- **system/**: input, interface, networking, fonts
- **tools/homebrew/**: GUI apps not in nixpkgs
- **services/**: system services (LaunchDaemons)

## Homebrew Usage

**Use for:**

- GUI apps not in nixpkgs (Discord, Spotify, etc.)
- Apps that self-update (browsers, Electron apps)
- Apps requiring macOS-specific integration

**Avoid for:**

- CLI tools (use Nix packages)
- Development tools (use Nix for reproducibility)
- Anything manageable declaratively in Nix

## System Preferences

### System-Level (nix-darwin)

nix-darwin uses `system.defaults.*` for **system-wide** preferences. Some
settings like `persistent-apps` are unique to nix-darwin:

```nix
# Direct usage - dock app list (unique to nix-darwin)
system.defaults.dock = {
  autohide = true;
  persistent-apps = [
    "/System/Applications/System Settings.app"
    "/System/Applications/Messages.app"
    { spacer = { small = true; }; }
    "/Applications/Firefox.app"
  ];
};
```

**When to wrap in `khanelinix.*` options:**

- Only when you need customization between different systems/hosts
- Only when the option needs to be toggled or configured at module level
- Not for "consistency" - use `system.defaults.*` directly otherwise

**Note:** Many individual dock settings (like `tilesize`) are also available in
Home Manager via `targets.darwin.defaults."com.apple.dock".*`, but
`persistent-apps` and hot corners are nix-darwin-only.

### User-Level (Home Manager)

For **user-specific** defaults, use Home Manager's `targets.darwin.defaults`:

```nix
# In modules/home/ (not modules/darwin/)
targets.darwin.defaults = {
  "com.apple.desktopservices" = {
    DSDontWriteNetworkStores = true;
    DSDontWriteUSBStores = true;
  };
};
```

**Note:** Some settings require re-login. Some only read from
`targets.darwin.currentHostDefaults`.

**Rule of thumb:** If it affects all users → `system.defaults.*` in darwin/. If
it's user-specific → `targets.darwin.defaults` in home/.

## Activation Scripts

Use activation scripts for settings not covered by nix-darwin:

```nix
system.activationScripts.postActivation.text = ''
  # Example: hidden preferences
  defaults write com.apple.finder ShowPathbar -bool true
'';
```

**Caution:** Run on every rebuild - keep them idempotent.

## macOS-Specific Considerations

- **SIP warning:** Yabai requires disabling SIP (not recommended for daily
  drivers)
- **Paths:** `/Users/$USER` (not `/home/`), `/opt/homebrew` (Apple Silicon)
- **Conditionals:** Use `pkgs.stdenv.hostPlatform.isDarwin` for Darwin-specific
  logic
- **Rosetta:** Use `nix-rosetta-builder` for x86_64 builds on Apple Silicon
- **Services:** LaunchDaemons (system/root) vs LaunchAgents (user via Home
  Manager)

## Testing

```bash
nix build .#darwinConfigurations.${host}.system
darwin-rebuild switch --flake .#${host}
```
