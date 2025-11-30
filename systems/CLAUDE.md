# Host System Configuration

Per-host system configurations. Host-specific settings only - shared defaults
belong in `modules/`.

## Directory Structure

```
systems/
├── x86_64-linux/
│   └── {hostname}/
│       ├── default.nix        # Main host configuration
│       ├── hardware.nix        # Hardware detection & drivers
│       ├── network.nix         # Network configuration (optional)
│       ├── disks.nix           # Disk layout (optional)
│       └── specializations.nix # Boot specializations (optional)
├── aarch64-linux/
├── aarch64-darwin/
├── x86_64-iso/               # ISO images
└── x86_64-install-iso/       # Installation ISOs
```

## Basic Structure

### default.nix

```nix
{ lib, ... }:
let
  inherit (lib.khanelinix) enabled;
in
{
  imports = [
    ./hardware.nix
    ./network.nix      # Optional
  ];

  khanelinix = {
    # Archetype selection
    archetypes = {
      gaming = enabled;
      workstation = enabled;
    };

    # Environment
    environments.home-network = enabled;

    # Host-specific overrides
    suites.development.enable = true;

    security.sops = {
      enable = true;
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      defaultSopsFile = lib.getFile "secrets/${hostname}/default.yaml";
    };
  };

  system.stateVersion = "24.11";  # NixOS
  # system.stateVersion = 5;      # Darwin
}
```

### hardware.nix

```nix
{ lib, pkgs, modulesPath, ... }:
let
  inherit (lib.khanelinix) enabled;
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" ];
  };

  khanelinix.hardware = {
    cpu.amd = enabled;      # OR cpu.intel
    gpu.amd = enabled;      # OR gpu.nvidia
    audio.enable = true;
    bluetooth = enabled;
    storage = {
      enable = true;
      ssdEnable = true;
    };
  };

  # Nix build tuning for this CPU
  nix.settings = {
    cores = 16;
    max-jobs = 8;
  };
}
```

## What Belongs Here

**Host-specific configuration:**

- Archetype selection (gaming, workstation, server)
- Environment selection (home-network, etc.)
- Hardware configuration (CPU, GPU, storage)
- Network interface setup
- Display/monitor hardware configuration
- Host-specific service overrides
- Nix build settings tuned to hardware
- State version

**Example - Host overrides:**

```nix
khanelinix = {
  # This host's roles
  archetypes = {
    gaming = enabled;
    personal = enabled;
  };

  # This host's display manager config
  display-managers.gdm.monitors = ./monitors.xml;

  # This host's services
  services = {
    openssh.enable = true;
    samba = {
      enable = true;
      shares.public.path = "/home/user/Public/";
    };
  };
};
```

## What Does NOT Belong Here

**Shared configuration** (belongs in `modules/`):

- Program defaults
- Service implementations
- Module patterns
- Theme definitions

**User configuration** (belongs in `homes/`):

- User-specific programs
- Per-user preferences
- User secrets
- Suite selections for specific users

## Archetypes

Archetypes enable role-based configuration bundles:

- `gaming` - Gaming hardware and software
- `personal` - Personal use configuration
- `workstation` - Development workstation
- `server` - Server configuration

```nix
khanelinix.archetypes = {
  gaming = enabled;
  workstation = enabled;
};
```

## Environments

Environments enable network-specific configurations:

```nix
khanelinix.environments.home-network = enabled;
```

## Common Files

### network.nix (optional)

For custom networking beyond defaults:

```nix
{ config, ... }:
{
  systemd.network.networks."30-network-defaults-wired" = {
    matchConfig.Name = "en* | eth*";
    networkConfig = {
      DHCP = "ipv4";
      IPMasquerade = "ipv4";
    };
  };

  # Darwin
  networking = {
    computerName = "My MacBook Pro";
    hostName = "hostname";
  };
}
```

### disks.nix (optional)

For disko-based disk layouts:

```nix
{
  disko.devices.disk.main = {
    device = "/dev/nvme0n1";
    type = "disk";
    content.type = "gpt";
    # ... partition definitions
  };
}
```

### specializations.nix (optional)

For alternate boot configurations:

```nix
{
  specialisation.no-wayland.configuration = {
    khanelinix.programs.graphical.wms.hyprland.enable = lib.mkForce false;
  };
}
```

## Platform Differences

### NixOS

```nix
{
  system.stateVersion = "24.11";

  # Default session
  services.displayManager.defaultSession = "hyprland-uwsm";

  # Environment variables
  environment.variables.GSK_RENDERER = "ngl";
}
```

### Darwin

```nix
{
  system = {
    stateVersion = 5;
    primaryUser = "username";
  };

  networking = {
    computerName = "My MacBook Pro";
    hostName = "hostname";
    localHostName = "hostname";
  };

  environment.systemPath = [ "/opt/homebrew/bin" ];
}
```

## Key Decisions

### When to add to systems/ vs modules/

**Add to systems/ when:**

- Host-specific value (hostname, hardware, network)
- Applies only to this specific machine
- Hardware detection and drivers
- Machine-specific overrides

**Add to modules/ when:**

- Shared default for all hosts
- Reusable pattern
- Service implementation
- Program configuration

### State Version

Set once during initial setup, **never change**:

```nix
system.stateVersion = "24.11";  # NixOS
system.stateVersion = 5;        # Darwin
```

## Testing

```bash
# NixOS
nh os switch
nh os build

# Darwin
nh darwin switch
nh darwin build

# Test without activation
nix build .#nixosConfigurations.hostname.config.system.build.toplevel
nix build .#darwinConfigurations.hostname.system
```
