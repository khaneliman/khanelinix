# Nix Toolkit Operating Rules

Use for cross-skill routing, reporting, and skill maintenance.

## Cross-Skill Boundaries

- Use `writing-nix` before editing Nix code, modules, overlays, packages, or
  flake outputs.
- Use `git-toolkit` for history surgery, commit strategy, and branch hygiene.
- Use `github-toolkit` for GitHub issues, PR review comments, and CI checks.
- Prefer one-off tools through `nix shell`, `nix run`, `,`, or `nix-shell`
  instead of adding persistent investigation dependencies.

## Reporting Rules

- Show exact commands used or recommended.
- Separate measured facts from hypotheses.
- Label snippets: executed, dry-run checked, syntax checked, or template only.
- For performance claims, require before/after measurements from same command
  shape.
- For package diffs, report compared inputs and comparison method.

## Skill Maintenance

After editing references, run:

```bash
scripts/validate-snippets.sh
```

This checks shell fence syntax and verifies referenced Nix subcommands/flags are
available. It does not build packages, fetch remote forks, or update lock files.
