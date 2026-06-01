---
name: "playwright-interactive"
description: "Persistent browser and Electron interaction through `js_repl` for fast iterative UI debugging."
---

# Playwright Interactive

Use persistent `js_repl` Playwright handles for web or Electron debugging when
stateful browser sessions make iteration faster than one-shot scripts.

## Plays

- `references/setup.md`: js_repl enablement, npm setup, bootstrap cell.
- `references/web.md`: desktop/mobile/native web sessions and reloads.
- `references/electron.md`: Electron launch, reload, relaunch.
- `references/qa.md`: functional QA, visual QA, signoff inventory.
- `references/screenshots.md`: CSS-normalized screenshots and viewport checks.
- `references/troubleshooting.md`: stale handles, server lifecycle, cleanup.

## Preconditions

- `js_repl` enabled in Codex config or session flags.
- Playwright import works from target workspace.
- Run from project directory being debugged.
- Treat `js_repl_reset` as recovery; it destroys handles.

Minimal setup when Playwright is absent:

```bash
test -f package.json || npm init -y
npm install playwright
node -e "import('playwright').then(() => console.log('ok'))"
```

## Core Loop

1. Define QA inventory from user request, implemented behavior, and final claims.
2. Start dev server in persistent terminal if needed.
3. Bootstrap `js_repl` once; reuse `browser`, `context`, `page`,
   `electronApp`, and `appWindow`.
4. Launch web page or Electron app.
5. After edits, reload renderer changes; relaunch Electron for main/preload or
   startup changes.
6. Run functional QA with real user input.
7. Run separate visual QA over required states/viewports.
8. Capture evidence only after state matches claim.
9. Clean up only when task is finished or intentionally keep session alive.

Read only play files needed for current task.

## Signoff Bar

- Functional path works with normal input.
- Each requested behavior and final claim maps to a QA check.
- Visual inspection covers initial view, meaningful post-interaction states,
  density/overflow, clipping, contrast, layering, and viewport fit.
- Screenshot review and numeric checks agree, or discrepancy is investigated.
- Console errors reviewed; new errors fixed or reported.
