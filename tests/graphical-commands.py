"""Native module renders and harmless command-flow regression checks.

Run with --nixpkgs SOURCE --home-manager SOURCE --niri SOURCE --scratch DIR.
Optional --root tests unapplied copies; --repo supplies their library.
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
for option in ("nixpkgs", "home-manager", "niri", "scratch"):
    parser.add_argument("--" + option, type=Path, required=True)
parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
parser.add_argument("--repo", type=Path)
parser.add_argument("--niri-bin", type=Path)
parser.add_argument("--sway-bin", type=Path)
parser.add_argument("--lua-bin", type=Path)
args = parser.parse_args()
scratch = args.scratch.resolve()
scratch.mkdir(parents=True, exist_ok=True)
root = args.root.resolve()
repo = (args.repo or root).resolve()


def evaluate(tree):
    values = {
        "nixpkgs": args.nixpkgs,
        "homeManager": args.home_manager,
        "niri": args.niri,
        "root": tree,
        "repo": repo,
    }
    expr = (
        "import (builtins.toPath "
        + json.dumps(str(root / "tests/graphical-commands.nix"))
        + ") { "
    )
    expr += (
        " ".join(
            k + " = builtins.toPath " + json.dumps(str(v.resolve())) + ";"
            for k, v in values.items()
        )
        + " }"
    )
    return json.loads(
        subprocess.check_output(
            ["nix", "eval", "--impure", "--json", "--expr", expr], text=True
        )
    )


data = evaluate(root)
(scratch / "rendered.json").write_text(json.dumps(data, indent=2))
bin_dir = scratch / "bin"
bin_dir.mkdir(exist_ok=True)
log = scratch / "calls.jsonl"
stub = bin_dir / "stub"
stub.write_text(
    "#!"
    + sys.executable
    + "\n"
    + """
import json, os, sys, time
from pathlib import Path
name = Path(sys.argv[0]).name
payload = sys.stdin.read() if name in ("rofi", "cliphist", "wl-copy", "satty", "swappy") else ""
with open(os.environ["CALL_LOG"], "a") as out:
    out.write(json.dumps(dict(name=name, argv=sys.argv[1:], stdin=payload,
                             display=os.environ.get("WAYLAND_DISPLAY"))) + "\\n")
if name == "pkill":
    sys.exit(int(os.environ.get("PKILL_RESULT", "1")))
elif name == "niri" and sys.argv[1:] == ["msg", "--json", "event-stream"]:
    for _ in range(200):
        if '"swaybg"' in Path(os.environ["CALL_LOG"]).read_text():
            break
        time.sleep(0.01)
    else:
        sys.exit(1)
    print('{"WorkspacesChanged": {}}')
    print('{"WorkspaceActivated": {"id": 2}}')
elif name == "niri":
    print("Hex: #aabbcc")
elif name == "tailscale":
    print(os.environ.get("TAILSCALE_IP", ""))
    sys.exit(int(os.environ.get("TAILSCALE_STATUS", "0")))
elif name == "swaymsg":
    print(json.dumps({"nodes": [{"focused": not os.environ.get("NO_FOCUS"), "name": "spaces and " + chr(34) + "quotes", "rect": {"x": 1, "y": 2, "width": 30, "height": 40}}]}))
elif name == "slurp":
    print("1,2 30x40")
elif name == "grim":
    print("image")
elif name == "cliphist":
    print("42\\tpreview\\x01\\x7f", end="") if sys.argv[1] == "list" else print("decoded:" + payload.split("\\t")[0], end="")
elif name == "rofi":
    print(payload, end="")
"""
)
stub.chmod(0o755)
for name in (
    "kitty",
    "swaync-client",
    "cliphist",
    "rofi",
    "wl-copy",
    "niri",
    "magick",
    "notify-send",
    "slurp",
    "grim",
    "satty",
    "swappy",
    "killall",
    "swaymsg",
    "pkill",
    "swaylock",
    "hyprlock",
    "loginctl",
    "brightnessctl",
    "tailscale",
    "wayvnc",
    "swaybg",
):
    path = bin_dir / name
    if not path.exists():
        path.symlink_to(stub.name)
env = os.environ | {
    "PATH": str(bin_dir) + ":" + os.environ["PATH"],
    "CALL_LOG": str(log),
    "WAYLAND_DISPLAY": "wayland-test",
}
# Relocate only executable store references. Every dispatched executable is inert.
replacements = dict(data["packages"])
jq_link = bin_dir / "jq"
if not jq_link.exists():
    jq = shutil.which("jq")
    assert jq is not None, "jq is required"
    jq_link.symlink_to(jq)
for argv in data["niri"]["argv"].values():
    if len(argv) == 3 and argv[:2] == ["sh", "-c"]:
        import re

        for path in re.findall(r"/nix/store/[^\s;|]+/bin/(?:wl-copy|magick)", argv[2]):
            replacements[Path(path).name] = path


def relocate(command):
    for name, path in replacements.items():
        command = command.replace(path, str(bin_dir / name))
    # The color picker writes nothing through the stub, but keep scratch paths local.
    return command.replace("/tmp/color.png", str(scratch / "color.png"))


def load_script(name, executable, dependencies=()):
    drv = next(p for p in data["shellDerivations"] if p.endswith(f"-{name}.drv"))
    output = json.loads(subprocess.check_output(["nix", "derivation", "show", drv]))
    definition = next(iter(output.get("derivations", output).values()))
    text = definition.get("structuredAttrs", definition["env"])["text"]
    for dependency in dependencies:
        assert data["packages"][dependency] in text, dependency
    script = bin_dir / name
    script.write_text(relocate(text))
    script.chmod(0o755)
    replacements[name] = executable
    return [executable]


def run(command, extra=None, check=True):
    log.write_text("")
    if isinstance(command, list):
        command = [relocate(x) for x in command]
    else:
        command = relocate(command)
        subprocess.run(["/bin/sh", "-n", "-c", command], check=True)
        command = ["/bin/sh", "-c", command]
    result = subprocess.run(
        command,
        env=env | (extra or {}),
        text=True,
        capture_output=True,
        check=False,
    )
    calls = [json.loads(line) for line in log.read_text().splitlines()]
    if check:
        assert result.returncode == 0, (command, result.stderr)
    return result, calls


expected = {
    "Mod+Shift+Return": ["kitty", "zellij"],
    "Mod+E": ["kitty", "yazi"],
    "Mod+T": ["kitty", "btop"],
    "Mod+N": ["swaync-client", "-t", "-sw"],
    "Mod+I": ["notify-send", "niri", "No window inspector configured"],
    "Ctrl+Shift+B": ["killall", "-SIGUSR1", ".waybar-wrapped"],
}
for key, argv in expected.items():
    assert data["niri"]["argv"][key] == argv
    _, calls = run(argv)
    assert calls[-1]["argv"] == argv[1:]
for key in ("Mod+V", "Mod+Shift+P", "Ctrl+Alt+Print"):
    argv = data["niri"]["argv"][key]
    assert argv[:2] == ["sh", "-c"]
    subprocess.run(["/bin/sh", "-n", "-c", argv[2]], check=True)
    _, calls = run(argv)
    if key == "Mod+V":
        preview = next(c["stdin"] for c in calls if c["name"] == "rofi")
        assert preview == "42\tpreview", repr(preview)
        assert calls[-1]["name"] == "wl-copy"
        assert calls[-1]["stdin"] == "decoded:42"
    elif key == "Mod+Shift+P":
        assert calls[-1]["name"] == "notify-send"
        assert calls[-1]["argv"][:2] == ["Color Code:", "#aabbcc"]
    else:
        assert calls[-1]["name"] == "satty"
        assert calls[-1]["argv"] == ["--filename", "-"]
        assert calls[-1]["stdin"] == "image\n"
_, calls = run(data["niri"]["swappy"])
assert calls[-1]["name"] == "swappy" and calls[-1]["argv"] == ["-f", "-"]

binds = data["sway"]["binds"]
assert not data["niri"]["emptyWallpaperUnit"]
for key, step in (("XF86MonBrightnessUp", "5%+"), ("XF86MonBrightnessDown", "5%-")):
    argv = [data["packages"]["brightnessctl"], "--class=backlight", "set", step]
    assert data["niri"]["argv"][key] == argv
    assert binds[key] == "exec " + " ".join(argv)
    for command in (argv, binds[key].removeprefix("exec ")):
        _, calls = run(command)
        assert calls[0]["name"] == "brightnessctl" and calls[0]["argv"] == argv[1:]
    _, dispatch, flags = next(
        b["_args"] for b in data["hyprland"]["brightness"] if b["_args"][0] == key
    )
    assert dispatch["expr"] == f'hl.dsp.exec_cmd("run-as-service {" ".join(argv)}")'
    assert flags["locked"] and flags["repeating"]
assert binds["Mod4+u"] == "output * power on"
for workspace in range(1, 11):
    digit = workspace % 10
    assert binds[f"Control+Alt+{digit}"] == f"workspace number {workspace}"
    for modifiers in ("Control+Alt+Shift", "Mod4+Shift"):
        assert (
            binds[f"{modifiers}+{digit}"]
            == f"move container to workspace number {workspace}"
        )
assert data["sway"]["grace"] == 300
for key, argv in (("Mod4+l", []), ("Mod4+Control+l", ["--grace", "0"])):
    command = binds[key].removeprefix("exec ")
    assert binds[key] in data["sway"]["rendered"]
    _, calls = run(command)
    assert calls[-1]["name"] == "swaylock" and calls[-1]["argv"] == argv
for status, expected_names in (("0", ["pkill"]), ("1", ["pkill", "swaylock"])):
    _, calls = run(
        binds["Mod4+BackSpace"].removeprefix("exec "), {"PKILL_RESULT": status}
    )
    assert [c["name"] for c in calls] == expected_names
    assert calls[-1]["display"] == "wayland-test"
_, calls = run(binds["Mod4+i"].removeprefix("exec "))
assert calls[-1]["name"] == "notify-send"
assert calls[-1]["argv"][0] == "Window Info"
assert json.loads(calls[-1]["argv"][1])["name"] == 'spaces and "quotes'

startup = next(
    s["command"] for s in data["sway"]["startup"] if "wayvnc" in s["command"]
)
wrapper, executable = startup.split()
assert wrapper == "run-as-service"
vnc = load_script("sway-start-wayvnc", executable, ("tailscale", "wayvnc"))
_, calls = run(vnc, {"TAILSCALE_IP": "100.64.0.10"})
assert [(c["name"], c["argv"]) for c in calls] == [
    ("tailscale", ["ip", "--4"]),
    ("wayvnc", ["100.64.0.10"]),
]
for overrides in (
    {"TAILSCALE_IP": ""},
    {"TAILSCALE_STATUS": "1", "TAILSCALE_IP": "100.64.0.10"},
):
    result, calls = run(vnc, overrides, check=False)
    assert result.returncode != 0 and [c["name"] for c in calls] == ["tailscale"]

capture = binds["Control+Print"].removeprefix("exec ")
geometry = capture.split("$(", 1)[1].split(")", 1)[0]
load_script("sway-active-geometry", geometry)
for binding, capture_args, recipient in (
    ("Control+Print", ["-"], "wl-copy"),
    ("Alt+Print", ["-t", "ppm", "-"], "satty"),
):
    command = binds[binding].removeprefix("exec ")
    _, calls = run(command)
    assert any(
        c["name"] == "grim" and c["argv"] == ["-g", "1,2 30x40", *capture_args]
        for c in calls
    )
    assert any(c["name"] == recipient and c["stdin"] == "image\n" for c in calls)
    result, calls = run(command, {"NO_FOCUS": "1"}, check=False)
    assert result.returncode != 0 and [c["name"] for c in calls] == ["swaymsg"]

watcher = load_script(
    "niri-wallpaper-watch", data["niri"]["wallpaperExec"][0], ("niri", "jq", "swaybg")
)
_, calls = run(watcher)
assert [c["argv"] for c in calls if c["name"] == "niri"] == [
    ["msg", "--json", "event-stream"]
]
assert [c["argv"] for c in calls if c["name"] == "swaybg"] == [
    ["-o", "DP-3", "-i", path, "-o", "DP-1", "-i", path, "-m", "fill"]
    for path in ("/fixture/first wallpaper.png", '/fixture/second "wallpaper".png')
]
# Native Wlogout layout is newline-separated objects, not a JSON array.
layout = [json.loads(line) for line in data["wlogout"].splitlines()]
assert (
    next(x for x in layout if x["label"] == "lock")["action"]
    == data["menus"][0]["wlogout"]
)
assert (
    data["waybarRender"][0]["custom/power"]["menu-actions"]["lock"]
    == data["menus"][0]["waybar"]
)
# Apply the native format generator's jq operation to its structured value.
rendered_waybar = subprocess.check_output(
    ["jq", ".value"], input=json.dumps({"value": data["waybarRender"]}), text=True
)
(scratch / "waybar.json").write_text(rendered_waybar)
for menu in data["menus"]:
    assert menu["wlogout"] == menu["waybar"]
    for desktop, name, index, argv in (
        ("sway", "swaylock", 0, ["-defF"]),
        ("niri", "swaylock", 0, ["-defF"]),
        ("GNOME:niri", "swaylock", 0, ["-defF"]),
        ("Hyprland", "hyprlock", 1, ["--immediate"]),
        ("Hyprland:wlroots", "hyprlock", 1, ["--immediate"]),
    ):
        result, calls = run(
            menu["wlogout"], {"XDG_CURRENT_DESKTOP": desktop}, check=False
        )
        if menu["bits"][index]:
            assert result.returncode == 0
            assert (
                len(calls) == 1
                and calls[0]["name"] == name
                and calls[0]["argv"] == argv
            )
        else:
            assert result.returncode == 1 and not calls
        _, calls = run(menu["ashell"], {"XDG_CURRENT_DESKTOP": desktop})
        if menu["bits"][index]:
            assert len(calls) == 1 and calls[0]["name"] == name and not calls[0]["argv"]
        else:
            assert len(calls) == 1 and calls[0]["name"] == "loginctl"
            assert calls[0]["argv"] == ["lock-session"]
    for desktop in ("", "GNOME", "notniri"):
        result, calls = run(
            menu["wlogout"], {"XDG_CURRENT_DESKTOP": desktop}, check=False
        )
        assert result.returncode == 1 and not calls
        _, calls = run(menu["ashell"], {"XDG_CURRENT_DESKTOP": desktop})
        assert len(calls) == 1 and calls[0]["name"] == "loginctl"
        assert calls[0]["argv"] == ["lock-session"]
    # Enablement, not executable closure presence: both stubs exist for every case.
    for index, name in enumerate(("swaylock", "hyprlock")):
        if not menu["bits"][index]:
            assert data["packages"][name] not in menu["wlogout"]
            assert data["packages"][name] not in menu["ashell"]

locker = Path(data["packages"]["swaylock"])
for flag, valid in (("--immediate", False), ("--grace", True)):
    argv = [str(locker), flag] + (["0"] if valid else []) + ["--help"]
    result = subprocess.run(argv, text=True, capture_output=True, check=False)
    # Help returns 1 in swaylock-effects; it exits before any Wayland/PAM setup.
    assert ("unrecognized option" not in result.stderr) == valid, result.stderr
if args.niri_bin:
    config = scratch / "niri.kdl"
    config.write_text(data["niri"]["kdl"])
    subprocess.run([str(args.niri_bin), "validate", "-c", str(config)], check=True)
if args.sway_bin:
    config = scratch / "sway.conf"
    config.write_text(data["sway"]["rendered"])
    sway_env = os.environ | {
        "WLR_BACKENDS": "headless",
        "WLR_RENDERER": "pixman",
        "XDG_RUNTIME_DIR": str(scratch),
    }
    subprocess.run(
        [str(args.sway_bin), "--validate", "-c", str(config)], env=sway_env, check=True
    )
if args.lua_bin:
    callback = data["hyprland"]["wallpaperCallback"]["expr"]
    subprocess.run(
        [str(args.lua_bin), "-"],
        input=f"local callback = {callback}\n"
        + """
local commands = {}
local active
hl = {
  get_active_monitor = function() return active end,
  exec_cmd = function(command) table.insert(commands, command) end,
}
callback({ id = 1 })
assert(#commands == 0)
active = { name = "DP-1" }
callback({ id = 1 })
callback({ id = 1, monitor = { name = "DP-1" } })
callback({ id = 1, monitor = "DP-2" })
callback({ id = 2, monitor = "DP-2", special = true })
assert(#commands == 2)
assert(commands[1]:match("^hyprctl hyprpaper wallpaper DP%-1,"))
assert(commands[2]:match("^hyprctl hyprpaper wallpaper DP%-2,"))
""",
        text=True,
        check=True,
    )

print(
    "PASS: native graphical renders, brightness, Sway workspace and command flow, Niri wallpaper service, locker menu matrix and flag parsing"
)
