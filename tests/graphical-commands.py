"""Native module renders and harmless command-flow regression checks.

Run with --nixpkgs SOURCE --home-manager SOURCE --niri SOURCE --scratch DIR.
Optional --root tests unapplied copies; --repo supplies their library.
--baseline checks the old tree's known failures without launching any real locker.
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
for option in ("nixpkgs", "home-manager", "niri", "scratch"):
    parser.add_argument("--" + option, type=Path, required=True)
parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
parser.add_argument("--repo", type=Path)
parser.add_argument("--baseline", type=Path)
parser.add_argument("--niri-bin", type=Path)
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
import json, os, sys
from pathlib import Path
name = Path(sys.argv[0]).name
payload = sys.stdin.read() if name in ("rofi", "cliphist", "wl-copy", "satty", "swappy") else ""
with open(os.environ["CALL_LOG"], "a") as out:
    out.write(json.dumps(dict(name=name, argv=sys.argv[1:], stdin=payload,
                             display=os.environ.get("WAYLAND_DISPLAY"))) + "\\n")
if name == "pkill":
    sys.exit(int(os.environ.get("PKILL_RESULT", "1")))
elif name == "niri":
    print("Hex: #aabbcc")
elif name == "swaymsg":
    print(json.dumps({"nodes": [{"focused": True, "name": "spaces and " + chr(34) + "quotes", "rect": {"x": 1}}]}))
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
    for desktop in ("", "GNOME", "notniri"):
        result, calls = run(
            menu["wlogout"], {"XDG_CURRENT_DESKTOP": desktop}, check=False
        )
        assert result.returncode == 1 and not calls
    # Enablement, not executable closure presence: both stubs exist for every case.
    for index, name in enumerate(("swaylock", "hyprlock")):
        if not menu["bits"][index]:
            assert data["packages"][name] not in menu["wlogout"]

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

if args.baseline:
    old = evaluate(args.baseline.resolve())
    assert all(
        isinstance(old["niri"]["argv"][key][0], str)
        and len(old["niri"]["argv"][key]) == 1
        for key in expected
    )
    for key in ("Mod+V", "Mod+Shift+P", "Ctrl+Alt+Print"):
        assert len(old["niri"]["argv"][key]) == 1
    try:
        run(old["niri"]["argv"]["Mod+Shift+Return"])
    except FileNotFoundError:
        pass
    else:
        raise AssertionError("old combined executable unexpectedly launched")
    old_fallback = old["sway"]["binds"]["Mod4+BackSpace"]
    assert (
        "$screen-locker" in old_fallback and "WAYLAND_DISPLAY=wayland-1" in old_fallback
    )
    result, calls = run(
        old_fallback.removeprefix("exec "), {"PKILL_RESULT": "1"}, check=False
    )
    assert result.returncode == 127 and [c["name"] for c in calls] == ["pkill"]
    _, calls = run(old["sway"]["binds"]["Mod4+i"].removeprefix("exec "))
    assert next(c for c in calls if c["name"] == "notify-send")["argv"] == [
        "Window Info",
        "-t",
        "5000",
    ]
    assert "--immediate" in old["sway"]["binds"]["Mod4+Control+l"]
    assert old["menus"][0]["wlogout"] == "saylock"
    result, calls = run(
        old["menus"][0]["waybar"], {"XDG_CURRENT_DESKTOP": "niri"}, check=False
    )
    assert result.returncode != 0 and not calls
print(
    "PASS: native HM/Niri renders, nine Niri actions, both annotation branches, Sway lock/inspector flows, 4 enablement x 8 desktop menu cases, real help-only flag parsing and old negative cases"
)
