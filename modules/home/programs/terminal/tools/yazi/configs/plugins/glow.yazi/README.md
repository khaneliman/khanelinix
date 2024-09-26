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
