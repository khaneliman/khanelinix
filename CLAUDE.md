# KhaneliNix

Flake-based NixOS/nix-darwin dotfiles configuration.

## Core Principles

1. **Modular Architecture** - Config split by platform
   (nixos/darwin/home/common)
2. **Namespace Scoping** - All options under `khanelinix.*`
3. **Home-First** - Prefer home-manager modules over system modules
4. **Functional Style** - Pure functions, minimal side effects

## Essential Commands

```bash
nix fmt                                    # Format
nix flake check                            # Validate
nix build .#nixosConfigurations.HOST.config.system.build.toplevel  # Build
sudo nixos-rebuild switch --flake .#HOST   # NixOS rebuild
darwin-rebuild switch --flake .#HOST       # Darwin rebuild
```

## Directory Structure

```
modules/
├── common/     # Cross-platform shared modules
├── nixos/      # NixOS system configuration
├── darwin/     # macOS system configuration
├── home/       # Home Manager user configuration
├── systems/        # Per-host configuration
├── homes/          # Per-user configuration
├── lib/            # Custom library functions
├── packages/       # Custom package derivations
└── templates/      # Project templates
```

## Style Rules

See `.claude/rules/nix-style.md` for detailed Nix code style guidelines.
