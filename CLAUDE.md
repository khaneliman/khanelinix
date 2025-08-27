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

## Specialized Agents and Commands

The khanelinix configuration includes specialized Claude Code agents and
commands designed for this Nix-based dotfiles system:

### Agents

#### Nix Specialists

- **Nix Expert**: General Nix language and NixOS configuration specialist
- **Nix Module Expert**: NixOS/Home Manager module creation and options design
  specialist
- **Nix Refactor**: Comprehensive Nix code refactoring, formatting, and
  optimization specialist
- **Flake Expert**: Nix flake management, inputs, and dependency specialist

#### Project Specialists

- **Dotfiles Expert**: khanelinix configuration specialist and maintainer -
  knows the complete module structure, host/user customizations, theme system,
  and patterns
- **System Config Expert**: NixOS system configuration and administration
  specialist
- **Template Designer**: Development environment and template creation
  specialist

#### General Development

- **Code Reviewer**: Specialized code review agent for development tasks
- **Security Auditor**: Security analysis and vulnerability assessment
  specialist
- **Documenter**: Technical documentation and README writer

### Custom Commands

#### Nix Commands

- `nix-refactor [path] [--style-only] [--fix-let-blocks] [--fix-lib-usage]`:
  Automatically fix Nix code style violations and refactor patterns
- `nix-check [path] [--build] [--eval] [--format]`: Comprehensive Nix code
  validation and formatting
- `module-scaffold [name] [--nixos] [--home] [--darwin]`: Create new module
  templates with proper structure
- `option-migrate [from] [to]`: Migrate deprecated options to new alternatives
- `template-new [template-name] [target-dir]`: Create new projects from
  khanelinix templates
- `flake-update [input] [--all] [--commit]`: Update flake inputs with proper
  commit messages

#### Git Commands

- `add-and-format [files]`: Stage files and run formatters before commit
- `commit-changes [--all] [--amend]`: Commit with contextual messages based on
  changes
- `commit-msg [type] [message]`: Generate conventional commit messages
- `git-review [target-branch]`: Comprehensive git history and diff review

#### Quality Assurance

- `quick-check [path]`: Fast validation of code quality and formatting
- `deep-check [path] [--security] [--performance]`: Comprehensive code analysis
- `style-audit [path] [--fix]`: Style and convention compliance check
- `dependency-audit [--unused] [--conflicts] [--security]`: Analyze and optimize
  dependencies
- `module-lint [path] [--fix]`: Lint Nix modules for common issues

#### Project Management

- `changelog [version] [--auto] [--format=md|nix]`: Generate changelogs from git
  history

### When to Use Specialized Agents

- **Use Dotfiles Expert** when working with khanelinix-specific configurations,
  understanding module interactions, or making system-wide changes
- **Use Nix specialists** for language-specific tasks, module creation, or
  refactoring Nix code
- **Use Security Auditor** when reviewing security configurations, analyzing
  dependencies, or implementing security features
- **Use Code Reviewer** after significant changes or before committing complex
  modifications
- **Use quality commands** before commits or when maintaining code health
