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
- Links this directory's files under `~/.config/dynamic-island-sketchybar`.
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
managed link at `~/.config/dynamic-island-sketchybar/config.lua` points to the
new generation. Do not edit the installed links or their Nix-store targets.

Main options:

- `main.display`: SketchyBar display target. Defaults to `"main"`.
- `main.font`: font family used by island items. Defaults to `"SF Pro"`.
- `logging.level`: one of `debug`, `info`, `warn`, or `error`.
- `enabled.<island>`: enables or disables Lua island modules.
- `notch.defaultHeight`: collapsed island height.
- `notch.defaultWidth`: collapsed island half-width used by margin logic; the
  visible island is twice this value.
- `notch.cornerRadius`: collapsed bar corner radius.
- `notch.monitorHorizontalResolution`: `"auto"` or fixed display width.
- `animation.squishAmount`: width adjustment used during island expansion.
- `layout.*`: shared spacing, dimensions, font sizes, text sizing, animation
  timings, meter geometry, and music artwork layout.
- `layout.dimensions.expandedMinWidth`: minimum expanded half-width, used so
  short notifications still grow out from the collapsed island.
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
- `cpu_panic`: reports sustained per-process CPU activity as "CPU busy".
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

## CPU activity notices

The existing `enabled.cpu_panic`, `islands.cpu_panic`, and `icons.cpu.panic`
keys remain compatible. The name is historical; this is an activity notice, not
evidence of a crash, overload, or misbehaving process.

Defaults in `islands.cpu_panic`:

- `pollInterval = 30`: one asynchronous `ps` snapshot every 30 seconds while
  awake. At most one snapshot is in flight.
- `threshold = 90`: track each non-SketchyBar process above 90% CPU.
- `sustainedSeconds = 120`: require high readings spanning at least two minutes.
  With regular polling, that takes five readings, including the first.
- `cooldownSeconds = 900`: allow at most one CPU notice across all processes
  every 15 minutes, even when the leading process changes.

Each process alerts once per observed high-usage episode. A reading at or below
the threshold, or disappearance from the snapshot, ends its episode. A later
episode must sustain again and still respects the global cooldown. Other
eligible processes wait for the cooldown and must still be high when it ends;
the highest-CPU unreported process is chosen then. Continuous activity does not
produce periodic reminders. State is in memory and resets when the Lua runtime
reloads. Sleep, failed snapshots, backwards clock changes, or gaps greater than
two polling intervals discard sustained evidence rather than counting unseen
time. The cooldown survives those resets within the running instance.

The title shows `CPU busy: 99.5% | Busy App`; the second line shows
`PID 42 | high 2m+ | Click: Activity Monitor`. Click either line to open
Activity Monitor, select its CPU tab, and find the process by name or PID. Check
whether the work is expected before taking action. Long names are shortened in
the island, but the PID remains available. The info-level log records the full
executable, PID, start time, percentage, and observed high-reading duration. The
existing four-second animation and interruption cleanup are reused; an
interrupted notice is not replayed. Persistent music is hidden during the notice
and restored after the final transient notice completes, even if another notice
interrupts the CPU notice.

On macOS, `%cpu` is recent averaged process usage, not a whole-machine
percentage or a lifetime average. Apple's
[ps manual](https://github.com/apple-oss-distributions/adv_cmds/blob/main/ps/ps.1)
describes a decaying average over up to a minute. Its
[implementation](https://github.com/apple-oss-distributions/adv_cmds/blob/main/ps/tasks.c)
sums thread CPU-usage values; approximately 100% represents one logical core,
and a multithreaded process can exceed 100%. Averaging can delay detection and
recovery. Consecutive snapshots establish sustained _high readings_, not proof
of uninterrupted CPU use between polls. Bursts entirely between polls may be
missed.

Two minutes filters brief spikes and many short build processes without hiding
long-lived activity such as a game left running without a visible window. Long
builds and active games can still receive one neutral notice. The 15-minute
global cooldown reduces interruptions but can delay notice of another process.
Process identity combines PID, the full `lstart` timestamp, and executable path
so normal restarts and PID reuse do not inherit evidence. `lstart` has
one-second resolution, not a kernel-unique process identifier.

Foreground status is deliberately not a gate: the existing app-switch event
names an application, not every busy helper's PID, and a background process can
be doing legitimate work. Whole-machine load already appears in the main
SketchyBar CPU item through `sketchy_cpu_load`; that helper belongs to the other
bar instance. Adding another sampler or cross-bar state just to qualify this
notice is not necessary. Revisit that choice if the goal becomes detecting
machine-wide contention rather than identifying long-lived CPU activity.

Regression checks run through the existing workflow harness:

```sh
python3 tests/graphical-workflows.py --root . \
  --scratch "$HOME/.cache/khanelinix/graphical-workflows" --lua /path/to/lua-5.4
```

They cover brief spikes, sustained readings, alternating processes, cooldowns,
recovery, restarts/PID reuse, failed samples, sleep, polling gaps, the actual
snapshot command with fixture output, and cleanup through the island runtime.

An overhead check on khanelimac with roughly 1,000 processes used 24 interleaved
before/after polls. Median command wall time was about 76 ms for both versions;
median child CPU time was 75 ms before and 70 ms after. The new callback parsed
a captured snapshot in about 1.8 ms. At 30-second intervals, that is roughly
0.25% of one logical core's time, not 0.25% of the whole machine. These are
one-off measurements during other build activity, not a claimed speedup. The new
command transfers about 120 KB per snapshot to Lua instead of one process row;
state retains only currently high-CPU processes. No new dependency or additional
recurring command is required, and no process is terminated.

## Dependencies

Dependencies are supplied by the surrounding Home Manager module instead of
Homebrew install steps. Current SketchyBar module adds packages such as
`sketchybar`, `sbarlua`, `blueutil`, `curl`, `gh`, `gh-notify`, `jq`, and
related helpers.

This README assumes the module owns installation. Do not clone this directory
manually into `~/.config`.
