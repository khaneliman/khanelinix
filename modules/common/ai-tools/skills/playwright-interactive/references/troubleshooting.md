# Troubleshooting Play

Use when persistent Playwright session, server, or handles misbehave.

## Stale Handles

- If a page/window is closed, set that binding to `undefined` and rerun launch.
- If context is stale, close it, set context/page to `undefined`, recreate.
- If browser disconnected, set `browser = undefined` and rebuild web handles.
- Reset `js_repl` only when kernel itself is broken.

## Dev Server

- Start required dev server in persistent TTY.
- Prefer `127.0.0.1` over `localhost`.
- If server port changes, update `TARGET_URL` and reload context.
- Do not restart server for renderer-only changes when hot reload works.

## Common Failures

- Element refs stale: re-query/snapshot DOM before interacting.
- Blank screenshot: wait for `domcontentloaded`, check console, verify canvas or
  WebGL render loop started.
- Native window crop/DPI mismatch: use CSS-normalized screenshot play.
- Electron app stale after preload/main change: relaunch, not reload.
- Visual and metric checks disagree: trust visible screenshot and investigate.

## Cleanup

At task end:

```javascript
await browser?.close().catch(() => {});
await electronApp?.close().catch(() => {});
browser = context = page = mobileContext = mobilePage = undefined;
electronApp = appWindow = undefined;
```
