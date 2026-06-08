ALWAYS Read @CONTRIBUTING.md when making changes. Treat it as the source of
truth for code style, module taxonomy, commit conventions, and validation.

For any Nix code or module task, use the `writing-nix` skill before making
edits.

## Core Principles

1. **Home-First**: Prefer Home Manager (`modules/home`) for user-space configs
   (dotfiles, programs) over system modules.
2. **Namespace Scoping**: Always place options under `khanelinix.*`.
3. **Explicit Imports**: Follow the library/import guidance in @CONTRIBUTING.md.
4. **Modular & Composable**: Follow the module organization and taxonomy in
   @CONTRIBUTING.md.
5. **Skill Usage (Nix Work)**: For any Nix code or module task, use the
   `writing-nix` skill before making edits.

## Host Context

- Primary `khanelinix` workstation uses a Kinesis Advantage360 Pro split
  keyboard.
- For keybind, shortcut, launcher, window-manager, shell, editor, multiplexer,
  or workflow changes, optimize for split-keyboard ergonomics.
- Prefer home-row or thumb-cluster reachable binds, modal flows, and consistent
  cross-app patterns. Treat keyboard firmware layers/macros as available tools
  when they reduce app-specific chord complexity.
- Avoid designs that assume laptop/ANSI key placement, function-row reach, or
  dense same-hand multi-modifier chords.

## Coding Style & Patterns

- **Naming**: `camelCase` for Nix variables/options, `kebab-case` for files and
  directories.
- **Option Path**: `khanelinix.{category}.{subcategory}.{name}`; see
  @CONTRIBUTING.md for platform module taxonomy.
- **Home Manager + System Access**: HM modules use `osConfig ? {}` to access the
  host system's configuration.
- **Conditionals**: Prefer `lib.mkIf` for entire configuration blocks.
- **PATH vs Store Paths**: Prefer adding required tools to `home.packages` /
  `environment.systemPackages` so configs can use plain command names, instead
  of inlining store paths with `lib.getExe`/`getExe'` in shell aliases or config
  strings (unless a fixed store path is explicitly needed).
- **Secrets**: Use `sops-nix`. Never commit secrets in plaintext. Use
  `lib.getFile "secrets/..."` helpers.
- **Custom Helpers**: Check `lib.khanelinix` for common helpers like `enabled`
  and `disabled`.

## Git Workflow

- In sandboxed agent environments, set `PRE_COMMIT_HOME=/tmp/pre-commit` before
  `git commit` if pre-commit cannot write to `~/.local/cache/pre-commit`.

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
