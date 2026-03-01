---
name: writing-nix
description: Write idiomatic, maintainable, and performant Nix code. Use when creating or refactoring Nix expressions, modules, overlays, packages, flake outputs, and helper functions, including anti-pattern avoidance and evaluation/build performance practices.
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

### 3. Over-wide option surfaces

Do not expose options for hypothetical use cases. Keep interfaces minimal and
intentional.

## Module Design

Use clear module structure:

```nix
{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.some.path;
in {
  options.some.path = {
    enable = mkEnableOption "description";
  };

  config = mkIf cfg.enable {
    # implementation
  };
}
```

Guidelines:

- Define strict option types.
- Use `mkDefault` for overridable defaults.
- Prefer `mkMerge` + `mkIf` for conditional composition.
- Prefer `inherit (...)` when names match.

## Expression Style

- Prefer attrset lookup over long if/else chains for multi-branch selection.
- Keep temporary variables close to usage.
- Keep functions small and names descriptive.

## Performance Practices

Evaluation:

- Avoid forcing large attrsets when not needed.
- Avoid expensive repeated imports and computations.
- Keep hot-path expressions straightforward.

Build:

- Minimize runtime closures.
- Keep sources clean (`cleanSource`/filters) to avoid rebuild churn.

## Function Patterns

- Destructure arguments in function headers.
- Use `override` for function arguments and `overrideAttrs` for derivation
  attrs.

## Validation

After edits, run the most relevant checks available in the target repo
(eval/build/test).

## Output Contract

Report:

```text
CHANGES MADE:
- <file>: <what changed and why>

THINGS I DIDN'T TOUCH:
- <file>: <why intentionally unchanged>

POTENTIAL CONCERNS:
- <risk or follow-up checks>
```
