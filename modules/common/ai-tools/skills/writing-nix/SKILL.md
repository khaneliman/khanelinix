---
name: writing-nix
description: Write idiomatic and maintainable Nix code. Use when creating or refactoring Nix expressions, Home Manager or NixOS modules, overlays, packages, and flake outputs, especially when deciding module merge semantics, binding locality, option defaults, and conditional structure.
---

# Writing Nix

Write boring, explicit Nix that follows this skill's opinionated style. Prefer
module merge semantics, narrow scopes, and simple attrset composition over
decorative abstractions.

## Quick Start

1. Read repository docs only for hard constraints or project-specific layout. Do
   not weaken the style rules in this skill unless the user explicitly asks.
2. Identify the task shape and load only the relevant reference files:
   - [references/module-style.md](references/module-style.md): module templates,
     option design, merge priority, `mkDefault`, `mkForce`, and `mkMerge`.
   - [references/option-design.md](references/option-design.md): when to expose
     an option, option shape, enums vs booleans, and avoiding hypothetical
     flexibility.
   - [references/module-boundaries.md](references/module-boundaries.md): when to
     keep a module single-file versus split it into submodules.
   - [references/merge-order.md](references/merge-order.md): `mkBefore`,
     `mkAfter`, `mkOrder`, and when order control is justified.
   - [references/bindings.md](references/bindings.md): `let` locality,
     single-use bindings, `inherit (...)`, and bulky inline expressions.
   - [references/imports-and-args.md](references/imports-and-args.md): module
     headers, `osConfig ? {}`, import grouping, and explicit arguments.
   - [references/packages-and-exes.md](references/packages-and-exes.md): PATH
     management, plain command names, and when `lib.getExe` is justified.
   - [references/strings-and-shell.md](references/strings-and-shell.md): inline
     strings, `writeShellScript`, `writeShellApplication`, and shell snippet
     boundaries.
   - [references/assertions-and-warnings.md](references/assertions-and-warnings.md):
     when to fail evaluation, when to warn, and when simpler typing is better.
   - [references/derivation-style.md](references/derivation-style.md): boring
     packaging style, build inputs, and patching conventions.
   - [references/anti-patterns.md](references/anti-patterns.md): `with`, `rec`,
     chained conditionals, and other style hazards that should usually block a
     proposed refactor.
3. Apply the narrowest ruleset needed. Do not bulk-load every reference file
   unless the task truly spans them.

## Always Prefer

- Explicit `lib.` usage, or a justified local `inherit (...)`.
- Local bindings over hoisted helper names.
- Module-system merging over hand-written `if/else`.
- Small, intentional option surfaces.
- Normal assignments, `mkDefault`, and `mkForce` used intentionally by merge
  priority.

## Style Authority

- Treat this skill as the default style guide for Nix code.
- Use repository docs for hard constraints, integration details, or required
  module layout, not to dilute the style guidance here.
- If a repository's local conventions conflict with this skill, call out the
  conflict explicitly instead of silently blending the styles.
- Avoid `with lib;`.
- Keep edits surgical; do not clean up unrelated Nix while touching a module.

## Validation

After edits, run the most relevant repo checks available for the task
(`nix fmt`, focused eval/build/test, or module-specific validation).

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
