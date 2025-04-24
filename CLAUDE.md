# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Commands

- **Format code**: `nix fmt` (uses treefmt with nixfmt, deadnix, statix)
- **Run pre-commit hooks**: `nix run .#checks.${system}.pre-commit-hooks`
- **Check a specific system**:
  `nix build .#nixosConfigurations.${host}.config.system.build.toplevel`
- **Rebuild NixOS system**: `sudo nixos-rebuild switch --flake .#${host}`

## Code Style Guidelines

1. **Nix formatting**: Use nixfmt for consistent formatting
2. **Imports**: Group related imports together within the inputs or let binding
3. **Path structure**: Follow the Snowfall structure with modules/homes/systems
   hierarchy
4. **Naming**: Use camelCase for variables, kebab-case for files/directories
5. **Options**: Define namespace-scoped options (khanelinix.*)
6. **Conditionals**: Use mkIf for conditional configuration
7. **Organization**: Group related items within each module
8. **Theming**: Handle theme toggling with conditional paths and mkIf
   expressions

## Patterns and Conventions

- Use the Snowfall library for module organization
- Follow functional programming practices
- Keep configuration modular and reusable
- Handle host-specific customizations in home configuration
- Use sops-nix for secrets management
