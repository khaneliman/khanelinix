# khanelinix Agent Guide

`AGENTS.md` is the canonical AI agent guide for this repository. If `CLAUDE.md`
is present, treat it as Claude-specific extensions layered on top of this file.

## Project Snapshot

Flake-based NixOS + nix-darwin + Home Manager configuration for khanelinix.

## Core Principles

1. Modular architecture split by platform (`modules/nixos`, `modules/darwin`,
   `modules/home`, `modules/common`)
2. Namespace scoping under `khanelinix.*`
3. Home-first: prefer Home Manager modules when root privileges are not required
4. Functional style with explicit, composable Nix expressions

## Essential Commands

- `nix fmt`
- `nix flake check`
- `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
- `sudo nixos-rebuild switch --flake .#<host>`
- `darwin-rebuild switch --flake .#<host>`

## Repository Map

- `flake.nix`, `flake/`: top-level flake outputs and flake-parts modules
- `modules/`: reusable modules by platform
- `systems/`: per-host system configs
- `homes/`: per-user Home Manager configs
- `lib/`: custom library functions
- `packages/`: custom package derivations
- `templates/`: flake templates
- `secrets/`: encrypted secret material (sops-nix)

## Coding Rules

- Never use `with lib;`; prefer explicit `inherit (lib) ...` or `lib.<fn>`.
- Keep options under `khanelinix.*` when building reusable modules.
- Prefer `lib.mkIf`, `lib.optionals`, and `lib.optionalString` over broad
  `if/then/else` in module configs.
- Use camelCase for variables and kebab-case for files/directories.
- Keep changes scoped. Do not perform broad refactors unless requested.

## Path-Specific Guidance

Read these when touching matching paths:

- `modules/**`: `.claude/rules/nix-style.md`
- `modules/common/**`: `.claude/rules/common.md`
- `modules/nixos/**`: `.claude/rules/nixos.md`
- `modules/darwin/**`: `.claude/rules/darwin.md`
- `modules/home/**`: `.claude/rules/home-manager.md`
- `systems/**`, `homes/**`: `.claude/rules/hosts.md`
- `lib/**`: `.claude/rules/lib.md`
- `packages/**`, `templates/**`: `.claude/rules/packages.md`

## Validation and Safety

- Run the smallest meaningful validation for the changed scope.
- Never commit secrets or plaintext keys.
- Use `sops-nix` patterns for sensitive data.

## Commit Style

Use component-based commit messages: `component: description` Examples:
`darwin: tune dock defaults`, `docs: update agent guidance`
