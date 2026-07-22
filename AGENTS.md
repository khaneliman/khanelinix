# Repository Instructions

## Instruction Ownership

- `CONTRIBUTING.md` is contributor canon. Read it before changes; do not restate
  its style, taxonomy, validation, commit, or security rules here.
- `AGENTS.md` files are provider-neutral repository guidance. Before editing a
  subtree, read every `AGENTS.md` from repository root through target path;
  closest guidance wins.
- `CLAUDE.md` files import sibling `AGENTS.md` files. Claude-only provider
  behavior lives in dedicated addendum files (for example
  `modules/common/ai-tools/claude-delivery.md`) that `default.nix` concatenates
  onto `base.md` for generated Claude context, not in the `CLAUDE.md` files
  themselves. Keep repository rules out of those Claude-only addenda.
- `modules/common/ai-tools/base.md` owns installed cross-repository behavior.
  Skills own reusable workflows. Do not copy either into repository guidance.

## Scoped Guidance

- `modules/AGENTS.md`: reusable module conventions
- `modules/common/AGENTS.md`: shared system module ownership
- `modules/common/ai-tools/AGENTS.md`: generated AI-tool architecture
- `modules/home/AGENTS.md`: Home Manager ownership and integration
- `modules/nixos/AGENTS.md`: NixOS system ownership
- `modules/darwin/AGENTS.md`: nix-darwin ownership
- `systems/AGENTS.md`: host configuration
- `homes/AGENTS.md`: user configuration
- `lib/AGENTS.md`: custom library exports and tests
- `packages/AGENTS.md`: local package discovery
- `templates/AGENTS.md`: flake template discovery and validation

## Workstation Context

- Primary workstation uses Kinesis Advantage360 Pro split keyboard. For keybind,
  launcher, window-manager, shell, editor, multiplexer, or workflow changes,
  prefer home-row or thumb-cluster reach, modal flows, and consistent cross-app
  patterns. Firmware layers and macros are available.
- Avoid laptop/ANSI placement assumptions, function-row reach, and dense
  same-hand modifier chords.

## Agent Environment

- In sandboxed environments, use `PRE_COMMIT_HOME=/tmp/pre-commit` for commits
  when default pre-commit cache is not writable.
