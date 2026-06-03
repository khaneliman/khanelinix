---
name: "playwright-interactive"
description: "Persistent browser and Electron interaction through `js_repl` for fast iterative UI debugging, using Nix-provided `playwright-cli`/browsers when available. Do not install Playwright or browsers with npm/npx as setup."
---

# Playwright Interactive

Use persistent `js_repl` Playwright handles for web or Electron debugging when
stateful browser sessions make iteration faster than one-shot scripts.

Default to the `playwright` CLI skill when persistent in-process handles are
not needed. In khanelinix/Nix environments, `playwright-cli` already provides
Playwright plus runnable browsers. Do not run `npm install playwright`,
`npx playwright install`, or any command that populates `~/.cache/ms-playwright`
as setup.

## Plays

- `references/setup.md`: js_repl enablement, Nix-backed checks, bootstrap cell.
- `references/web.md`: desktop/mobile/native web sessions and reloads.
- `references/electron.md`: Electron launch, reload, relaunch.
- `references/qa.md`: functional QA, visual QA, signoff inventory.
- `references/screenshots.md`: CSS-normalized screenshots and viewport checks.
- `references/troubleshooting.md`: stale handles, server lifecycle, cleanup.

## Preconditions

- `js_repl` enabled in Codex config or session flags.
- `playwright-cli --help` works from `PATH`, or
  `nix run ~/khanelinix#playwright-cli -- --help` works.
- Run from project directory being debugged.
- Treat `js_repl_reset` as recovery; it destroys handles.

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
