"""Darwin-only sanitizer regression using an evaluated SketchyBar derivation.

Build the package first, then run:
python3 tests/sketchybar-window-lifetime.py /nix/store/...-sketchybar.drv cache-dir
--expect-bug checks the deployed, unmodified derivation's two failing scenarios.
All window-system calls are inert; no bar process or live service is touched.
"""

import argparse
import json
import os
import platform
import shutil
import subprocess
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("derivation", type=Path)
parser.add_argument("scratch", type=Path)
parser.add_argument("--expect-bug", action="store_true")
args = parser.parse_args()
if platform.system() != "Darwin":
    parser.error("requires native Darwin, CoreGraphics and libdispatch")
args.scratch.mkdir(parents=True, exist_ok=True)


def run(argv, **kwargs):
    return subprocess.run(
        argv, check=True, capture_output=True, text=True, timeout=60, **kwargs
    ).stdout


derivations = json.loads(run(["nix", "derivation", "show", str(args.derivation)]))
derivation = next(iter(derivations.get("derivations", derivations).values()))
attributes = derivation.get("structuredAttrs") or derivation["env"]
source = Path(attributes["src"])
patches = attributes.get("patches", [])
if isinstance(patches, str):
    patches = patches.split()

with tempfile.TemporaryDirectory(
    prefix="sketchybar-lifetime-", dir=args.scratch.resolve()
) as directory:
    work = Path(directory)
    tree = work / "source"
    shutil.copytree(source, tree)
    for path in [tree, *tree.rglob("*")]:
        path.chmod(path.stat().st_mode | 0o200)
    for patch in patches:
        run(["git", "apply", patch], cwd=tree)

    window = (tree / "src/window.c").read_text()

    def section(start, end):
        return window[window.index(start) : window.index(end)]

    # Extract whole production functions, not a rewritten lifetime model.
    body = "".join(
        section(start, end)
        for start, end in [
            ("void window_init(", "static CFTypeRef window_create_region("),
            ("struct window* window_create()", "static void window_clear_background("),
            ("void window_clear(", "void windows_freeze("),
            ("static void window_defer_update(", "void window_send_to_space("),
            ("void window_close(", "void window_set_level("),
        ]
    )
    body += "\n" + "\n".join(
        line
        for line in (tree / "src/surface.c").read_text().splitlines()
        if not line.startswith("#include")
    )
    fixture = work / "lifetime.c"
    fixture.write_text(
        (HERE / "sketchybar-window-lifetime.c")
        .read_text()
        .replace("// PRODUCTION_FUNCTIONS", body)
    )
    binary = work / "lifetime"
    run(
        [
            "xcrun",
            "clang",
            "-g",
            "-O1",
            "-fsanitize=address,undefined",
            "-fno-omit-frame-pointer",
            "-Wno-unused-value",
            "-I" + str(tree / "src"),
            str(fixture),
            "-framework",
            "CoreGraphics",
            "-framework",
            "CoreFoundation",
            "-o",
            str(binary),
        ]
    )
    scenarios = (
        ["reopen", "destroy"]
        if args.expect_bug
        else [
            "normal",
            "reopen",
            "multi-reopen",
            "destroy",
            "heap-destroy",
            "closed",
            "fallback",
        ]
    )
    for scenario in scenarios:
        result = subprocess.run(
            [str(binary), scenario],
            check=False,
            capture_output=True,
            text=True,
            timeout=10,
            env=os.environ
            | {"ASAN_OPTIONS": "abort_on_error=1", "UBSAN_OPTIONS": "halt_on_error=1"},
        )
        if args.expect_bug:
            diagnostic = "bad-free" if scenario == "reopen" else "heap-use-after-free"
            assert result.returncode != 0 and diagnostic in result.stderr, result
            assert "_dispatch_async_and_wait_invoke" in result.stderr, result.stderr
            print(
                f"EXPECTED FAILURE {scenario}: {diagnostic} on the main dispatch queue"
            )
        else:
            assert result.returncode == 0, result.stdout + result.stderr
            assert "Sanitizer" not in result.stderr, result.stderr
            print(result.stdout.strip())
