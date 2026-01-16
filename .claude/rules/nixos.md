---
paths:
  - "modules/nixos/**"
---

# NixOS System Modules

System-level Linux configuration using NixOS.

## When to Use nixos/

**Use nixos/ when:**

- Requires root/system privileges (systemd system units, kernel modules)
- Hardware configuration (CPU, GPU, audio, Bluetooth, storage)
- System-wide services affecting all users
- Boot configuration and kernel parameters
- Security policies (sudo, PAM, polkit, firewall)
- System packages needed by all users

**Use modules/home/ when:**

- User-space configuration (dotfiles, user programs)
- systemd user units (not system units)
- Application configs that don't need root
- Per-user preferences and settings

**Use modules/common/ when:**

- System config that works identically on NixOS and Darwin
- No Linux-specific APIs needed (no systemd, kernel modules, etc.)

## Categories

- **archetypes/**: gaming, workstation, server, vm, wsl
- **hardware/**: audio, bluetooth, cpu, gpu, power, storage
- **display-managers/**: gdm, sddm, regreet, tuigreet
- **security/**: sops, sudo, gpg, polkit, pam
- **services/**: openssh, tailscale, printing, flatpak
- **system/**: boot, networking, locale, fonts

## Option Pattern

**When to wrap in `khanelinix.*` options:**

- Only when you need customization between different systems/hosts
- Only when the option needs to be toggled or configured at module level
- Not for wrapping every NixOS option

**Use NixOS options directly when:**

- No need for cross-system customization
- One-off system-specific configuration
- Standard NixOS patterns work fine

## systemd Services

### System Units (modules/nixos/)

Use for services running as root or system-wide:

```nix
systemd.services.my-service = {
  description = "My System Service";
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${pkgs.foo}/bin/foo";
    DynamicUser = true;  # Security: avoid running as root
  };
};
```

### User Units (modules/home/)

Use for user services - these go in Home Manager, not here:

```nix
# In modules/home/, not modules/nixos/
systemd.user.services.my-user-service = {
  Unit.Description = "My User Service";
  Service.ExecStart = "${pkgs.bar}/bin/bar";
  Install.WantedBy = [ "default.target" ];
};
```

## Hardware Detection

NixOS can detect hardware automatically:

```nix
# In systems/{arch}/{hostname}/hardware.nix
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" ];
  boot.kernelModules = [ "kvm-intel" ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/...";
    fsType = "ext4";
  };
}
```

Hardware modules in `modules/nixos/hardware/` provide common configurations that
can be toggled per-host.

## Boot Configuration

Required for NixOS (not needed on Darwin):

```nix
boot = {
  loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  kernelPackages = pkgs.linuxPackages_latest;
};
```

## Security Best Practices

- **Never store secrets in Nix store** - use `sops-nix`:
  ```nix
  sops.secrets.password = {
    sopsFile = lib.getFile "secrets/default.yaml";
    owner = "username";
  };
  ```

- **Minimize root services** - use `DynamicUser = true` when possible
- **Enable firewall** - `khanelinix.system.networking.firewall.enable = true`
- **Use sudo with minimal privileges** - configure `security.sudo.extraRules`

## Platform-Specific Considerations

- **systemd** - Linux-specific service management (Darwin uses LaunchDaemons)
- **Kernel modules** - Linux kernel configuration
- **Boot loader** - Required on NixOS, not on Darwin
- **Hardware detection** - `nixos-generate-config` for initial setup
- **File paths** - `/home/` (not `/Users/` like macOS)

## Testing

```bash
# Build without applying
nix build .#nixosConfigurations.${host}.config.system.build.toplevel

# Apply configuration
sudo nixos-rebuild switch --flake .#${host}

# Or use nh helper
nh os build    # Build system + home
nh os switch   # Apply system + home
```
