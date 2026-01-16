---
name: system-planning
description: NixOS system configuration and administration. Use when configuring system services, hardware setup, networking, security hardening, boot configuration, or system maintenance.
---

# NixOS System Planning Guide

Expert guidance for NixOS system-level configuration, administration, and
maintenance.

## Core Principles

1. **Declarative first** - Define desired state, let NixOS handle the rest
2. **Reproducibility** - Same config should produce same system
3. **Atomic updates** - Changes are all-or-nothing with rollback
4. **Security by default** - Minimize attack surface
5. **Stability focus** - Prioritize reliability over bleeding edge

## System Configuration Workflow

Copy this checklist when making system changes:

```
System Configuration Progress:
- [ ] Step 1: Identify requirements and constraints
- [ ] Step 2: Check existing configuration for conflicts
- [ ] Step 3: Plan changes in staging/VM first
- [ ] Step 4: Implement changes incrementally
- [ ] Step 5: Test each change before next
- [ ] Step 6: Document non-obvious decisions
- [ ] Step 7: Verify rollback works if needed
```

## Configuration Areas

### System Services

```nix
# Enable and configure services
services.openssh = {
  enable = true;
  settings = {
    PermitRootLogin = "no";
    PasswordAuthentication = false;
  };
};

services.nginx = {
  enable = true;
  recommendedGzipSettings = true;
  recommendedOptimisation = true;
  recommendedTlsSettings = true;
};
```

### Hardware Configuration

```nix
# hardware-configuration.nix (auto-generated, but can extend)
hardware.cpu.intel.updateMicrocode = true;
hardware.enableAllFirmware = true;

# GPU configuration
hardware.opengl = {
  enable = true;
  driSupport = true;
  driSupport32Bit = true;  # For Steam/gaming
};
```

### Networking

```nix
networking = {
  hostName = "myhost";
  networkmanager.enable = true;

  # Firewall
  firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
    allowedUDPPorts = [ ];
  };
};
```

### Boot Configuration

```nix
boot = {
  loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Kernel parameters
  kernelParams = [ "quiet" "splash" ];

  # Kernel modules
  kernelModules = [ "kvm-intel" ];
};
```

### User Management

```nix
users.users.myuser = {
  isNormalUser = true;
  description = "My User";
  extraGroups = [ "wheel" "networkmanager" "docker" ];
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAA..."
  ];
};

# Disable mutable users for reproducibility
users.mutableUsers = false;
```

## Security Hardening

### Essential Security Settings

```nix
security = {
  # Sudo configuration
  sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  # Audit logging
  auditd.enable = true;

  # AppArmor (alternative to SELinux)
  apparmor.enable = true;
};

# Disable unnecessary services
services.avahi.enable = false;

# Restrict kernel features
boot.kernel.sysctl = {
  "kernel.unprivileged_bpf_disabled" = 1;
  "net.core.bpf_jit_harden" = 2;
};
```

### Security Checklist

- [ ] SSH key-only authentication
- [ ] Firewall enabled with minimal ports
- [ ] Automatic security updates configured
- [ ] Audit logging enabled
- [ ] Unnecessary services disabled
- [ ] User privileges minimized

## Performance Tuning

### System Optimization

```nix
# Increase file descriptor limits
security.pam.loginLimits = [{
  domain = "*";
  type = "soft";
  item = "nofile";
  value = "65536";
}];

# Zram swap for better memory utilization
zramSwap = {
  enable = true;
  algorithm = "zstd";
  memoryPercent = 50;
};

# SSD optimization
services.fstrim.enable = true;
```

## Maintenance Procedures

### Regular Tasks

| Task               | Frequency           | Command                               |
| ------------------ | ------------------- | ------------------------------------- |
| Update system      | Weekly              | `sudo nixos-rebuild switch --upgrade` |
| Garbage collection | Monthly             | `sudo nix-collect-garbage -d`         |
| Check disk space   | Weekly              | `df -h`                               |
| Review logs        | Weekly              | `journalctl -p err -b`                |
| Test rollback      | After major changes | Boot previous generation              |

### Troubleshooting Quick Reference

| Issue               | Diagnostic                   | Resolution              |
| ------------------- | ---------------------------- | ----------------------- |
| Boot failure        | Boot previous generation     | Fix config, rebuild     |
| Service won't start | `systemctl status <service>` | Check logs, fix config  |
| Network issues      | `ip addr`, `ping`            | Check networking config |
| Disk full           | `ncdu /`                     | Run garbage collection  |
| Performance issues  | `htop`, `iotop`              | Identify bottleneck     |

## Decision Guide

### When to Use System vs Home Config

| Configuration       | System (nixos/) | Home (home/) |
| ------------------- | --------------- | ------------ |
| System services     | Yes             | No           |
| Hardware drivers    | Yes             | No           |
| Firewall rules      | Yes             | No           |
| User applications   | Prefer home     | Yes          |
| Desktop environment | Either          | Prefer home  |
| Shell configuration | Either          | Prefer home  |

## See Also

- **Module placement**: See
  [scaffolding-modules](../../khanelinix/scaffolding-modules/) for where to put
  system configs
- **Configuration layers**: See
  [configuring-layers](../../khanelinix/configuring-layers/) for override
  precedence
- **Flake management**: See [managing-flakes](../managing-flakes/) for input and
  dependency management
