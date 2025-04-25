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

1. **Library Usage**:
   - Avoid using `with lib;` - instead use `inherit (lib) ...` or inline `lib.`
     prefixes
   - Prefer inlining `lib.` usages to `inherit (lib)` when 1 or 2 usages of the
     library function.
   - Keep `let in` blocks scoped as close to usage as possible

2. **Imports**: Group related imports together within the inputs or let binding

3. **Naming**: Use camelCase for variables, kebab-case for files/directories

4. **Options**: Define namespace-scoped options (khanelinix.*)

   - Reduce option repetition by using a shared top level option
   - Use top level option values throughout configuration when possible

5. **Conditionals**: Prefer `lib.mkIf`, `lib.optionals`, `lib.optionalString`
   instead of `if then else` expressions.
   - Only use `if then else` when it makes the expression too complicated using
     other means.

6. **Organization**: Group related items within each module

7. **Theming**: Handle theme toggling with conditional paths and mkIf
   expressions
   - Prefer specific theme module customizations over stylix.
   - Prefer all theme modules over the defaults of each module.

8. **Reduce Repetition**: Utilize Nix functions and abstractions to minimize
   duplicated code

## Patterns and Conventions

- Follow functional programming practices
- Keep configuration modular and reusable
- Handle host specific customization in host named configuration modules
- Handle platform specific customization in nixos/darwin modules
- Handle home application specific customization in home modules
- Handle user specific customization in user home configuration
- Prefer handling customization in home configuration, wherever possible
- Use sops-nix for secrets management
