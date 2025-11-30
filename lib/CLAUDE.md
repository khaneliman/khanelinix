# Custom Library Functions

Reusable Nix functions extending nixpkgs.lib for khanelinix-specific patterns.

## Library Structure

```
lib/
├── base64/         # Base64 encoding/decoding
├── file/           # File system operations
├── module/         # Module creation utilities
├── system/         # System/host builders
├── theme/          # Theme utilities
└── overlay.nix     # Overlay helpers
```

## Core Principles

### 1. Pure Functions

All lib functions must be pure:

- No side effects
- Same inputs always produce same outputs
- No file I/O during evaluation (except via builtins)

### 2. Explicit Function Parameters

Lib functions accept `inputs` parameter and extract needed dependencies:

```nix
{ inputs }:
let
  # Extract only what this lib module needs
  inherit (inputs.nixpkgs.lib) mkOption types mapAttrs;
in
{
  # Function definitions using the inherited values
  myFunction = arg: /* ... */;
}
```

This keeps lib functions self-contained and makes dependencies explicit.

### 3. Namespaced Exports

Export via `flake.lib.{category}`:

```nix
# lib/default.nix
{
  flake.lib = {
    base64 = import ./base64 { inherit inputs; };
    file = import ./file { inherit inputs; self = ../..; };
    module = import ./module { inherit inputs; };
    system = import ./system { inherit inputs; };
    theme = import ./theme { inherit inputs; };
  };
}
```

## Library Categories

- **base64**: Base64 encoding/decoding utilities
- **file**: File operations (getFile, importDir, scanDir, etc.)
- **module**: Module helpers (enabled, mkOpt, mkBoolOpt, mkModule)
- **system**: System builders (mkSystem, mkDarwin, mkHome)
- **theme**: Theme utilities (getTheme, mkColorScheme, applyTheme)
- **overlay**: Overlay creation helpers

Function details are documented in the source code.

## Creating New Library Functions

### 1. Choose Category

Determine which category fits your function:

- File operations → `file/`
- Module utilities → `module/`
- System builders → `system/`
- Theme operations → `theme/`
- New category → Create new directory

### 2. Write Pure Function

```nix
{ inputs }:
let
  inherit (inputs.nixpkgs.lib) mapAttrs filterAttrs;
in
{
  # Document the function
  # @param arg1 Description of arg1
  # @param arg2 Description of arg2
  # @return Description of return value
  # @example myFunction "a" "b" => "ab"
  myFunction = arg1: arg2:
    # Pure implementation
    # No side effects
    # Deterministic output
    arg1 + arg2;
}
```

### 3. Document Function

Add clear documentation with:

- Brief description of what function does
- Parameter descriptions
- Return value description
- Usage example

### 4. Export in default.nix

```nix
# lib/default.nix
{
  flake.lib = {
    # Existing categories...
    myCategory = import ./myCategory { inherit inputs; };
  };
}
```

### 5. Test Function

```bash
# Test in nix repl
nix repl
> :lf .
> lib.khanelinix.myCategory.myFunction "a" "b"
"ab"
```

## When to Add Library Functions

**Add to lib when:**

- Function is reused across multiple modules
- Logic is complex and benefits from abstraction
- Pattern is common throughout codebase
- Function has no side effects

**Don't add to lib when:**

- Used only once
- Module-specific logic
- Requires side effects
- Better expressed inline

## Common Patterns

### Option Creation

```nix
mkOpt = type: default: description:
  lib.mkOption {
    inherit type default description;
  };
```

### Safe Import

```nix
safeImport = path: default:
  if builtins.pathExists path
  then import path
  else default;
```

### Directory Import

```nix
importDir = path: args:
  let
    entries = builtins.readDir path;
    nixFiles = lib.filterAttrs (n: v: v == "regular" && lib.hasSuffix ".nix" n) entries;
  in
  lib.mapAttrs (name: _: import (path + "/${name}") args) nixFiles;
```

## Testing

```bash
# Test in nix repl
nix repl
> :lf .
> lib.khanelinix.file.getFile "modules"
/nix/store/.../modules

# Test via build
nix eval .#lib.khanelinix.file.scanDir ./lib
[ "base64" "file" "module" "system" "theme" ]
```
