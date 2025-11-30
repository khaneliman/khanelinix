# KhaneliNix Constitution

**This is a Flake-based NixOS/nix-darwin dotfiles configuration.**

## Core Principles

1. **Modular Architecture**: Configuration split by platform
   (nixos/darwin/home/common)
2. **Namespace Scoping**: All options under `khanelinix.*`
3. **Home-First**: Prefer home-manager modules over system modules when possible
4. **Functional Style**: Pure functions, minimal side effects

## Essential Commands

- **Format**: `nix fmt`
- **Check build**:
  `nix build .#nixosConfigurations.${host}.config.system.build.toplevel`
- **Rebuild**: `sudo nixos-rebuild switch --flake .#${host}`

## Universal Style Rules

- **No `with lib;`** - use `inherit (lib)` or inline `lib.` prefix
- **Naming**: camelCase (vars), kebab-case (files/dirs)
- **Options**: Always `khanelinix.*` namespaced
- **Conditionals**: Prefer `lib.mkIf` over `if then else`

## Directory Structure

```
modules/
├── common/     # Shared cross-platform modules
├── nixos/      # NixOS system configuration
├── darwin/     # macOS system configuration
└── home/       # Home Manager user configuration
```

## Context Loading

Claude Code loads CLAUDE.md files recursively. Each subdirectory has focused
context:

- Working in `modules/nixos/`? Load system-level patterns
- Working in `modules/home/programs/`? Load application configs
- Working in `modules/common/`? Load shared abstractions

**See subdirectory CLAUDE.md files for domain-specific guidance.**
