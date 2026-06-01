# Setup Play

Use when preparing web-game test loop.

## Skill Paths

```bash
export CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
export WEB_GAME_CLIENT="$CODEX_HOME/skills/develop-web-game/scripts/web_game_playwright_client.js"
export WEB_GAME_ACTIONS="$CODEX_HOME/skills/develop-web-game/references/action_payloads.json"
```

User-scoped skills install under `$CODEX_HOME/skills` by default.

## Playwright

Ensure Playwright is available through project dependency, global install, or
repo tooling. If unsure, check `npx` first. Use bundled client:

```bash
node "$WEB_GAME_CLIENT" --help
```

Do not replace the client unless it cannot support required inputs.

## Required Hooks

- primary canvas
- `window.render_game_to_text()`
- preferably `window.advanceTime(ms)` for deterministic frame stepping
