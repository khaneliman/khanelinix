# Darwin WindowServer Instability Investigation

## Scope

This note documents a live investigation on March 6, 2026 into:

- `WindowServer` freezes, crashes, and UI hangs
- repeated `socketfilterfw` CPU spikes
- possible involvement from `sketchybar`, dynamic island, `AeroSpace`, borders,
  and related desktop tooling in this repo

The goal of this document is to separate:

1. instability caused or amplified by repo-managed desktop tooling
2. instability that appears to remain in macOS services even after those tools
   are disabled

## High-confidence findings

### 1. Main `sketchybar` is a major contributor to the worst `WindowServer` churn

During a live isolate test:

- disabling `dynamic-island-sketchybar` did not materially improve the system
- disabling the main `sketchybar` did materially improve the system

Observed after the main bar was disabled:

- `WindowServer` CPU dropped noticeably
- `WindowServer` transaction timeout spam became less dense
- the system became visibly calmer than the prior state

This does not prove `sketchybar` is the only problem, but it does show it is one
of the main amplifiers.

### 2. `AeroSpace` is a secondary contributor

While the main bar was already disabled, live logs still showed `AeroSpace`
generating repeated `com.apple.controlcenter` scene-update traffic, which lined
up with fresh `WindowServer` spikes.

That makes `AeroSpace` a likely second amplifier, especially when paired with
bar-triggered refreshes.

### 3. Dynamic island adds load, but was not the primary trigger in this test

Dynamic island has several polling-heavy modules, but disabling it first did not
significantly change the live `WindowServer` or firewall behavior.

It still looks worth simplifying, but it was not the first-order cause in the
observed failure mode.

### 4. The repo is not currently using Control Center alias items for Wi-Fi/volume

The active repo and `~/.config/sketchybar` copies checked during the
investigation did not contain SketchyBar alias definitions for Control Center
widgets.

The current Wi-Fi and volume items are custom widgets, not `alias` mirrors.

### 5. `socketfilterfw` is a separate problem from the worst bar/WM compositor churn

Even after the main bar and `AeroSpace` were taken out of the path,
`socketfilterfw` remained hot.

Recent firewall clients seen in unified logs:

- `rapportd`
- `syncthing`
- `tailscaled`
- `ControlCenter` in some earlier slices

This means the firewall CPU issue is not primarily caused by SketchyBar.

### 6. A residual system-side `WindowServer` / `universalaccessd` issue remains

Even after the desktop stack was mostly removed, live logs still showed:

- `pid 53647 failed to act on a ping it dequeued before timing out`
  (`universalaccessd`)
- repeated `WindowServer` transaction timeouts
- `__CFRunLoopModeFindSourceForMachPort returned NULL`

That suggests the repo-managed desktop tooling makes the machine worse, but some
macOS-side instability still exists underneath it.

## Evidence in repo config

### SketchyBar layout and event pressure

- two bar processes are configured at once:
  - `modules/home/programs/graphical/bars/sketchybar/default.nix`
- the main bar is enabled through Home Manager
- dynamic island is also launched as a separate `launchd` agent with
  `KeepAlive = true`

### AeroSpace to SketchyBar churn

- `modules/home/programs/graphical/wms/aerospace/default.nix`
  - `on-focus-changed` triggers SketchyBar updates
  - `exec-on-workspace-change` also triggers SketchyBar updates
- `modules/home/programs/graphical/wms/aerospace/rules.nix`
  - `on-window-detected` triggers `aerospace_windows_change`
- `modules/home/programs/graphical/wms/aerospace/bindings.nix`
  - many move/workspace bindings trigger extra bar refreshes

### Expensive SketchyBar refresh paths

- `modules/home/programs/graphical/bars/sketchybar/config/items/spaces-aerospace.lua`
  - recomputes workspace labels from `aerospace list-windows --all`
- `modules/home/programs/graphical/bars/sketchybar/config/items/control_center/github.lua`
  - polls GitHub notifications and does extra per-notification API lookups
- `modules/home/programs/graphical/bars/sketchybar/config/items/stats/network.lua`
  - frequent network stats updates
- `modules/home/programs/graphical/bars/sketchybar/config/items/today/calendar.lua`
  - 1-second clock updates

### Poll-heavy dynamic island modules

- `modules/home/programs/graphical/bars/sketchybar/dynamic-island-sketchybar/lua/islands/clipboard.lua`
  - polls clipboard every 2 seconds
- `modules/home/programs/graphical/bars/sketchybar/dynamic-island-sketchybar/lua/islands/privacy.lua`
  - runs `lsof` checks every 5 seconds
- `modules/home/programs/graphical/bars/sketchybar/dynamic-island-sketchybar/lua/islands/cpu_panic.lua`
  - polls `ps` every 5 seconds

### Busy-wait bug

- `modules/home/programs/graphical/bars/sketchybar/config/utils.lua`

`SLEEP` is implemented as a busy loop using `os.time()`. That is a bad fit for
UI tooling and can pin CPU during transitions.

### Additional bar bugs/noise

- `modules/home/programs/graphical/bars/sketchybar/config/items/today/ical.lua`
  - popup items can be added repeatedly, matching duplicate-item spam in logs

## Live isolate test summary

### Step 1: disable dynamic island

Result:

- little or no meaningful improvement
- `WindowServer` and `socketfilterfw` remained hot

Conclusion:

- dynamic island was not the primary active trigger in the observed failure mode

### Step 2: disable main `sketchybar`

Result:

- clear improvement
- `WindowServer` CPU and log noise dropped
- the system became noticeably calmer

Conclusion:

- main `sketchybar` is a major amplifier of the instability

### Step 3: disable `AeroSpace`

Result:

- removed another layer of control-center/scene-update churn
- remaining problems were much more clearly separated from bar/WM behavior

Conclusion:

- `AeroSpace` is also involved, though less strongly than the main bar

### Post-isolation residual state

Still present after bar/WM isolation:

- `socketfilterfw` remained elevated
- `WindowServer` still logged some transaction timeouts and `universalaccessd`
  ping failures

Conclusion:

- there is a second, mostly system-side problem that should not be blamed
  entirely on repo-managed desktop config

## What to remediate first

### Priority 1: reduce main SketchyBar churn

Look for:

- duplicate bar processes
- high-frequency refreshes that do not need to be real time
- event storms from window-manager hooks
- network-backed widgets in the main bar

Recommended actions:

1. run only one bar while stabilizing the system
2. keep dynamic island disabled until the main bar is proven stable
3. temporarily disable GitHub, weather, and any non-essential network-backed
   widgets
4. raise polling intervals for non-critical items
5. remove the busy-wait `SLEEP` helper
6. fix duplicate popup item creation in `ical.lua`

### Priority 2: reduce AeroSpace-triggered redraw churn

Look for:

- focus-change hooks that trigger global bar refreshes
- workspace-change hooks that recalculate all space labels
- repeated `aerospace_windows_change` triggers for every move or detection event

Recommended actions:

1. debounce or batch bar refresh triggers from `AeroSpace`
2. avoid full `aerospace list-windows --all` recalculation on every focus
   transition
3. temporarily remove `on-focus-changed` and `on-window-detected` bar hooks
   during stability testing
4. restore them one by one only after the system is calm

### Priority 3: isolate the residual firewall problem separately

Look for:

- `rapportd`
- `syncthing`
- `tailscaled`
- `ControlCenter` continuity/AirPlay/Bluetooth activity

Recommended actions:

1. stop `syncthing` and `tailscaled` temporarily and observe `socketfilterfw`
2. compare with Handoff/AirDrop/AirPlay Receiver/Continuity features disabled
3. keep this investigation separate from SketchyBar remediation to avoid mixing
   symptoms

## Things to watch while iterating

When testing changes, watch for:

- `WindowServer` transaction timeout density
- `pid 53647 failed to act on a ping` frequency
- `WindowServer` CPU level at idle
- whether `AeroSpace` still logs `com.apple.controlcenter` scene updates
- whether `socketfilterfw` stays elevated with bar/WM tooling off

If the system becomes calm only when the main bar is disabled, the next fix
should stay focused on the main bar rather than dynamic island or borders.

## Practical remediation order

Suggested order for future work:

1. keep dynamic island off
2. keep the main bar minimal
3. remove the busy-wait helper
4. disable GitHub/weather/network-heavy items
5. reduce or debounce AeroSpace-driven refreshes
6. re-enable items one small group at a time
7. separately test `syncthing`, `tailscaled`, and continuity-related macOS
   services for the firewall issue

## Bottom line

The investigation supports three conclusions:

1. the main `sketchybar` config is a major cause of the worst observed
   `WindowServer` instability
2. `AeroSpace` is also involved and likely amplifies the same path
3. `socketfilterfw` remains a separate live problem that continues even after
   most desktop tooling is removed
