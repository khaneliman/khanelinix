---
paths:
  - "modules/darwin/**"
---

# nix-darwin macOS Modules

Placement rules: `CONTRIBUTING.md` "Module Organization" and "Platform Module
Taxonomy". Repo-specific nudges only below.

## Categories

- **archetypes/**: personal, workstation, vm
- **desktop/wms/**: yabai, aerospace, skhd
- **nix/**: linux-builder, nix-rosetta-builder
- **system/**: input, interface, networking, fonts
- **tools/homebrew/**: GUI apps not in nixpkgs
- **services/**: system services (LaunchDaemons)

## Homebrew Policy

- Casks only for GUI apps not in nixpkgs, self-updating apps, or apps needing
  macOS-specific integration. CLI and dev tools come from Nix.

## Defaults Placement

- System-wide preferences → `system.defaults.*` here (some settings like
  `persistent-apps` and hot corners are nix-darwin-only).
- User-specific preferences → `targets.darwin.defaults` in `modules/home/` (some
  keys only read from `targets.darwin.currentHostDefaults`; some need re-login).
- LaunchDaemons (system/root) live here; LaunchAgents (user) go through Home
  Manager.

## Repo Nudges

- Activation scripts run on every rebuild — keep them idempotent.
- Yabai requires disabling SIP; flag this tradeoff when touching it.
- Use `nix-rosetta-builder` for x86_64 builds on Apple Silicon.

## Testing

```bash
nh darwin build   # or: nix build .#darwinConfigurations.${host}.system
nh darwin switch
```
