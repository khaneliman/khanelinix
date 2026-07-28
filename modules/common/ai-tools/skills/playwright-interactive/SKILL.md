---
name: "playwright-interactive"
description: "Persistent browser and Electron debugging through a harness-native interactive runtime, with Nix-provided Playwright and browsers when available. Use for stateful iterative QA; use playwright for one-shot terminal automation."
---

# Playwright Interactive

Use persistent Playwright handles through the current harness's interactive
runtime when stateful browser sessions make iteration faster than one-shot
scripts.

Default to the `playwright` CLI skill when persistent in-process handles are
not needed. In khanelinix/Nix environments, `playwright-cli` already provides
Playwright plus runnable browsers. Do not run `npm install playwright`,
`npx playwright install`, or any command that populates `~/.cache/ms-playwright`
as setup.

## Plays

- `references/setup.md`: `js_repl`-specific enablement, Nix-backed checks, and
  bootstrap cell. Read only when that tool exists.
- `references/web.md`: desktop/mobile/native web sessions and reloads.
- `references/electron.md`: Electron launch, reload, relaunch.
- `references/qa.md`: functional QA, visual QA, signoff inventory.
- `references/screenshots.md`: CSS-normalized screenshots and viewport checks.
- `references/troubleshooting.md`: stale handles, server lifecycle, cleanup.

## Runtime Routing

- Harness exposes `js_repl`: read `references/setup.md`, then reuse the
  in-process handles described by this skill.
- Another harness with a persistent JavaScript/browser tool: translate the same
  handle lifecycle to that native tool; do not emulate unavailable tool names.
- No persistent runtime: use the `playwright` skill and its CLI session instead.
- In every harness, `playwright-cli --help` or the repository's Nix wrapper must
  work before browser automation begins.
- Run from project directory being debugged.
- Reset the interactive runtime only for recovery; it destroys handles.

## Core Loop

1. Define QA inventory from user request, implemented behavior, and final claims.
2. Start dev server in persistent terminal if needed.
3. Bootstrap the harness-native runtime once; reuse `browser`, `context`,
   `page`, `electronApp`, and `appWindow`.
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
