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
4. **Locality over Hoisting**: Keep bindings as close to their usage as
   possible. Inline single-use values by default. Use a local `let` only to
   contain a bulky unreadable expression, and hoist only to the narrowest scope
   that serves multiple consumers.

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

### 3. Over-hoisted bindings

Do not introduce top-level `let` bindings, `inherit (...)` aliases, or helper
variables "for neatness" when they only have one straightforward use.

Binding decision rule:

1. If a value is used once and reads fine inline, inline it.
2. If a value is used once but is a large multi-line expression that makes the
   surrounding block hard to scan, put it in a small local `let` around the
   smallest expression that needs it.
3. If a value is used multiple times, bind it at the narrowest shared scope of
   those uses instead of hoisting it to the top of the file or module.

The purpose of a local single-use binding is to preserve the readability of the
surrounding structure, not to shorten names or avoid typing `lib.` / `pkgs.`.

- Inline one-off values when they remain readable in context.
- Use a small local `let` only when the surrounding expression becomes hard to
  read inline, usually because the value is a large multi-line block such as
  `pkgs.writeShellScript`.
- Hoist values only when they are shared by multiple consumers.
- Do not create single-use aliases such as `package = pkgs.ripgrep;`,
  `mkIf = lib.mkIf;`, or `inherit (lib) generators;` just to make a short
  expression slightly shorter.

```nix
# BAD
let
  package = pkgs.ripgrep;
in {
  home.packages = [ package ];
}

# GOOD
{
  home.packages = [ pkgs.ripgrep ];
}

# ALSO GOOD
{
  systemd.services.example =
    let
      script = pkgs.writeShellScript "example-service" ''
        set -euo pipefail
        ${pkgs.coreutils}/bin/mkdir -p /var/lib/example
        ${pkgs.rsync}/bin/rsync -a --delete /srv/source/ /var/lib/example/
      '';
    in {
      description = "Example sync service";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${script}";
      };
    };
}
```

### 4. Over-wide option surfaces

Do not expose options for hypothetical use cases. Keep interfaces minimal and
intentional.

## Module Design

Use clear module structure:

```nix
{ config, lib, ... }:
let
  cfg = config.some.path;
in {
  options.some.path.enable = lib.mkEnableOption "description";

  config = lib.mkIf cfg.enable {
    # implementation
  };
}
```

Guidelines:

- Define strict option types.
- Use `mkDefault` for overridable defaults.
- Prefer `mkMerge` + `mkIf` for conditional composition.
- Prefer `inherit (...)` when names match and the binding is reused enough in
  the same local scope to justify introducing it. Do not create single-use
  aliases for `lib` helpers; prefer `lib.mkIf`, `lib.optionalString`, etc.
  inline.

## Expression Style

- Prefer attrset lookup over long if/else chains for multi-branch selection.
- Keep temporary variables close to usage.
- Avoid naming single-use values unless the expression is unreadable without a
  small local `let`.
- Treat `inherit (lib) ...` and similar aliases like any other binding: keep
  them local, and only hoist them when repeated usage clearly pays for the extra
  indirection.
- Ask two questions before adding a binding: "Is this shared?" and "Does the
  inline form damage readability?" If both answers are no, do not bind it.
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
