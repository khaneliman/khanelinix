# Nix Toolkit Operating Rules

## Cross-Skill Boundaries

- Read [Authoring](authoring.md) before editing Nix code, modules, overlays,
  packages, or flake outputs.
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

After editing references, run `scripts/validate-snippets.sh`. It checks shell
fence syntax and Nix subcommands and flags. It does not build packages, fetch
remotes, or update lock files.

## NixOS Privilege Wrappers

If `sudo` resolves outside `/run/wrappers/bin`, use `/run/wrappers/bin/sudo`.
Nix store binaries lack setuid privileges. Diagnose with `type -a sudo`, then
prepend the wrapper directory for that command. Never `chmod` a store path or
replace the wrapper.
