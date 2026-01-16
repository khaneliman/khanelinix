---
paths:
  - "modules/common/**"
---

# Common Cross-Platform Modules

**System-level** modules shared between NixOS and nix-darwin.

**Note:** This is for **system configuration** that works on both platforms. For
user-space config, use `modules/home/` (Home Manager is already cross-platform).

## When to Use common/

**Put here when:**

- System-level config that works identically on NixOS and Darwin
- Logic is platform-agnostic (doesn't depend on systemd, launchd, etc.)
- Reduces duplication between nixos/ and darwin/ system modules
- Defines shared system abstractions (fonts, locales, build settings)

**Keep platform-specific when:**

- Uses platform-specific APIs (systemd vs launchd)
- Different behavior needed per platform (Homebrew on Darwin only)
- Platform has unique requirements (macOS system preferences, NixOS boot config)

**Use modules/home/ when:**

- User-space configuration (dotfiles, user services)
- Home Manager already handles cross-platform concerns

## Categories

- **ai-tools/**: Claude Code agents, commands, skills
- **nix/**: language helpers, build utilities
- **programs/**: cross-platform application configs
- **suites/**: configuration bundles
- **system/**: fonts, shared system settings

## Theming

Prefer module-specific theme options over stylix defaults:

```nix
# Good: Use khanelinix theme option
khanelinix.user.theme = "catppuccin-mocha";

# Bad: Duplicate theme string everywhere
```

This allows theme to be set once and referenced throughout all modules.

## Platform-Specific Overrides

When platform-specific config is needed:

- Generic config: `modules/common/programs/`
- NixOS override: `modules/nixos/programs/`
- Darwin override: `modules/darwin/programs/`

Example: Git config is in `common/programs/git/`, but macOS keychain integration
is in `darwin/programs/git/`.
