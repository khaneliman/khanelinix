# Commit Message Reference

Conventional Commit types, scope derivation, and breaking-change format are
model-known. Atomic commit planning and CLI safety live in
[commit-discipline.md](commit-discipline.md).

## Path-Based Convention

Some projects use `path/to/component: subject` instead of `type(scope): subject`
(e.g., nixpkgs-style).

Examples:

- `programs/waybar: update to 0.9.13`
- `modules/nixos/docker: fix socket permissions`
- `init.lua: refactor plugin loading`

**Check `git log` first** to confirm which convention the repo uses before
writing the first commit.
