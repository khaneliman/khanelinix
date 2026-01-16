---
paths:
  - "systems/**"
  - "homes/**"
---

# Host and User Configuration

Per-host system config and per-user Home Manager config.

## systems/ (Per-Host System Config)

Host-specific **system-level** configuration.

**What belongs here:**

- Archetype selection (`khanelinix.archetypes.gaming.enable`)
- Hardware config (CPU, GPU, storage, detected hardware)
- Network interfaces and hostname
- Host-specific service overrides
- Nix build settings tuned to this machine's hardware
- Boot configuration

**What does NOT belong here:**

- Shared defaults (belongs in `modules/`)
- User-specific config (belongs in `homes/`)
- Reusable patterns (belongs in `modules/`)

**Structure:** `systems/{arch}/{hostname}/`

```
systems/x86_64-linux/my-laptop/
├── default.nix        # Main config: imports, archetypes, overrides
├── hardware.nix       # Hardware detection (nixos-generate-config output)
└── network.nix        # Optional: custom networking beyond defaults
```

**Example systems/x86_64-linux/my-laptop/default.nix:**

```nix
{ lib, ... }:
let
  inherit (lib.khanelinix) enabled;
in
{
  imports = [ ./hardware.nix ];

  khanelinix = {
    # This host's role
    archetypes.workstation = enabled;

    # This host's environment
    environments.home-network = enabled;

    # This host's overrides
    services.ollama.enable = true;
  };

  system.stateVersion = "24.11";
}
```

## homes/ (Per-User Config)

User-specific **Home Manager** configuration.

**What belongs here:**

- User identity (name, email, git config)
- Monitor layouts and workspace assignments (this user's setup)
- Suite selections for this user
- User-specific program overrides
- Per-user secrets (sops paths)

**What does NOT belong here:**

- Shared user defaults (belongs in `modules/home/`)
- System-level config (belongs in `systems/` or `modules/nixos|darwin/`)
- Reusable patterns (belongs in `modules/`)

**Structure:** `homes/{arch}/{user}@{host}/default.nix`

**Example homes/x86_64-linux/user@my-laptop/default.nix:**

```nix
{ lib, ... }:
let
  inherit (lib.khanelinix) enabled;
in
{
  khanelinix = {
    user = {
      enable = true;
      name = "myuser";
      email = "user@example.com";
    };

    # This user's monitor setup
    programs.graphical.wms.hyprland = {
      enable = true;
      prependConfig = ''
        monitor=DP-1,5120x1440@120,0x0,1
      '';
    };

    # This user's suite selections
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

## Key Decisions

### Host-specific vs Module?

**Put in systems/ when:**

- Unique to this specific machine
- Hardware-detected values
- This hostname, these network interfaces
- This machine's archetype

**Put in modules/ when:**

- Shared across multiple hosts
- Reusable pattern
- Default behavior

### User-specific vs Module?

**Put in homes/ when:**

- Unique to this user on this host
- This user's identity, email, git config
- This user's monitor layout
- This user's suite choices

**Put in modules/home/ when:**

- Shared across all users
- Default program configuration
- Reusable patterns

## State Version

Set once during initial setup, **never change**:

```nix
system.stateVersion = "24.11";  # NixOS (in systems/)
home.stateVersion = "24.11";    # Home Manager (in homes/)
system.stateVersion = 5;        # Darwin (in systems/)
```

**Why never change:** Controls compatibility behavior for stateful data.
Changing it can break existing data.

## Platform Differences

### NixOS (systems/x86_64-linux/ or systems/aarch64-linux/)

- Uses `nixosConfigurations`
- Has hardware detection:
  `imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];`
- Boot configuration required
- systemd services

### Darwin (systems/aarch64-darwin/ or systems/x86_64-darwin/)

- Uses `darwinConfigurations`
- No hardware detection (manual)
- No boot config
- LaunchDaemons for services
- May include Homebrew casks

## Testing

```bash
# NixOS
nh os build           # Build system + home
nh os switch          # Apply system + home
nix build .#nixosConfigurations.hostname.config.system.build.toplevel

# Darwin
nh darwin build       # Build system + home
nh darwin switch      # Apply system + home
nix build .#darwinConfigurations.hostname.system
```
