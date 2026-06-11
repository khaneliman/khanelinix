# Dynamic Island SketchyBar

Lua-only Dynamic Island configuration for this repository's SketchyBar setup.

This is not a vendored copy of `crissNb/Dynamic-Island-Sketchybar` anymore. The
runtime has been migrated to Lua and is managed by the Home Manager module at
`modules/home/programs/graphical/bars/sketchybar/default.nix`.

## How it is wired

When `khanelinix.programs.graphical.bars.sketchybar.enable = true`, Home Manager
does three things:

- Installs `dynamic-island-sketchybar` as a symlink to the configured SketchyBar
  package.
- Copies this directory to `~/.config/dynamic-island-sketchybar`.
- Starts a Darwin launchd agent named
  `org.nix-community.home.dynamic-island-sketchybar`.

The launchd agent runs:

```sh
dynamic-island-sketchybar --config ~/.config/dynamic-island-sketchybar/sketchybarrc
```

`sketchybarrc` loads `sketchybar` via SbarLua, starts config mode, executes
`init.lua`, enables hot reload, then enters the SketchyBar event loop.

## Runtime layout

- `sketchybarrc`: SbarLua entrypoint used by SketchyBar.
- `init.lua`: core island runtime, bar geometry, event wiring, module loader,
  animation lifecycle, and persistent island state.
- `config.lua`: user-facing Lua configuration table.
- `lua/helpers/`: shared helpers for logging and monitor sizing.
- `lua/islands/`: island modules loaded by `init.lua`.

## Configuration

Edit `config.lua` in this directory, then rebuild or switch Home Manager so the
file is copied to `~/.config/dynamic-island-sketchybar/config.lua`.

Main options:

- `main.display`: SketchyBar display target. Defaults to `"main"`.
- `main.font`: font family used by island items. Defaults to `"SF Pro"`.
- `logging.level`: one of `debug`, `info`, `warn`, or `error`.
- `enabled.<island>`: enables or disables Lua island modules.
- `notch.defaultHeight`: collapsed island height.
- `notch.defaultWidth`: collapsed island half-width used by margin logic.
- `notch.cornerRadius`: collapsed bar corner radius.
- `notch.monitorHorizontalResolution`: `"auto"` or fixed display width.
- `animation.squishAmount`: width adjustment used during island expansion.
- `layout.*`: shared spacing, dimensions, font sizes, text sizing, animation
  timings, meter geometry, and music artwork layout.
- `islands.<name>`: per-island dimensions, polling intervals, and thresholds.
- `colors` and `icons`: shared color/icon values.

Environment variables can override logging at runtime:

```sh
DYNAMIC_ISLAND_LOG_LEVEL=debug
DYNAMIC_ISLAND_LOG_FLUSH_SECONDS=1
DYNAMIC_ISLAND_LOG_MAX_BUFFER_SIZE=80
```

## Restarting

After config changes:

```sh
home-manager switch
launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.dynamic-island-sketchybar
```

For one-off debugging:

```sh
BAR_NAME=dynamic-island-sketchybar \
dynamic-island-sketchybar --config ~/.config/dynamic-island-sketchybar/sketchybarrc
```

## Logs

Launchd writes stdout and stderr here:

- `~/Library/Logs/sketchybar/dynamic-island.out.log`
- `~/Library/Logs/sketchybar/dynamic-island.err.log`

The Lua logger buffers structured records and flushes them according to
`logging.flushSeconds` and `logging.maxBufferSize`.

## Islands

Loaded from `init.lua` when enabled:

- `appswitch`: expands on `front_app_switched`.
- `wifi`: expands on `wifi_change`.
- `power`: expands on `power_source_change` and routine polling.
- `music`: shows now-playing state from configured music source.
- `cpu_panic`: polls CPU usage and expands above configured threshold.
- `clipboard`: polls clipboard changes and previews new text content.
- `privacy`: shows camera and microphone privacy dots.
- `github`: expands on `github_notification` from the main SketchyBar config.

Present but not currently loaded:

- `volume`: Lua module exists, but `init.lua` leaves it disabled until macOS OSD
  handling is resolved.
- `brightness`: Lua module exists, but `init.lua` leaves it disabled until macOS
  OSD handling is resolved.
- `notification`: config placeholder exists, but generic notifications are not
  migrated into the Lua-only runtime.

## Dependencies

Dependencies are supplied by the surrounding Home Manager module instead of
Homebrew install steps. Current SketchyBar module adds packages such as
`sketchybar`, `sbarlua`, `blueutil`, `curl`, `gh`, `gh-notify`, `jq`, and
related helpers.

This README assumes the module owns installation. Do not clone this directory
manually into `~/.config`.
