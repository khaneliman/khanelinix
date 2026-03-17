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

9. **Source Patching in Derivations**:
   - Prefer `fetchpatch2` for upstream commits and pull requests when a fixed
     patch URL is available.
   - For `fetchpatch2`, start with `hash = lib.fakeHash;`, build once, and copy
     the `got:` SRI hash from the fixed-output derivation failure into the
     derivation.
   - Do **not** use `nix-prefetch-url` as the final hash source for
     `fetchpatch2`. `nix-prefetch-url` hashes the raw downloaded bytes, while
     `fetchpatch2` normalizes the patch before hashing its output.
   - `nix-prefetch-url` is still appropriate for plain `fetchurl` and similar
     raw-download fetchers.
   - Prefer `substituteInPlace` over ad-hoc `sed`/`perl` for local source edits
     inside derivations.
   - Prefer `--replace-fail` so builds fail loudly when upstream source changes,
     signaling that the patch should be reviewed or removed.

### Module Organization

- **Host specific customization**: Place in host named configuration modules
- **Platform specific customization**: Place in nixos/darwin modules
- **Home application specific customization**: Place in home modules
- **User specific customization**: Place in user home configuration
- **Prefer handling customization in home configuration**, wherever possible

## Commit Message Convention

This repository follows a **Conventional Commits style** format:

```
type(scope): description
```

### Examples:

- `feat(codex): add mcp integration`
- `fix(waybar): restore accidentally deleted icon`
- `refactor(nix): tweak gc schedule`
- `docs(ai-tools): add fixup/autosquash workflow to git skill`
- `chore(flake): lock update`

### Guidelines:

- Use lowercase for the description
- Keep the subject line under 50 characters when possible
- Use imperative mood ("add", "fix", "update", not "added", "fixed", "updated")
- No trailing period in the subject line
- Keep `type` to standard values (`feat`, `fix`, `refactor`, `docs`, `chore`)
- Keep `scope` specific to the primary area affected
- Breaking changes may use `!` (for example: `refactor(devShells)!: ...`)
- Subject is the what, Body is the how/why

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
2. Prefer one module per commit when changes are logically independent
3. Follow the commit message convention
4. Ensure pre-commit hooks pass
5. Test that the configuration builds successfully

## Security

- Never commit secrets or keys to the repository
- Use sops-nix for secrets management
- Follow security best practices in configurations
- Use the Security Auditor agent for security-related changes

Thank you for contributing to khanelinix!
