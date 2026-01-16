---
paths:
  - "lib/**"
---

# Library Functions

Custom reusable Nix functions extending nixpkgs.lib.

## When to Create a Lib Function

**Create in lib/ when:**

- Function is reused across multiple modules (3+ uses)
- Logic is complex and benefits from abstraction
- Pattern is common throughout codebase
- Function is pure (no side effects)

**Don't create lib function when:**

- Used only once or twice
- Simple one-liner
- Module-specific logic
- Better expressed inline

## Categories

### base64

Encoding/decoding utilities for secrets and data.

### file

- `getFile` - Absolute path from repo root
- `importDir` - Import all .nix files in directory
- `scanDir` - List directory contents

### module

- `enabled` / `disabled` - Shorthand for `{ enable = true/false; }`
- `mkOpt` - Create option with type, default, description
- `mkBoolOpt` - Boolean option helper
- `mkModule` - Module creation helper

### system

System configuration builders used in flake.nix:

- `mkSystem` - Create NixOS configuration
- `mkDarwin` - Create nix-darwin configuration
- `mkHome` - Create Home Manager configuration

### theme

- `getTheme` - Get theme configuration
- `mkColorScheme` - Create color scheme
- `applyTheme` - Apply theme to program

## Principles

- **Pure functions only** - no side effects, no I/O during evaluation
- **Same inputs → same outputs** - deterministic
- **Explicit parameters** -
  `{ inputs }: let inherit (inputs.nixpkgs.lib) ...; in { ... }`
- **Export via category** - `flake.lib.{category}.{function}`

## Usage

```nix
# In modules
let
  inherit (lib.khanelinix) enabled disabled;
  inherit (lib.khanelinix.file) getFile;
in
{
  khanelinix.programs.git = enabled;
  sops.defaultSopsFile = getFile "secrets/default.yaml";
}

# In flake.nix
nixosConfigurations.hostname = lib.khanelinix.system.mkSystem {
  hostname = "my-laptop";
  username = "myuser";
};
```

## Creating New Functions

```nix
# lib/myCategory/default.nix
{ inputs }:
let
  inherit (inputs.nixpkgs.lib) mapAttrs;
in
{
  myFunction = arg1: arg2: arg1 + arg2;
}
```

Then export in `lib/default.nix` under `flake.lib.myCategory`.

## Testing

```bash
nix repl
> :lf .
> lib.khanelinix.module.enabled
{ enable = true; }
```
