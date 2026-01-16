# Nix Code Style

Universal Nix code formatting and patterns for khanelinix.

## Quick Commands

- **Format code:** `nix fmt`
- **Fix style violations:** `/nix-refactor` command
- **Validate syntax:** Hooks run automatically on Edit/Write
- **Scaffold new module:** `/module-scaffold` - Follows these patterns
- **Update flake inputs:** `/flake-update` command

## Imports

**Never use `with lib;`** - it obscures function origins and causes namespace
pollution.

```nix
# Good: Explicit imports
let
  inherit (lib) mkIf mkEnableOption types;
  inherit (lib.strings) concatStringsSep;
in

# Also good: Inline lib prefix
config = lib.mkIf cfg.enable { };

# Bad: with statement
with lib;
```

## Naming Conventions

- **Variables:** camelCase (`myOption`, `enableFeature`, `cfgValue`)
- **Files/directories:** kebab-case (`my-module/`, `default.nix`,
  `my-program.nix`)
- **Options:** Always under `khanelinix.*` namespace
  - Pattern: `khanelinix.{category}.{subcategory}.{name}`
  - Example: `khanelinix.programs.terminal.shells.zsh.enable`

## Conditionals

**Prefer `lib.mkIf` over `if then else`** for module configs:

```nix
# Good: mkIf for module config
config = mkIf cfg.enable {
  programs.git.enable = true;
};

# Acceptable: if/then for values
value = if condition then "yes" else "no";

# Good: mkDefault for overridable defaults
programs.git.userName = mkDefault "user";

# Use sparingly: mkForce to override
programs.git.userName = mkForce "override";
```

## Module Structure Pattern

Standard module template:

```nix
{
  config,
  lib,
  pkgs,
  osConfig ? {},
  ...
}:
let
  inherit (lib) mkIf mkEnableOption mkOption types;
  inherit (lib.khanelinix) enabled disabled;

  cfg = config.khanelinix.category.program;
in
{
  options.khanelinix.category.program = {
    enable = mkEnableOption "program description";

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra configuration";
    };
  };

  config = mkIf cfg.enable {
    # Implementation
    programs.example = {
      enable = true;
      extraConfig = cfg.extraConfig;
    };
  };
}
```

**Key points:**

- Always extract `cfg` from `config.khanelinix.*` path
- Use `osConfig ? {}` in Home Manager modules to access system config
- Include `inherit (lib.khanelinix)` for common helpers

## Functions

```nix
# Pure functions only - same inputs = same outputs
myFunction = arg1: arg2: arg1 + arg2;

# Explicit parameter destructuring
myFunction = { name, value, extraArgs ? {} }:
  # implementation

# Use `inherit` for clarity
let
  inherit (inputs.nixpkgs) lib;
in
```

## Common Antipatterns

**Avoid `with` statements:**

```nix
# Bad: obscures origins
with lib; with pkgs;

# Good: explicit imports when used multiple times
let
  inherit (lib) mkIf mkOption mkEnableOption;
in

# Also good: inline lib. prefix when used once
config = lib.mkIf cfg.enable { };
```

**Other antipatterns:**

```nix
# Bad: if/then for module config
config = if cfg.enable then { ... } else {};

# Good: use mkIf instead
config = lib.mkIf cfg.enable { ... };

# Bad: impure functions
readFile /etc/config  # evaluation-time I/O
```

## File Organization

**Split files when:**

- Module exceeds ~200 lines
- Multiple related programs in same category
- Complex configuration needs breakdown

**Structure:**

```
programs/terminal/shells/
├── default.nix          # Imports submodules
├── bash.nix             # Individual shells
├── zsh.nix
└── fish.nix
```

## Formatting

- **Indentation:** 2 spaces (enforced by `nix fmt`)
- **Line length:** Aim for <100 chars, not strict
- **List items:** One per line for readability
- **Attribute sets:** Break across lines when >3 attributes

```nix
# Good: readable list
home.packages = with pkgs; [
  git
  vim
  ripgrep
];

# Good: multiline attrset
programs.git = {
  enable = true;
  userName = "user";
  userEmail = "user@example.com";
};
```

**Note:** 8 Nix skills apply automatically when needed (writing-nix,
validating-nix, managing-flakes, and others).
