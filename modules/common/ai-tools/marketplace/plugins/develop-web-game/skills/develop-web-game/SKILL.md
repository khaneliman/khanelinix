---
name: "develop-web-game"
description: "Build or iterate on HTML/JavaScript games with a short Playwright verification loop, screenshot and console inspection, and render_game_to_text state checks. Use for playable browser-game implementation or debugging; use frontend-design for non-game interfaces."
metadata:
  disable-model-selection: "true"
---

# Develop Web Game

Build games in small verified steps: implement, run short input bursts, inspect
text state plus screenshots, fix, repeat.

## Load Detail On Demand

- `references/setup.md`: environment variables and Playwright prerequisites.
- `references/test-loop.md`: action bursts, screenshots, console checks.
- `references/game-guidelines.md`: canvas, visuals, text state, deterministic
  time, fullscreen.
- `references/progress-tracking.md`: `progress.md` handling across agents.
- `references/action_payloads.json`: valid action keys and payload shape.

## Setup

Resolve the absolute directory containing this `SKILL.md`, then set
`WEB_GAME_CLIENT` to `scripts/web_game_playwright_client.js` and
`WEB_GAME_ACTIONS` to `references/action_payloads.json` beneath that directory.
Read [references/setup.md](references/setup.md) when either path or Playwright
availability is unclear.

## Required Game Hooks

- Single primary canvas.
- `window.render_game_to_text()` returning concise JSON game state.
- Prefer deterministic `window.advanceTime(ms)` for stable automated checks.

## Iteration Loop

1. Define one feature/behavior goal.
2. Make smallest coherent code change.
3. Run `$WEB_GAME_CLIENT` with short input bursts after each meaningful change.
4. Inspect latest text output, screenshot, and console errors.
5. Verify all affected controls and state transitions end-to-end.
6. Fix first concrete failure, then rerun.
7. Reset between unrelated scenarios.

Read only focused references needed for current game task.

Example:

```bash
node "$WEB_GAME_CLIENT" --url http://localhost:5173 --actions-file "$WEB_GAME_ACTIONS" --iterations 3 --pause-ms 250
```

## Signoff Bar

- New behavior works through actual controls, not only state injection.
- `render_game_to_text` matches visible game state.
- Screenshots show gameplay beyond start/menu when gameplay changed.
- Important interactions cover cause, intermediate state, and outcome.
- Console has no new unhandled errors.
- Visual state is readable: key objects visible, text minimal, no broken layout.
