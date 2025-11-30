# NixOS System Configuration

NixOS-specific system-level configuration modules. These run with root
privileges and configure the base operating system.

## Module Categories

### Archetypes (`archetypes/`)

System profiles that bundle related functionality for specific use cases.

**Available:**

- `gaming`: Gaming system with GPU drivers, Steam, performance tuning
- `personal`: Personal desktop/laptop configuration
- `server`: Headless server configuration
- `vm`: Virtual machine optimizations
- `workstation`: Development workstation setup
- `wsl`: Windows Subsystem for Linux configuration

**Pattern:**

```nix
khanelinix.archetypes.workstation.enable = true;
# Enables: development tools, desktop environment, services
```

### Hardware (`hardware/`)

Hardware-specific configuration for different components.

**Categories:**

- `audio`: PipeWire, ALSA, audio routing
- `bluetooth`: Bluetooth support and management
- `cpu`: CPU-specific optimizations (Intel/AMD)
- `gpu`: Graphics drivers (NVIDIA, AMD, Intel)
- `power`: Battery management, TLP, power profiles
- `storage`: Disk configuration, TRIM, filesystem tuning
- `tpm`: TPM2 support for secure boot
- `yubikey`: YubiKey integration

**When adding hardware modules:**

- Auto-detect when possible using `lib.mkDefault`
- Provide override options for manual configuration
- Document hardware requirements in module

### Display Managers (`display-managers/`)

Login screen and session management.

**Available:** GDM, LightDM, regreet, SDDM, tuigreet

**Pattern:**

```nix
khanelinix.display-managers.sddm.enable = true;
khanelinix.display-managers.sddm.theme = "catppuccin-mocha";
```

### Security (`security/`)

Security hardening, authentication, and access control.

**Modules:**

- `sops`: Secret management with sops-nix
- `sudo`/`sudo-rs`: Privilege escalation
- `gpg`: GPG agent and smartcard support
- `polkit`: PolicyKit rules
- `pam`: PAM configuration
- `usbguard`: USB device authorization

**Critical:**

- Always test sudo/doas changes in VM first
- Keep emergency root access method
- Document security implications in module comments

### Services (`services/`)

System daemons and background services.

**Common services:**

- `openssh`: SSH server configuration
- `tailscale`: VPN mesh networking
- `printing`: CUPS printing support
- `flatpak`: Flatpak application support
- `ollama`: Local LLM server

**Service patterns:**

```nix
# Enable service
khanelinix.services.openssh.enable = true;

# Configure service-specific options
khanelinix.services.openssh.ports = [ 22 ];
khanelinix.services.openssh.permitRootLogin = false;
```

### System (`system/`)

Core system configuration.

**Modules:**

- `boot`: Bootloader, kernel, initrd
- `networking`: Network configuration, firewall
- `locale`: Localization, timezone, i18n
- `fonts`: System fonts
- `env`: Environment variables

**Boot configuration:**

- Use `systemd-boot` by default
- Secure boot via lanzaboote when available
- Keep kernel options minimal, prefer module parameters

### Virtualisation (`virtualisation/`)

Container and VM support.

**Available:**

- `kvm`: KVM/QEMU virtualization
- `podman`: Rootless container runtime

### Suites (`suites/`)

Bundled configurations for common scenarios.

**Available:**

- `common`: Base system essentials
- `desktop`: Full desktop environment
- `development`: Development tools and services
- `games`: Gaming-related packages and config
- `wlroots`: Wayland compositor support

## Platform-Specific Patterns

### System vs Home Configuration

**System (NixOS):** Hardware, services, security, system packages **Home (Home
Manager):** User dotfiles, application configs, user packages

**Rule:** If it requires root or system-level changes → NixOS module If it's
user-specific configuration → Home Manager module

### Override Pattern

Many NixOS modules provide base configuration, overridden in:

1. Host-specific config: `systems/x86_64-linux/${hostname}/default.nix`
2. User-specific config: `homes/x86_64-linux/${user}@${hostname}/default.nix`

**Example:**

```nix
# Base in modules/nixos/hardware/audio/default.nix
khanelinix.hardware.audio.enable = lib.mkDefault true;

# Override in systems/x86_64-linux/my-laptop/default.nix
khanelinix.hardware.audio.enable = true;
khanelinix.hardware.audio.extraDevices = [ "usb-dac" ];
```

## Security Considerations

- Never store secrets in Nix store (use sops-nix)
- Minimize `systemd.services.*.serviceConfig.User = "root"`
- Use `DynamicUser = true` for services when possible
- Enable firewall by default:
  `khanelinix.system.networking.firewall.enable = true`

## Testing System Changes

```bash
# Build without switching
nix build .#nixosConfigurations.${host}.config.system.build.toplevel

# Build and check for errors
nix flake check

# Test in VM (if available)
nixos-rebuild build-vm --flake .#${host}

# Switch to new configuration
sudo nixos-rebuild switch --flake .#${host}
```
