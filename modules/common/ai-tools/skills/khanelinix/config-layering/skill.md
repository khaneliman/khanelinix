---
name: khanelinix-config-layering
description: "khanelinix 7-level configuration hierarchy and customization strategy. Use when deciding where to put customizations, understanding override precedence, or working with host/user specific configs."
---

# Configuration Layering

## 7-Level Hierarchy

From lowest to highest precedence:

1. **Common modules** - Cross-platform base functionality
2. **Platform modules** - OS-specific (nixos/darwin)
3. **Home modules** - User-space applications
4. **Suite modules** - Grouped functionality with defaults
5. **Archetype modules** - High-level use case profiles
6. **Host configs** - Host-specific overrides
7. **User configs** - User-specific customizations (highest priority)

## Customization Strategy

| What to customize      | Where                                 |
| ---------------------- | ------------------------------------- |
| Host hardware/services | `systems/{arch}/{hostname}/`          |
| Platform behavior      | `modules/nixos/` or `modules/darwin/` |
| User applications      | `modules/home/`                       |
| Personal preferences   | `homes/{arch}/{user@host}/`           |

## Host Configuration

```
systems/{arch}/{hostname}/
├── default.nix       # Host-specific system config
└── hardware.nix      # Hardware-specific settings
```

Example: `systems/x86_64-linux/khanelimain/default.nix`

## User Configuration

```
homes/{arch}/{username@hostname}/
├── default.nix       # User-specific home config
└── packages.nix      # User-specific packages
```

Example: `homes/x86_64-linux/khaneliman@khanelimain/default.nix`

## Override Precedence

```nix
# In module (low priority - can be overridden)
programs.git.userName = lib.mkDefault "Default Name";

# In host config (overrides module default)
programs.git.userName = "Host Specific";

# Force (highest priority - rarely needed)
programs.git.userName = lib.mkForce "Forced Value";
```

## Best Practice

Prefer customization in this order:

1. **Home configuration** wherever possible
2. **Host config** for hardware/host-specific
3. **Platform modules** for OS-specific behavior
4. **Common modules** for shared base functionality
