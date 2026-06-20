# Nix Toolkit Operating Rules

## Cross-Skill Boundaries

- `writing-nix` before editing Nix code, modules, overlays, packages, or flake
  outputs.
- `git-toolkit` for history surgery, commit strategy, and branch hygiene.
- `github-toolkit` for GitHub issues, PR review comments, and CI checks.
- Prefer `nix shell`, `nix run`, `,`, or `nix-shell` for one-off investigation
  tools.

## Reporting Rules

- Show exact commands used or recommended.
- Separate measured facts from hypotheses.
- Label snippets: executed | dry-run checked | syntax checked | template only.
- Performance claims require before/after measurements from same command shape.
- Package diffs: report compared inputs and comparison method.

## Skill Maintenance

After editing references, run `scripts/validate-snippets.sh` — checks shell
fence syntax and Nix subcommands/flags; does not build packages, fetch remotes,
or update lock files.
