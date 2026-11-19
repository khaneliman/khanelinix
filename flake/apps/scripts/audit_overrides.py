"""Inventory overlay pins and input patches without changing the checkout.

Comparisons are opt-in: add "# audit-package: attribute [linux|darwin]" to a
self-contained overlay and "# audit-review: ..." for its manual removal check.
Inventory lists checked-in declarations, not the effective configuration.
"""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

DECLARATION = re.compile(
    r'\s*(version|rev|tag|owner|repo|url|hash|revert)\s*=\s*(?:"([^"]+)"|(true|false))\s*;'
)
GITHUB_REFERENCE = re.compile(
    r"https://github\.com/[\w.-]+/[\w.-]+/"
    r"(?:pull/\d+|issues/\d+|commit/[0-9a-f]{7,40})(?![\w/-])"
)
INPUT_PACKAGE = re.compile(r"\binputs\.([\w-]+)\.packages\b")
TARGET = re.compile(r"# audit-package: ([\w-]+(?:\.[\w-]+)*)(?: (linux|darwin))?")

PACKAGE_METADATA = """
{ source, system, overlay, attr }:
let
  pkgs = import (builtins.toPath source) {
    inherit system;
    config = { allowAliases = false; allowUnfree = true; };
    overlays = if overlay == "" then [ ] else [ (import (builtins.toPath overlay) { }) ];
  };
  path = builtins.fromJSON attr;
  package = pkgs.lib.attrByPath path null pkgs;
  src = package.src or null;
  stringOrNull = value: if builtins.isString value then value else null;
in
{
  result = if !pkgs.lib.isDerivation package then null else {
    version = stringOrNull (package.version or null);
    sourceRev = stringOrNull (src.rev or null);
    sourceHash = stringOrNull (src.outputHash or null);
  };
}
"""

LOCKED_SOURCE = """
{ locked }: { result = (builtins.fetchTree (builtins.fromJSON locked)).outPath; }
"""


def locked_input(lock, name):
    node = lock["nodes"][lock["root"]]["inputs"].get(name)
    if isinstance(node, str):
        return lock["nodes"][node].get("locked")
    return None


def inventory(root, lock):
    entries = []
    for kind, directory in (("overlay", "overlays"), ("input patch", "patches")):
        for folder in sorted((root / directory).iterdir()):
            if not folder.is_dir():
                continue
            definition = folder / "default.nix"
            local_patches = sorted(
                path.relative_to(root).as_posix()
                for path in folder.iterdir()
                if path.is_file() and path.suffix in (".patch", ".diff")
            )
            if kind == "overlay" and not definition.is_file():
                continue
            if not definition.is_file() and not local_patches:
                continue

            declarations, references, targets, notes = [], [], [], []
            code = []
            inputs = {folder.name} if kind == "input patch" else set()
            if definition.is_file():
                for number, line in enumerate(definition.read_text().splitlines(), 1):
                    stripped = line.strip()
                    if target := TARGET.fullmatch(stripped):
                        targets.append({"attribute": target[1], "platform": target[2]})
                    if stripped.startswith("# audit-review: "):
                        notes.append(stripped.removeprefix("# audit-review: "))
                    if stripped.startswith("#"):
                        # Ignore example fetchpatch entries in the input patch templates.
                        if not stripped.removeprefix("#").lstrip().startswith("url ="):
                            references.extend(GITHUB_REFERENCE.findall(stripped))
                        continue
                    code.append(line)
                    if declaration := DECLARATION.match(line):
                        field, literal, boolean = declaration.groups()
                        value = literal or boolean
                        declarations.append(
                            {"field": field, "value": value, "line": number}
                        )
                        if field == "url" and "${" not in value:
                            references.extend(GITHUB_REFERENCE.findall(value))
                    inputs.update(INPUT_PACKAGE.findall(line))

            if (
                kind == "input patch"
                and not local_patches
                and re.fullmatch(r"\s*_:\s*\[\s*\]\s*", "\n".join(code))
            ):
                continue
            entries.append(
                {
                    "path": folder.relative_to(root).as_posix(),
                    "definition": definition.relative_to(root).as_posix()
                    if definition.is_file()
                    else None,
                    "kind": kind,
                    "local_patches": local_patches,
                    "declarations": declarations,
                    "references": list(dict.fromkeys(references)),
                    "locked_inputs": {
                        name: (locked_input(lock, name) or {}).get("rev")
                        for name in sorted(inputs)
                    },
                    "targets": targets,
                    "notes": notes,
                    "status": "manual",
                    "comparisons": [],
                }
            )
    return entries


def nix_eval(root, expression, **args):
    command = [
        "nix",
        "eval",
        "--no-write-lock-file",
        "--impure",
        "--option",
        "allow-import-from-derivation",
        "false",
        "--json",
        "--file",
        "-",
    ]
    for key, value in args.items():
        command.extend(["--argstr", key, value])
    result = subprocess.run(
        [*command, "result"],
        input=expression,
        cwd=root,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode:
        errors = [
            line.strip() for line in result.stderr.splitlines() if "error:" in line
        ]
        raise ValueError(
            errors[-1] if errors else f"nix eval exited {result.returncode}"
        )
    return json.loads(result.stdout)


def compare_package(root, source, system, overlay, attribute):
    result = {"attribute": attribute, "status": "inconclusive"}
    errors = []
    for side, path in (("locked", ""), ("overlay", str(overlay))):
        try:
            metadata = nix_eval(
                root,
                PACKAGE_METADATA,
                source=source,
                system=system,
                overlay=path,
                attr=json.dumps(attribute.split(".")),
            )
            if metadata is None:
                errors.append(f"{side}: package attribute missing or not a derivation")
            result[side] = metadata
        except (OSError, ValueError) as error:
            errors.append(f"{side}: {error}")
            result[side] = None
    if errors:
        result["reason"] = "; ".join(errors)
        return result

    locked, overridden = result["locked"], result["overlay"]
    for field in ("version", "sourceRev", "sourceHash"):
        left, right = locked[field], overridden[field]
        result[field] = (
            ("same" if left == right else "different") if left and right else "unknown"
        )
    if all(
        result[field] == "unknown" for field in ("version", "sourceRev", "sourceHash")
    ):
        result["reason"] = "No comparable version or source metadata"
    else:
        result["status"] = "compared"
    return result


def audit(root, lock, system, inventory_only):
    entries = inventory(root, lock)
    baseline = None
    if not inventory_only:
        try:
            system = system or nix_eval(root, "{ result = builtins.currentSystem; }")
            input_name = "nixpkgs-unstable" if system.endswith("-darwin") else "nixpkgs"
            locked = locked_input(lock, input_name)
            if not locked or not locked.get("narHash"):
                raise ValueError(
                    f"{input_name} has no direct, content-pinned lock entry"
                )
            baseline = {"system": system, "input": input_name, "rev": locked.get("rev")}
            source = nix_eval(root, LOCKED_SOURCE, locked=json.dumps(locked))
        except (OSError, ValueError) as error:
            baseline = (baseline or {"system": system}) | {"error": str(error)}

    for entry in entries:
        for target in entry.pop("targets"):
            attribute, platform = target["attribute"], target["platform"]
            comparison = {"attribute": attribute, "status": "manual"}
            if inventory_only:
                comparison["reason"] = "Inventory only; evaluation skipped"
            elif platform and system and not system.endswith(f"-{platform}"):
                comparison["reason"] = f"Comparison applies to {platform}, not {system}"
            elif "error" in baseline:
                comparison.update(status="inconclusive", reason=baseline["error"])
            else:
                comparison = compare_package(
                    root, source, system, root / entry["path"], attribute
                )
            entry["comparisons"].append(comparison)
    return {"baseline": baseline, "entries": entries}


def print_report(report):
    baseline = report["baseline"]
    if baseline is None:
        print("Inventory only; no Nix evaluation.")
    elif "error" in baseline:
        print(f"Locked baseline inconclusive: {baseline['error']}")
    else:
        print(
            f"Locked baseline: {baseline['input']} {baseline['rev']} ({baseline['system']})"
        )
    print("Version and source comparisons are observations, not removal advice.")
    for entry in report["entries"]:
        print(f"\n{entry['path']} ({entry['kind']}; removal review: manual)")
        for name, rev in entry["locked_inputs"].items():
            print(f"  Locked input {name}: {rev or 'revision unavailable'}")
        for patch in entry["local_patches"]:
            print(f"  Local patch: {patch}")
        for field in entry["declarations"]:
            print(
                f"  Declared {field['field']} ({entry['definition']}:{field['line']}): "
                f"{field['value']}"
            )
        for reference in entry["references"]:
            print(f"  Reference: {reference}")
        for note in entry["notes"]:
            print(f"  Review: {note}")
        for comparison in entry["comparisons"]:
            print(f"  {comparison['attribute']}: {comparison['status']}")
            if "reason" in comparison:
                print(f"    {comparison['reason']}")
            for side in ("locked", "overlay"):
                if metadata := comparison.get(side):
                    fields = ", ".join(f"{k}={v}" for k, v in metadata.items() if v)
                    print(f"    {side}: {fields or 'metadata unavailable'}")
            if comparison["status"] == "compared":
                fields = ("version", "sourceRev", "sourceHash")
                print("    " + ", ".join(f"{k}: {comparison[k]}" for k in fields))


def main(argv=None):
    parser = argparse.ArgumentParser(prog="audit-overrides", description=__doc__)
    parser.add_argument(
        "--root", type=Path, help="checkout root (default: find it from cwd)"
    )
    parser.add_argument(
        "--system", help="Nix system for comparisons (default: current system)"
    )
    parser.add_argument(
        "--inventory-only", action="store_true", help="skip Nix evaluation"
    )
    parser.add_argument(
        "--json", action="store_true", help="print JSON instead of text"
    )
    args = parser.parse_args(argv)

    cwd = Path.cwd()
    root = args.root or next(
        (path for path in (cwd, *cwd.parents) if (path / "flake.lock").is_file()), cwd
    )
    root = root.resolve()
    if not all((root / name).is_dir() for name in ("overlays", "patches")):
        parser.error(f"not a khanelinix checkout: {root}; use --root")
    try:
        lock = json.loads((root / "flake.lock").read_text())
        report = audit(root, lock, args.system, args.inventory_only)
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f"Could not read override inventory: {error}", file=sys.stderr)
        return 1
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print_report(report)
    return 0


if __name__ == "__main__":
    sys.exit(main())
