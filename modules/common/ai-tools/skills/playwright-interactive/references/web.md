# Web Session Play

Use for browser-based web apps. Read `setup.md` first if `js_repl` is not
bootstrapped.

## Session Mode

- Explicit viewport: default for deterministic iteration, breakpoints,
  screenshots, and coordinate follow-up.
- Native-window mode (`viewport: null`): separate headed pass for OS window,
  DPI, browser chrome, or launch-size bugs.
- Switching modes means new context/page. Do not reuse emulated viewport context
  for native-window checks.

## Desktop Context

```javascript
var TARGET_URL = "http://127.0.0.1:3000";

if (page?.isClosed()) page = undefined;

await ensureWebBrowser();
context ??= await browser.newContext({
  viewport: { width: 1600, height: 900 },
});
page ??= await context.newPage();

await page.goto(TARGET_URL, { waitUntil: "domcontentloaded" });
console.log("Loaded:", await page.title());
```

If stale, set `context = page = undefined` and rerun.

## Mobile Context

```javascript
var MOBILE_TARGET_URL = typeof TARGET_URL === "string"
  ? TARGET_URL
  : "http://127.0.0.1:3000";

if (mobilePage?.isClosed()) mobilePage = undefined;

await ensureWebBrowser();
mobileContext ??= await browser.newContext({
  viewport: { width: 390, height: 844 },
  isMobile: true,
  hasTouch: true,
});
mobilePage ??= await mobileContext.newPage();

await mobilePage.goto(MOBILE_TARGET_URL, { waitUntil: "domcontentloaded" });
console.log("Loaded mobile:", await mobilePage.title());
```

If stale, set `mobileContext = mobilePage = undefined` and rerun.

## Native-Window Pass

```javascript
var TARGET_URL = "http://127.0.0.1:3000";

await ensureWebBrowser();
await page?.close().catch(() => {});
await context?.close().catch(() => {});
page = undefined;
context = undefined;

context = await browser.newContext({ viewport: null });
page = await context.newPage();
await page.goto(TARGET_URL, { waitUntil: "domcontentloaded" });
console.log("Loaded native window:", await page.title());
```

## Reload

Renderer-only web change:

```javascript
await reloadWebContexts();
```
