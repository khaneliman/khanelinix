# Playwright CLI Setup

Use before first CLI action.

## Skill Path

```bash
export CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
export PWCLI="$CODEX_HOME/skills/playwright/scripts/playwright_cli.sh"
```

User-scoped skills install under `$CODEX_HOME/skills` (default
`~/.codex/skills`).

## Prerequisite Check

No Node/npm check is required. Wrapper provides Playwright through Nix:

```bash
"$PWCLI" --help
```

If Nix cannot resolve `nixpkgs#playwright-test`, fix Nix registry/package
availability. Do not install Playwright with `npx` or `npm`.

Prefer wrapper unless repo already standardizes on direct Playwright calls
inside its own Nix environment.
