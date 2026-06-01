# Game Guidelines Play

Use when designing or reviewing browser game implementation details.

## Canvas And Layout

- Prefer one primary canvas centered in window.
- Keep canvas dimensions stable across hover/state changes.
- Avoid UI text overlays during play unless needed for state.

## Visuals

- Draw background inside canvas.
- Avoid overly dark scenes unless requested.
- Make player, enemies, pickups, hazards, goals, and interactables visually
  distinct.
- Keep on-screen text minimal; put controls on start/menu screen when possible.

## Text State

Expose:

```javascript
window.render_game_to_text = () => JSON.stringify({
  screen,
  player,
  enemies,
  score,
  health,
});
```

Include enough state to play/debug without visuals. Text state must match
visible state.

## Deterministic Time

Prefer:

```javascript
window.advanceTime = (ms) => {
  // advance simulation deterministically
};
```

This keeps automated checks stable.

## Fullscreen

If fullscreen exists, test enter/exit and layout recovery. Do not make
fullscreen required for normal play unless user asks.
