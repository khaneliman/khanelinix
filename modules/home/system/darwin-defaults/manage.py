"""Manage owned macOS preference keys and their pre-management baseline."""

import argparse
import base64
import json
import os
import plistlib
import subprocess
import tempfile
from pathlib import Path
from typing import Any


def export_domain(domain: str) -> dict[str, Any]:
    result = subprocess.run(
        ["/usr/bin/defaults", "export", domain, "-"],
        check=False,
        capture_output=True,
    )
    if result.returncode != 0:
        return {}
    value = plistlib.loads(result.stdout)
    if not isinstance(value, dict):
        raise TypeError(f"defaults domain {domain!r} did not export a dictionary")
    return value


def encode_value(value: Any) -> str:
    payload = plistlib.dumps({"value": value}, fmt=plistlib.FMT_BINARY)
    return base64.b64encode(payload).decode("ascii")


def decode_value(value: str) -> Any:
    payload = base64.b64decode(value)
    return plistlib.loads(payload)["value"]


def load_baseline(path: Path) -> dict[str, dict[str, dict[str, Any]]]:
    if not path.exists():
        return {}
    with path.open(encoding="utf-8") as stream:
        value = json.load(stream)
    if not isinstance(value, dict):
        raise TypeError("preference baseline must be a JSON object")
    return value


def save_baseline(path: Path, baseline: dict[str, Any]) -> None:
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(dir=path.parent, prefix=f".{path.name}.")
    stream = os.fdopen(descriptor, "w", encoding="utf-8")
    try:
        os.chmod(temporary, 0o600)
        with stream:
            json.dump(baseline, stream, indent=2, sort_keys=True)
            stream.write("\n")
        os.replace(temporary, path)
    except BaseException:
        stream.close()
        Path(temporary).unlink(missing_ok=True)
        raise


def record_missing_baselines(
    baseline: dict[str, Any], preferences: list[dict[str, Any]]
) -> bool:
    changed = False
    domains: dict[str, dict[str, Any]] = {}
    for preference in preferences:
        domain = preference["domain"]
        key = preference["key"]
        records = baseline.setdefault(domain, {})
        if key in records:
            continue
        values = domains.setdefault(domain, export_domain(domain))
        if key in values:
            records[key] = {"exists": True, "value": encode_value(values[key])}
        else:
            records[key] = {"exists": False}
        changed = True
    return changed


def apply_preference(preference: dict[str, Any]) -> None:
    if preference["type"] != "bool":
        raise ValueError(f"unsupported preference type: {preference['type']}")
    value = "true" if preference["value"] else "false"
    subprocess.run(
        [
            "/usr/bin/defaults",
            "write",
            preference["domain"],
            preference["key"],
            "-bool",
            value,
        ],
        check=True,
    )


def apply(specification_path: Path, baseline_path: Path) -> None:
    with specification_path.open(encoding="utf-8") as stream:
        preferences = json.load(stream)
    baseline = load_baseline(baseline_path)
    if record_missing_baselines(baseline, preferences):
        save_baseline(baseline_path, baseline)
    for preference in preferences:
        apply_preference(preference)


def import_domain(domain: str, values: dict[str, Any]) -> None:
    descriptor, temporary = tempfile.mkstemp(suffix=".plist")
    try:
        with os.fdopen(descriptor, "wb") as stream:
            plistlib.dump(values, stream, fmt=plistlib.FMT_BINARY)
        subprocess.run(["/usr/bin/defaults", "import", domain, temporary], check=True)
    finally:
        Path(temporary).unlink(missing_ok=True)


def restore(baseline_path: Path) -> None:
    baseline = load_baseline(baseline_path)
    if not baseline:
        raise SystemExit(f"no preference baseline exists at {baseline_path}")
    for domain, records in baseline.items():
        values = export_domain(domain)
        for key, record in records.items():
            if record["exists"]:
                values[key] = decode_value(record["value"])
            else:
                values.pop(key, None)
        import_domain(domain, values)


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    apply_parser = subparsers.add_parser("apply")
    apply_parser.add_argument("--specification", required=True, type=Path)
    apply_parser.add_argument("--baseline", required=True, type=Path)

    restore_parser = subparsers.add_parser("restore")
    restore_parser.add_argument("--baseline", required=True, type=Path)
    return parser.parse_args()


def main() -> None:
    arguments = parse_arguments()
    if arguments.command == "apply":
        apply(arguments.specification, arguments.baseline)
    else:
        restore(arguments.baseline)


if __name__ == "__main__":
    main()
