# Setup Play

Use when starting persistent Playwright from `js_repl`.

## Enable `js_repl`

`js_repl` must be enabled before session start:

```toml
[features]
js_repl = true
```

Equivalent session flag: `--enable js_repl` or `-c features.js_repl=true`.
Restart Codex after changing config so tool list refreshes.

## Workspace Setup

Run from target project directory:

```bash
test -f package.json || npm init -y
npm install playwright
node -e "import('playwright').then(() => console.log('playwright import ok')).catch((error) => { console.error(error); process.exit(1); })"
```

If switching workspaces, repeat setup there.

## Bootstrap Cell

Run once per `js_repl` kernel:

```javascript
var chromium;
var electronLauncher;
var browser;
var context;
var page;
var mobileContext;
var mobilePage;
var electronApp;
var appWindow;

try {
  ({ chromium, _electron: electronLauncher } = await import("playwright"));
  console.log("Playwright loaded");
} catch (error) {
  throw new Error(`Could not load playwright from current js_repl cwd: ${error}`);
}
```

Use `var` for shared handles so later cells can reuse them. Treat
`js_repl_reset` as recovery only; it destroys handles.

## Shared Web Helpers

```javascript
var resetWebHandles = function () {
  context = undefined;
  page = undefined;
  mobileContext = undefined;
  mobilePage = undefined;
};

var ensureWebBrowser = async function () {
  if (browser && !browser.isConnected()) {
    browser = undefined;
    resetWebHandles();
  }
  browser ??= await chromium.launch({ headless: false });
  return browser;
};

var reloadWebContexts = async function () {
  for (const currentContext of [context, mobileContext]) {
    if (!currentContext) continue;
    for (const p of currentContext.pages()) {
      await p.reload({ waitUntil: "domcontentloaded" });
    }
  }
  console.log("Reloaded existing web tabs");
};
```
