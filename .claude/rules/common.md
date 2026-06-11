---
paths:
  - "modules/common/**"
---

# Common Cross-Platform Modules

**System-level** modules shared between NixOS and nix-darwin. Placement rules:
`CONTRIBUTING.md` "Module Organization". User-space config belongs in
`modules/home/` (Home Manager is already cross-platform); platform-specific APIs
(systemd vs launchd, Homebrew, macOS preferences) stay in `modules/nixos/` or
`modules/darwin/`.

## Categories

- **ai-tools/**: Claude Code agents, commands, skills
- **nix/**: language helpers, build utilities
- **programs/**: cross-platform application configs
- **suites/**: configuration bundles
- **system/**: fonts, shared system settings

## Platform-Specific Overrides

Generic config lives here; platform overrides layer on top:

- Generic: `modules/common/programs/git/`
- NixOS-only additions: `modules/nixos/programs/git/`
- Darwin-only additions (e.g. keychain): `modules/darwin/programs/git/`
