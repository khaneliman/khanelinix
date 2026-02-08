# Contributing to khanelinix

Thank you for your interest in contributing to khanelinix! This document
provides guidelines for contributing to this Nix-based dotfiles configuration.

## Code Style and Conventions

### Nix Code Style

1. **Library Usage**:
   - Avoid using `with lib;` - instead use `inherit (lib) ...` or inline `lib.`
     prefixes
   - Prefer inlining `lib.` usages to `inherit (lib)` when 1 or 2 usages of the
     library function
   - Keep `let in` blocks scoped as close to usage as possible

2. **Imports**: Group related imports together within the inputs or let binding

3. **Naming**:
   - Use camelCase for variables
   - Use kebab-case for files/directories

4. **Options**: Define namespace-scoped options (khanelinix.*)
   - Reduce option repetition by using a shared top level option
   - Use top level option values throughout configuration when possible

5. **Conditionals**: Prefer `lib.mkIf`, `lib.optionals`, `lib.optionalString`
   instead of `if then else` expressions
   - Only use `if then else` when it makes the expression too complicated using
     other means

6. **Organization**: Group related items within each module

7. **Theming**: Handle theme toggling with conditional paths and mkIf
   expressions
   - Prefer specific theme module customizations over stylix
   - Prefer all theme modules over the defaults of each module

8. **Reduce Repetition**: Utilize Nix functions and abstractions to minimize
   duplicated code

### Module Organization

- **Host specific customization**: Place in host named configuration modules
- **Platform specific customization**: Place in nixos/darwin modules
- **Home application specific customization**: Place in home modules
- **User specific customization**: Place in user home configuration
- **Prefer handling customization in home configuration**, wherever possible

## Commit Message Convention

This repository follows a **component-based** commit message format:

```
component: description
```

### Examples:

- `claude-code: enhance commit-changes with pattern recognition`
- `firefox: userchrome trimmed down`
- `hyprland: add walker to test`
- `flake.lock: update`
- `docs: add specialized agents and commands section`

### Guidelines:

- Use lowercase for the description
- Keep the subject line under 50 characters when possible
- Use imperative mood ("add", "fix", "update", not "added", "fixed", "updated")
- No trailing period in the subject line
- Component should match the primary area affected (module name, config area,
  etc.)

## Development Workflow

### Before Making Changes

1. **Format code**: Run `nix fmt` (uses treefmt with nixfmt, deadnix, statix)
2. **Run pre-commit hooks**: `nix run .#checks.${system}.pre-commit-hooks`
3. **Check a specific system**:
   `nix build .#nixosConfigurations.${host}.config.system.build.toplevel`

### Making Changes

1. Follow the code style guidelines above
2. Test your changes on your system
3. Ensure all formatting and checks pass
4. Use secrets management with sops-nix for any sensitive data

### Submitting Changes

1. Create atomic commits - each commit should represent one logical change
2. Follow the commit message convention
3. Ensure pre-commit hooks pass
4. Test that the configuration builds successfully

## Available Tools

### Claude Code Commands

The repository includes specialized Claude Code commands:

#### Nix Commands

- `nix-refactor [path] [--style-only] [--fix-let-blocks] [--fix-lib-usage]`
- `nix-check [path] [--build] [--eval] [--format]`
- `module-scaffold [name] [--nixos] [--home] [--darwin]`

#### Git Commands

- `commit-changes [--all] [--amend]`: Analyze and commit changes following repo
  conventions
- `add-and-format [files]`: Stage files and run formatters
- `commit-msg [type] [message]`: Generate conventional commit messages

#### Quality Assurance

- `quick-check [path]`: Fast validation of code quality and formatting
- `deep-check [path] [--security] [--performance]`: Comprehensive code analysis
- `style-audit [path] [--fix]`: Style and convention compliance check

### Specialized Agents

When using Claude Code, specialized agents are available:

- **Dotfiles Expert**: khanelinix configuration specialist
- **Nix Expert/Module Expert/Refactor**: Nix language specialists
- **System Config Expert**: NixOS system configuration specialist
- **Security Auditor**: Security analysis specialist

## Getting Help

- Check the [AGENTS.md](./AGENTS.md) file for shared agent guidelines
- If using Claude Code, also check [CLAUDE.md](./CLAUDE.md) for Claude-specific
  extensions
- Use the specialized Claude Code agents for complex tasks
- Ensure you understand the module structure before making changes

## Security

- Never commit secrets or keys to the repository
- Use sops-nix for secrets management
- Follow security best practices in configurations
- Use the Security Auditor agent for security-related changes

Thank you for contributing to khanelinix!
