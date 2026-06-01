# Screenshot Play

Use when screenshots will be interpreted by model or used for coordinate
follow-up.

## Default

Normalize emitted screenshots to CSS pixels. Raw captures are fine for local
debugging, but avoid emitting raw native-window screenshots unless debugging DPI
or pixel fidelity.

```javascript
var emitJpeg = async function (bytes) {
  await codex.emitImage({
    bytes,
    mimeType: "image/jpeg",
    detail: "original",
  });
};

var emitWebJpeg = async function (surface, options = {}) {
  await emitJpeg(
    await surface.screenshot({
      type: "jpeg",
      quality: 85,
      scale: "css",
      ...options,
    }),
  );
};
```

## Coordinate Helpers

```javascript
var clickCssPoint = async function ({ surface, x, y, clip }) {
  await surface.mouse.click(clip ? clip.x + x : x, clip ? clip.y + y : y);
};

var tapCssPoint = async function ({ page, x, y, clip }) {
  await page.touchscreen.tap(clip ? clip.x + x : x, clip ? clip.y + y : y);
};
```

## Native-Window Caveat

In Chromium or Electron native-window mode, `scale: "css"` may still return
device-pixel screenshots on high-DPI displays. For model-bound captures:

- Web: resize via canvas in current page if screenshot dimensions exceed CSS
  viewport.
- Electron: capture with main-process `BrowserWindow.capturePage(...)`, resize
  with `nativeImage.resize(...)`, then emit bytes.

## Viewport Fit Checks

Check:

- initial viewport no unintended horizontal overflow
- key content not clipped or hidden behind fixed UI
- smallest supported viewport/window size
- post-interaction dense state
- mobile context when responsive behavior matters
