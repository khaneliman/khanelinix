"""Portable std::future scheduling regression, not a Darwin build/sensor check.

Run on Linux: python3 tests/btop-future-regressions.py /locked/nixpkgs ignored-scratch-dir
--source-root selects a scratch projection. Realize only the locked source and
C++ compiler, apply the actual overlay patch, extract update_sensors and run it
with an inert gated collector. No macOS APIs, host or flake checks are invoked.
"""

import argparse
import json
import shutil
import subprocess
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("nixpkgs", type=Path)
parser.add_argument("scratch", type=Path)
parser.add_argument("--source-root", type=Path, default=HERE.parent)
args = parser.parse_args()
args.scratch.mkdir(parents=True, exist_ok=True)


def run(argv, **kwargs):
    return subprocess.run(
        argv, check=True, capture_output=True, text=True, **({"timeout": 300} | kwargs)
    ).stdout.strip()


expr = f"let p = import (builtins.toPath {json.dumps(str(args.nixpkgs.resolve()))}) {{}}; in [ p.btop.src p.stdenv.cc ]"
outputs = json.loads(
    run(["nix", "build", "--impure", "--no-link", "--json", "--expr", expr])
)
paths = [Path(item["outputs"]["out"]) for item in outputs]
source = next(path for path in paths if (path / "src/osx/btop_collect.cpp").exists())
compiler = next(path / "bin/c++" for path in paths if (path / "bin/c++").exists())
with tempfile.TemporaryDirectory(
    prefix="btop-future-", dir=args.scratch.resolve()
) as directory:
    work = Path(directory)
    tree = work / "source"
    shutil.copytree(source, tree)
    for path in tree.rglob("*"):
        path.chmod(path.stat().st_mode | 0o200)
    patch = (
        args.source_root.resolve()
        / "overlays/btop/btop-1.4.7-darwin-runner-stall-fix.patch"
    )
    run(
        ["patch", "--batch", "--forward", "--fuzz=0", "-p1", "-i", str(patch)], cwd=tree
    )
    body = (tree / "src/osx/btop_collect.cpp").read_text()
    start = body.index("\tvoid update_sensors() {")
    end = body.index("\n\tstring get_cpuHz()", start)
    fixture = work / "future.cpp"
    fixture.write_text(
        (HERE / "btop-future-regressions.cpp")
        .read_text()
        .replace("// UPDATE_SENSORS", body[start:end])
    )
    binary = work / "future"
    run([str(compiler), "-std=c++20", "-pthread", str(fixture), "-o", str(binary)])
    result = json.loads(run([str(binary)], timeout=5))
    assert result == {
        "returned_while_sensor_blocked": True,
        "pending_sensor_calls": 1,
        "completed_result_consumed": True,
    }, result
    print("PASS Btop portable scheduling:", json.dumps(result))
