This file provides guidance to AI coding agents like Claude Code
(claude.ai/code), Cursor AI, Codex, Gemini CLI, GitHub Copilot, and other AI
coding assistants when working with code in this repository.

# khanelinix AI Agent Guide

## Project Overview

Flake-based NixOS, nix-darwin, and Home Manager configuration for khanelinix.
Built using `flake-parts` for modularity.

## Core Architecture

- **`modules/`**: Reusable modules split by platform.
  - `common/`: Shared between NixOS and Darwin.
  - `home/`: Home Manager modules (user-space).
  - `nixos/` / `darwin/`: System-level configurations.
- **`systems/`**: Host-specific system configurations (NixOS/Darwin).
- **`homes/`**: User-specific Home Manager configurations.
- **`lib/`**: Custom Nix library extensions.
- **`packages/`**: Custom package derivations.
- **`flake/`**: Partitioned flake outputs (apps, overlays, etc.).

## Core Principles

1. **Home-First**: Prefer Home Manager (`modules/home`) for user-space configs
   (dotfiles, programs) over system modules.
2. **Namespace Scoping**: Always place options under `khanelinix.*`.
3. **Explicit Imports**: Never use `with lib;`. Use `inherit (lib) ...` or
   explicit `lib.<fn>`.
4. **Modular & Composable**: Split large modules (>200 lines) into sub-modules
   in a directory.

## Essential Commands

- **Format Code**: `nix fmt`
- **Check Flake**: `nix flake check`
- **Build System (NixOS)**: `nh os build` or
  `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
- **Switch System (NixOS)**: `nh os switch .` or
  `sudo nixos-rebuild switch --flake .#<host>`
- **Build/Switch Darwin**: `nh darwin build` / `nh darwin switch .`
- **Update All Inputs**: `nix run .#update-all`

## Coding Style & Patterns

- **Naming**: `camelCase` for Nix variables/options, `kebab-case` for files and
  directories.
- **Option Path**: `khanelinix.{category}.{subcategory}.{name}`.
- **Home Manager + System Access**: HM modules use `osConfig ? {}` to access the
  host system's configuration.
- **Conditionals**: Prefer `lib.mkIf` for entire configuration blocks.
- **Secrets**: Use `sops-nix`. Never commit secrets in plaintext. Use
  `lib.getFile "secrets/..."` helpers.
- **Custom Helpers**: Check `lib.khanelinix` for common helpers like `enabled`
  and `disabled`.

## Module Template

```nix
{ config, lib, pkgs, osConfig ? {}, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.khanelinix.category.name;
in {
  options.khanelinix.category.name.enable = mkEnableOption "Description";
  config = mkIf cfg.enable {
    # implementation
  };
}
```

## Specific Guidance

- Refer to `.claude/rules/*.md` for platform-specific deep dives (NixOS, Darwin,
  Home Manager, Lib, etc.).
- When adding a new module, ensure it is imported in its parent `default.nix`.

## AI Tools Skills

- For atomic commit cleanup with follow-up fixes, use the `git-workflows` skill
  in `modules/common/ai-tools/skills/git-workflows/` (see `reference.md` and
  `examples.md` for the fixup + autosquash flow).
