# glow.yazi

Plugin for [Yazi](https://github.com/sxyazi/yazi) to preview markdown files with
[glow](https://github.com/charmbracelet/glow). To install, run the below
mentioned command:

```bash
ya pack -a Reledia/glow
```

then include it in your `yazi.toml` to use:

```toml
[plugin]
prepend_previewers = [
  { name = "*.md", run = "glow" },
]
```

Make sure you have [glow](https://github.com/charmbracelet/glow) installed, and
can be found in `PATH`.

## Feature

- You can modify line wrap in `init.lua`, the current value is 55.
- You can press `ctrl+e` to scroll up and `ctrl+y` to scroll down the readme
  file in preview panel in yazi: (add this to `keymap.toml`)

```toml
prepend_keymap = [
    # glow.yazi
    { on = ["<C-e>"], run = "seek 5" },
    { on = ["<C-y>"], run = "seek -5" },
]
```
