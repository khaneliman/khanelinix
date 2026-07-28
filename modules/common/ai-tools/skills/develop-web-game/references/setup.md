# Setup Play

Use when preparing web-game test loop.

## Skill Paths

Resolve the directory containing the loaded `develop-web-game/SKILL.md`; skill
locations differ by harness and installation scope. Use that exact directory:

```bash
export WEB_GAME_SKILL_DIR="<absolute-path-to-develop-web-game>"
export WEB_GAME_CLIENT="$WEB_GAME_SKILL_DIR/scripts/web_game_playwright_client.js"
export WEB_GAME_ACTIONS="$WEB_GAME_SKILL_DIR/references/action_payloads.json"
```

Do not assume a Codex, Claude, user, plugin, or system installation root.

## Playwright

Ensure Playwright is available through project dependencies or repository
tooling. In Nix environments, prefer the bundled `playwright-cli` closure. Use
the bundled client:

```bash
node "$WEB_GAME_CLIENT" --help
```

Do not replace the client unless it cannot support required inputs.

## Required Hooks

- primary canvas
- `window.render_game_to_text()`
- preferably `window.advanceTime(ms)` for deterministic frame stepping
