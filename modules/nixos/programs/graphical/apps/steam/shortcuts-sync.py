"""Merge declared non-Steam shortcuts into every Steam userdata profile."""

import json
import os
import sys
import zlib
from pathlib import Path

import vdf

MANAGED_TAG = "khanelinix"


def steam_root() -> Path | None:
    home = Path.home()
    for candidate in (home / ".local/share/Steam", home / ".steam/steam"):
        if (candidate / "userdata").is_dir():
            return candidate.resolve()
    return None


def steam_running() -> bool:
    # steam.pid survives reboots and low pids get recycled early in boot, so
    # a live /proc entry alone is not proof; check that it is really Steam.
    try:
        pid = int((Path.home() / ".steam/steam.pid").read_text().strip())
        comm = Path(f"/proc/{pid}/comm").read_text().strip()
    except (OSError, ValueError):
        return False
    return comm.startswith("steam")


def shortcut_appid(exe: str, name: str) -> int:
    # Steam derives non-Steam app ids from crc32(exe + name) with the high
    # bit set, stored as a signed 32-bit value in shortcuts.vdf.
    crc = zlib.crc32((exe + name).encode()) | 0x80000000
    return crc - (1 << 32) if crc >= 1 << 31 else crc


def quoted(path: str) -> str:
    return f'"{path}"'


def build_entry(spec: dict) -> dict:
    exe = spec["exe"]
    start_dir = spec.get("startDir") or os.path.dirname(exe)
    tags = list(spec.get("tags", []))
    if MANAGED_TAG not in tags:
        tags.append(MANAGED_TAG)
    return {
        "appid": shortcut_appid(quoted(exe), spec["name"]),
        "AppName": spec["name"],
        "Exe": quoted(exe),
        "StartDir": quoted(start_dir),
        "icon": spec.get("icon", ""),
        "ShortcutPath": "",
        "LaunchOptions": spec.get("launchOptions", ""),
        "IsHidden": 0,
        "AllowDesktopConfig": 1,
        "AllowOverlay": 1,
        "OpenVR": 0,
        "Devkit": 0,
        "DevkitGameID": "",
        "DevkitOverrideAppID": 0,
        "LastPlayTime": 0,
        "FlatpakAppID": "",
        "tags": {str(i): tag for i, tag in enumerate(tags)},
    }


def is_managed(entry: dict) -> bool:
    return MANAGED_TAG in entry.get("tags", {}).values()


def merge(existing: list[dict], desired: list[dict]) -> list[dict]:
    names = {entry["AppName"] for entry in desired}
    kept = [
        entry
        for entry in existing
        if entry.get("AppName") not in names and not is_managed(entry)
    ]
    return kept + desired


def sync_profile(config_dir: Path, desired: list[dict]) -> bool:
    path = config_dir / "shortcuts.vdf"
    existing: list[dict] = []
    if path.is_file():
        with path.open("rb") as fh:
            existing = list(vdf.binary_load(fh).get("shortcuts", {}).values())
    merged = merge(existing, desired)
    data = vdf.binary_dumps(
        {"shortcuts": {str(i): entry for i, entry in enumerate(merged)}}
    )
    if path.is_file() and path.read_bytes() == data:
        return False
    tmp = path.with_suffix(".vdf.tmp")
    tmp.write_bytes(data)
    os.replace(tmp, path)
    return True


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: steam-shortcuts-sync <shortcuts.json>", file=sys.stderr)
        return 2
    root = steam_root()
    if root is None:
        return 0
    if steam_running():
        return 0
    log = sys.stderr
    specs = json.loads(Path(sys.argv[1]).read_text())
    desired = [build_entry(spec) for spec in specs]
    for user_dir in (root / "userdata").iterdir():
        if not user_dir.name.isdigit() or user_dir.name == "0":
            continue
        config_dir = user_dir / "config"
        config_dir.mkdir(exist_ok=True)
        if sync_profile(config_dir, desired):
            print(f"steam-shortcuts-sync: updated {config_dir}", file=log)
    return 0


if __name__ == "__main__":
    sys.exit(main())
