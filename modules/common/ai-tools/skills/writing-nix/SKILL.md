---
name: writing-nix
description: Writes idiomatic, performant, and maintainable Nix code. Covers best practices, anti-patterns to avoid (like `with`), module system design, and performance optimization.
---

# Writing Nix

## Core Principles

1. **Declarative over Imperative**: Describe _what_, not _how_.
2. **Explicit over Implicit**: Avoid magic scoping or hidden dependencies.
3. **Hermetic**: No side effects, no network access during build (except
   fixed-output derivations).

## Critical Anti-Patterns

### 1. The `with` Statement

**NEVER use `with`**. It breaks static analysis, tools (LSP), and readability.

```nix
# BAD
meta = with lib; { license = licenses.mit; };

# GOOD
meta = { license = lib.licenses.mit; };
```

### 2. Recursive Attributes (`rec`)

Avoid `rec` when `let-in` suffices. `rec` can cause infinite recursion and
expensive evaluation.

```nix
# BAD
rec {
  version = "1.0";
  name = "pkg-${version}";
}

# GOOD
let
  version = "1.0";
in {
  inherit version;
  name = "pkg-${version}";
}
```

## Module System

### Standard Pattern

All modules must follow this structure:

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.khanelinix.path.to.module;
  inherit (lib) mkIf mkEnableOption mkOption types;
in {
  options.khanelinix.path.to.module = {
    enable = mkEnableOption "module description";
    # Other options...
  };

  config = mkIf cfg.enable {
    # Configuration implementation
  };
}
```

### Option Design

- **Namespacing**: Always prefix with `khanelinix.`.
- **Types**: Use strict types (`types.bool`, `types.str`,
  `types.listOf types.package`).
- **Defaults**: Use `mkDefault` for overridable values.

## Performance Optimization

### Evaluation

- **Laziness**: Nix is lazy. Don't force evaluation of unused attributes.
- **Imports**: Avoid importing large files if only a small part is needed.
- **Regex**: Avoid expensive regex operations in hot loops.

### Build

- **Closure Size**: Split outputs (`dev`, `doc`, `lib`) to reduce runtime
  dependencies.
- **Filters**: Use `lib.cleanSource` or `nix-filter` to avoid rebuilding on
  irrelevant file changes (e.g., README updates).

## Idiomatic Functions

### Destructuring

Always destructure arguments in function headers.

```nix
# BAD
args: stdenv.mkDerivation { name = args.pname; ... }

# GOOD
{ stdenv, pname, version, ... }: stdenv.mkDerivation {
  inherit pname version;
  ...
}
```

### Overrides

- **`override`**: Change function arguments (inputs).
- **`overrideAttrs`**: Change derivation attributes (steps, build inputs).

## Formatting

- Use `nixfmt` (or `treefmt`).
- `camelCase` for variables.
- `kebab-case` for attributes/files.

## See Also

- **Validation**: See [validating-nix](../validating-nix/) for checking syntax,
  formatting, and building code
- **Module scaffolding**: See
  [../../khanelinix/scaffolding-modules/](../../khanelinix/scaffolding-modules/)
  for creating new modules with proper structure
