# Setup Play

Use when starting persistent Playwright from `js_repl`.

## Hard Rule

Do not install Playwright or browsers as setup in khanelinix/Nix environments:

```bash
# Wrong for this repo:
npm install playwright
npx playwright install
```

Use the already-provided Nix package instead. It supplies `playwright-cli`,
the Playwright Node package inside the CLI closure, and NixOS-runnable browsers.

## Enable `js_repl`

`js_repl` must be enabled before session start:

```toml
[features]
js_repl = true
```

Equivalent session flag: `--enable js_repl` or `-c features.js_repl=true`.
Restart Codex after changing config so tool list refreshes.

## Nix-Backed Check

Run from target project directory:

```bash
playwright-cli --help
```

If missing from `PATH`, use this repo's flake:

```bash
nix run ~/khanelinix#playwright-cli -- --help
```

If neither command works, stop and report that Nix-provided Playwright is
unavailable. Do not fall back to `npm`, `npx`, or upstream browser downloads.

Plain `node -e "import('playwright')"` may fail here because the package lives
inside the Nix CLI closure, not in the target workspace. That is expected.

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
var nodeModule;
var nodeChildProcess;
var nodeFs;
var nodePath;
var playwrightRequire;
var playwrightCliBin;
var playwrightCliResolved;
var playwrightCliRoot;
var playwrightPackagePath;
var playwrightWrapperText;
var playwrightBrowsersMatch;

try {
  nodeModule = await import("node:module");
  nodeChildProcess = await import("node:child_process");
  nodeFs = await import("node:fs");
  nodePath = await import("node:path");

  playwrightCliBin = nodeChildProcess.execFileSync(
    "bash",
    ["-lc", "command -v playwright-cli"],
    { encoding: "utf8" },
  ).trim();
  playwrightCliResolved = nodeFs.realpathSync(playwrightCliBin);
  playwrightCliRoot = nodePath.dirname(nodePath.dirname(playwrightCliResolved));
  playwrightPackagePath = nodePath.join(
    playwrightCliRoot,
    "lib/node_modules/@playwright/cli/node_modules/playwright",
  );

  playwrightWrapperText = nodeFs.readFileSync(playwrightCliResolved, "utf8");
  playwrightBrowsersMatch = playwrightWrapperText.match(
    /PLAYWRIGHT_BROWSERS_PATH=\$\{PLAYWRIGHT_BROWSERS_PATH-'([^']+)'\}/,
  );
  if (playwrightBrowsersMatch && !process.env.PLAYWRIGHT_BROWSERS_PATH) {
    process.env.PLAYWRIGHT_BROWSERS_PATH = playwrightBrowsersMatch[1];
  }
  process.env.PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS ??= "1";

  playwrightRequire = nodeModule.createRequire(
    `${process.cwd()}/.codex-playwright.cjs`,
  );
  ({ chromium, _electron: electronLauncher } =
    playwrightRequire(playwrightPackagePath));
  console.log("Playwright loaded from Nix CLI closure");
} catch (error) {
  throw new Error(
    `Could not load Nix-provided Playwright from playwright-cli: ${error}`,
  );
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
