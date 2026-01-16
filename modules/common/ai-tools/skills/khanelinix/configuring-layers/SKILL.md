---
name: configuring-layers
description: "khanelinix 7-level configuration hierarchy and customization strategy. Use when deciding where to put customizations, understanding override precedence, resolving option conflicts, or working with host/user specific configs."
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

## Quick Decision Tree

**Question: Where should I put this configuration?**

1. **Does it require sudo/root access?** → System modules (`nixos/` or
   `darwin/`)
2. **Is it hardware-specific?** → Host config (`systems/{arch}/{hostname}/`)
3. **Is it user-preference specific?** → User config
   (`homes/{arch}/{user@host}/`)
4. **Does it configure user applications?** → Home modules (`modules/home/`)
5. **Is it shared across platforms?** → Common modules (`modules/common/`)

Still unsure? Default to home modules - they're easiest to test and most
portable.

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

## Override Patterns by Use Case

### Pattern 1: Testing a new value (keep module default)

```nix
# In home config - temporarily override
programs.git.userName = "Test Name";  # Plain assignment

# Module default still exists for other hosts
```

### Pattern 2: Setting project-wide standard (weak default)

```nix
# In module
programs.git.userName = lib.mkDefault "Default Name";

# Easily overridden in host/user configs
```

### Pattern 3: Enforcing a requirement (strong override)

```nix
# In security-critical module
security.sudo.wheelNeedsPassword = lib.mkForce true;

# Cannot be overridden by downstream configs
```

## Common Override Scenarios

### Scenario: Different git config per host

```nix
# modules/home/programs/terminal/tools/git/default.nix
programs.git.userName = lib.mkDefault "khaneliman";

# homes/x86_64-linux/khaneliman@workhost/default.nix
programs.git.userName = "Work Name";  # Overrides for this host

# homes/x86_64-linux/khaneliman@personalhost/default.nix
# Uses module default ("khaneliman")
```

### Scenario: Override theme but not fonts

```nix
# Suite sets defaults
khanelinix.user.theme = lib.mkDefault "catppuccin-mocha";
khanelinix.user.font.mono = lib.mkDefault "JetBrainsMono";

# User overrides just theme
khanelinix.user.theme = "gruvbox";  # Plain assignment overrides mkDefault
# Font remains JetBrainsMono from suite
```

## Best Practice

Prefer customization in this order:

1. **Home configuration** wherever possible
2. **Host config** for hardware/host-specific
3. **Platform modules** for OS-specific behavior
4. **Common modules** for shared base functionality

## See Also

- **Module placement**: See [scaffolding-modules](../scaffolding-modules/) for
  determining where to place configuration
- **Option design**: See [designing-options](../designing-options/) for creating
  properly namespaced options
