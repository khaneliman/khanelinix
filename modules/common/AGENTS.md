# Shared System Modules

## Ownership

- `modules/common/` owns reusable system-level behavior shared by NixOS and
  nix-darwin. Cross-platform user-space configuration still belongs in
  `modules/home/`.
- Keep systemd, launchd, Homebrew, macOS preference, and other platform API
  behavior in the corresponding platform tree.
- Layer platform-only additions at the matching path instead of forking the
  shared module.

## Main Areas

- `ai-tools/`: generated multi-provider agents, skills, hooks, and policy
- `fonts/`: shared font packages and naming
- `nix/`, `nixd/`: cross-platform Nix and nixd behavior
- `package-profile/`: shared package-tier selection
- `programs/`: reusable system-level application configuration
- `suites/`: shared capability bundles
- `system/`: fonts and other shared system settings
