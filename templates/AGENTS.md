# Flake Templates

## Discovery

- Each direct child of `templates/` is auto-discovered by
  `flake/dev/templates.nix`.
- Template key is directory name. Description defaults to `<name> template`; no
  root registry edit is required.

## Contents

- Keep template self-contained and minimal: `flake.nix`, optional `.envrc`, and
  smallest useful sample sources/config.
- Follow neighboring templates for layout, but declare only systems supported by
  template toolchain. Prefer Linux and Darwin when both work.
- Do not couple generated project back to khanelinix-only paths or inputs unless
  template explicitly demonstrates that integration.

## Validation

```bash
repo=$PWD
target=$(mktemp -d)
(
  cd "$target"
  nix flake init -t "$repo#<template>"
  nix flake check
)
```
