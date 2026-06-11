Read `CONTRIBUTING.md` before making any changes. It is the source of truth for
code style, module organization and taxonomy, commit conventions, validation,
and security practices — for humans and agents alike.

Everything below and in `.claude/rules/` exists only to add model-specific
nudges that `CONTRIBUTING.md` does not cover. Never treat these files as a
replacement for it.

## Progressive Context

- **Nix code or module work**: use the `writing-nix` skill before edits.
  Repo-specific nudges load automatically from `.claude/rules/nix-style.md` when
  touching `*.nix` files; other `.claude/rules/` files load per directory.
- **Secrets**: `sops-nix` only; never commit plaintext secrets. (Also in
  CONTRIBUTING.md — repeated here so it survives context compaction.)

## Host Context

- Primary `khanelinix` workstation uses a Kinesis Advantage360 Pro split
  keyboard.
- For keybind, shortcut, launcher, window-manager, shell, editor, multiplexer,
  or workflow changes, optimize for split-keyboard ergonomics: prefer home-row
  or thumb-cluster reachable binds, modal flows, and consistent cross-app
  patterns. Treat keyboard firmware layers/macros as available tools when they
  reduce app-specific chord complexity.
- Avoid designs that assume laptop/ANSI key placement, function-row reach, or
  dense same-hand multi-modifier chords.

## Agent Environment

- In sandboxed agent environments, set `PRE_COMMIT_HOME=/tmp/pre-commit` before
  `git commit` if pre-commit cannot write to `~/.local/cache/pre-commit`.
