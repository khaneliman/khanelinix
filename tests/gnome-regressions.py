"""Evaluate GNOME shortcuts and validate serialized values against native schemas.

Run with a PyGObject-enabled Python:
  python3 tests/gnome-regressions.py NIXPKGS HOME_MANAGER SHELL_SCHEMAS DESKTOP_SCHEMAS
All inputs are explicit paths. No user GSettings backend is created or accessed.
"""

import argparse
import json
import pathlib
import subprocess

from gi.repository import Gio, GLib

parser = argparse.ArgumentParser(description=__doc__)
for name in ("nixpkgs", "home_manager", "shell_schemas", "desktop_schemas"):
    parser.add_argument(name, type=pathlib.Path)
parser.add_argument("--root", type=pathlib.Path)
parser.add_argument("--module", type=pathlib.Path)
parser.add_argument("--output", type=pathlib.Path)
args = parser.parse_args()
root = args.root or pathlib.Path(__file__).resolve().parent.parent
expression = (
    "import (builtins.toPath "
    + json.dumps(str(pathlib.Path(__file__).with_suffix(".nix")))
    + ") { "
    + " ".join(
        name + " = builtins.toPath " + json.dumps(str(value.resolve())) + ";"
        for name, value in {
            "nixpkgs": args.nixpkgs,
            "homeManager": args.home_manager,
            "root": root,
            **({"gnomeModule": args.module} if args.module else {}),
        }.items()
    )
    + " }"
)
data = json.loads(
    subprocess.check_output(
        ["nix", "eval", "--impure", "--json", "--expr", expression], text=True
    )
)
source = Gio.SettingsSchemaSource.new_from_directory(
    str(args.desktop_schemas), None, False
)
source = Gio.SettingsSchemaSource.new_from_directory(
    str(args.shell_schemas), source, False
)
wm_path = "org/gnome/desktop/wm/keybindings"
shell_path = "org/gnome/shell/keybindings"


def values(case, path):
    return {
        key: GLib.Variant.parse(None, text, None, None).unpack()
        for key, text in case["settings"].get(path, {}).items()
    }


def validate(case):
    for path in (wm_path, shell_path):
        schema = source.lookup(path.replace("/", "."), True)
        for key, text in case["settings"].get(path, {}).items():
            assert schema.has_key(key), (path, key)
            schema_key = schema.get_key(key)
            variant = GLib.Variant.parse(None, text, None, None)
            assert variant.is_of_type(schema_key.get_value_type()), (path, key, text)
            assert schema_key.range_check(variant), (path, key, text)
    assert not any(
        k.startswith("switch-to-application-") for k in values(case, wm_path)
    )
    assert "switch-to-application-10" not in values(case, shell_path)
    assert not any(k.startswith("enable-") for k in values(case, wm_path))


cases = (
    [v for v in data.values() if isinstance(v, dict)] + data["toggles"] + data["counts"]
)
for case in cases:
    validate(case)
assert not data["invalidToggleAccepted"]
assert data["disabled"]["settings"] == {}
defaults = data["defaults"]
wm, shell = values(defaults, wm_path), values(defaults, shell_path)
assert len(wm) == 26 and len(shell) == 9
assert shell == {f"switch-to-application-{i}": [f"<Super>{i}"] for i in range(1, 10)}
assert wm["switch-applications"] == ["<Super><Tab>"]
assert wm["switch-applications-backward"] == ["<Shift><Super><Tab>"]
for family, chord in (("move", "<Shift><Super>"), ("switch", "<Control><Alt>")):
    for side, letter in (("left", "h"), ("right", "l")):
        assert wm[f"{family}-to-workspace-{side}"] == [
            chord + side.title(),
            chord + letter,
        ]
    for i in range(1, 11):
        assert wm[f"{family}-to-workspace-{i}"] == [
            chord + ("0" if i == 10 else str(i))
        ]
for n, case in enumerate(data["toggles"]):
    bindings = values(case, wm_path)
    for family, enabled in (("switch", bool(n % 2)), ("move", n >= 2)):
        keys = [k for k in bindings if k.startswith(f"{family}-to-workspace-")]
        assert len(keys) == (12 if enabled else 0), (n, family, keys)
    assert values(case, shell_path) == shell
    assert bindings["switch-applications"] == wm["switch-applications"]
override = values(data["override"], wm_path)
assert override["move-to-workspace-1"] == ["<Super>F1"]
assert override["switch-to-workspace-2"] == []
assert override["close"] == ["<Super>q"]
assert override["move-to-workspace-2"] == wm["move-to-workspace-2"]
assert values(data["override"], shell_path)["switch-to-application-1"] == ["<Super>F2"]
explicit = values(data["explicitDisabled"], wm_path)
assert len(explicit) == 4
assert explicit["move-to-workspace-1"] == ["<Super>F1"]
assert explicit["switch-to-workspace-2"] == ["<Super>F2"]
settings = data["settingsOverride"]
assert values(settings, wm_path)["move-to-workspace-1"] == ["<Super>F3"]
assert values(settings, wm_path)["switch-to-workspace-left"] == []
assert values(settings, shell_path)["switch-to-application-1"] == ["<Super>F4"]
assert values(settings, shell_path)["toggle-overview"] == ["<Super>F5"]
assert values(settings, "org/gnome/desktop/interface")["color-scheme"] == "default"
native = data["nativeOverride"]
assert values(native, wm_path)["move-to-workspace-1"] == ["<Super>F6"]
assert values(native, shell_path)["switch-to-application-1"] == ["<Super>F7"]
assert values(native, wm_path)["move-to-workspace-2"] == wm["move-to-workspace-2"]
split = values(data["splitOverrides"], wm_path)
assert split["close"] == ["<Super>q"] and split["move-to-workspace-1"] == ["<Super>F1"]
assert split["move-to-workspace-2"] == wm["move-to-workspace-2"]
for count, case in zip((1, 3, 12, 13), data["counts"], strict=True):
    bindings = values(case, wm_path)
    assert len(bindings) == 6 + 2 * min(count, 12)
    assert values(case, shell_path) == shell
    assert values(case, "org/gnome/desktop/wm/preferences")["num-workspaces"] == count
for case in (settings, native, data["bruddy"]):
    interface = values(case, "org/gnome/desktop/interface")
    assert interface["font-name"] == "Fixture 12"
    assert (
        interface["cursor-size"] == 32 and interface["cursor-theme"] == "FixtureCursor"
    )
    assert (
        interface["gtk-theme"] == "FixtureGTK"
        and interface["icon-theme"] == "FixtureIcons"
    )
    assert case["theme"]["gtk"]["enable"] and case["theme"]["qt"]["enable"]
for case in cases:
    if case is data["disabled"]:
        continue
    assert not any(
        k.startswith("enable-") for k in case["settings"].get(shell_path, {})
    )
    for path, expected in defaults["settings"].items():
        if path not in (
            wm_path,
            shell_path,
            "org/gnome/desktop/interface",
            "org/gnome/desktop/wm/preferences",
            "org/gnome/shell",
        ):
            assert case["settings"][path] == expected, path
assert values(data["bruddy"], "org/gnome/shell")["favorite-apps"] == [
    "org.gnome.Nautilus.desktop",
    "org.gnome.Console.desktop",
    "firefox-devedition.desktop",
    "steam.desktop",
    "org.prismlauncher.PrismLauncher.desktop",
    "org.vinegarhq.Sober.desktop",
]
if args.output:
    args.output.write_text(json.dumps(data, indent=2) + "\n")
print(
    f"PASS: {len(cases)} evaluations; defaults, toggle matrix, overrides, consumer/GTK merge, native schema keys/types/ranges"
)
