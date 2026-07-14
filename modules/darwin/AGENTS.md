# nix-darwin Modules

## Main Areas

- `archetypes/`: personal, workstation, and VM machine identities
- `suites/`: macOS capability bundles
- `services/`: LaunchDaemons and system services
- `desktop/`: window-manager integration
- `programs/`: macOS-specific application integration
- `nix/`: Nix daemon, Linux builder, Rosetta builder
- `security/`: GPG, sops, sudo
- `system/`: environment, fonts, input, interface, logging, networking, power,
  TCC
- `tools/homebrew/`: declarative Homebrew integration
- `environments/`, `home/`, `user/`: platform and Home Manager glue

## Homebrew and Defaults

- Use Homebrew for macOS-integrated GUI applications, self-updating apps, or
  software unavailable from nixpkgs. Prefer Nix for CLI and development tools.
- Put system-wide preferences in `system.defaults.*` here. Put user preferences
  in Home Manager `targets.darwin.defaults`; some keys require
  `currentHostDefaults` or a new login.
- Keep LaunchDaemons here and LaunchAgents in `modules/home/`.
- Activation scripts run on every rebuild; keep them idempotent.
- Flag Yabai's SIP tradeoff when changing its setup.
- Use `nix-rosetta-builder` for x86_64 builds on Apple Silicon.

## Validation

```bash
nh darwin build
# or
nix build '.#darwinConfigurations.<host>.system'
```

Run `nh darwin switch` only when task includes activating result on current
host.
