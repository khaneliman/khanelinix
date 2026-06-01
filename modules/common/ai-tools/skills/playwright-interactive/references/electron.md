# Electron Session Play

Use for Electron apps. Read `setup.md` first if `js_repl` is not bootstrapped.

Electron launches with native-window behavior. Check as-launched size and layout
before resizing.

## Launch

Set `ELECTRON_ENTRY` to `.` when current workspace is app root and
`package.json` points `main` correctly. Otherwise set explicit main file.

```javascript
var ELECTRON_ENTRY = ".";

if (appWindow?.isClosed()) appWindow = undefined;

if (!appWindow && electronApp) {
  await electronApp.close().catch(() => {});
  electronApp = undefined;
}

electronApp ??= await electronLauncher.launch({
  args: [ELECTRON_ENTRY],
});

appWindow ??= await electronApp.firstWindow();
console.log("Loaded Electron window:", await appWindow.title());
```

If launching outside app workspace, pass explicit `cwd`.

## Renderer Reload

```javascript
await appWindow.reload({ waitUntil: "domcontentloaded" });
console.log("Reloaded Electron window");
```

## Relaunch For Main/Preload/Startup Changes

```javascript
await electronApp.close().catch(() => {});
electronApp = undefined;
appWindow = undefined;

electronApp = await electronLauncher.launch({
  args: [ELECTRON_ENTRY],
});

appWindow = await electronApp.firstWindow();
console.log("Relaunched Electron window:", await appWindow.title());
```

## Notes

- Use `electronApp.evaluate(...)` for main-process inspection or diagnostics.
- If app process looks stale, set `electronApp = appWindow = undefined` and
  rerun launch.
- Do not reset `js_repl` unless kernel is broken.
