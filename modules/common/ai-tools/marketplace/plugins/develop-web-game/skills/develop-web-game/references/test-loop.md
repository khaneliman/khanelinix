# Test Loop Play

Use after each meaningful game change.

## Loop

1. Run `$WEB_GAME_CLIENT` with short action bursts.
2. Capture screenshot and `render_game_to_text` output.
3. Inspect screenshot visually; do not rely only on text state.
4. Review console errors; fix first new error before continuing.
5. Verify full interaction chain: input, intermediate state, outcome.
6. Reset state between distinct scenarios.
7. Rerun until controls, text state, screenshots, and console are clean.

Example:

```bash
node "$WEB_GAME_CLIENT" --url http://localhost:5173 --actions-file "$WEB_GAME_ACTIONS" --iterations 3 --pause-ms 250
```

## What To Test

- movement and primary interactions
- win/lose/success/fail transitions
- score, health, inventory, resource changes
- collisions, walls, edges, timers
- menu, pause, restart, start flow
- any requested special action, powerup, puzzle, or enemy behavior

## Screenshot Standard

Capture gameplay states, not only start screen. If expected element is missing
from screenshot, treat as missing in build. For headless/WebGL ambiguity, rerun
headed and inspect again.
