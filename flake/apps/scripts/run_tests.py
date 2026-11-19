"""Run the focused Linux regression checks in docs/support.md."""

import argparse
import json
import os
import platform
import shlex
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import NamedTuple


class Check(NamedTuple):
    args: tuple[str, ...] = ()
    tools: tuple[str, ...] = ()


CHECKS = {
    "module-regressions": Check(("{nixpkgs}", "{scratch}"), ("openssh",)),
    "command-regressions": Check(("{nixpkgs}", "{home-manager}", "{scratch}")),
    "terminal-recovery": Check(
        ("{root}", "{scratch}"),
        ("fish", "gzip", "bzip2", "unzip", "ncompress", "p7zip"),
    ),
    "terminal-regressions": Check(("{nixpkgs}",)),
    "terminal-data-regressions": Check(("{nixpkgs}", "{scratch}", "{home-manager}")),
    "native-tool-regressions": Check(("{nixpkgs}", "{home-manager}", "{scratch}")),
    "angular-wrappers": Check(("{nixpkgs}", "{scratch}")),
    "snowfall-dns-regressions": Check(("{nixpkgs}",)),
    "graphical-commands": Check(
        (
            "--nixpkgs",
            "{nixpkgs}",
            "--home-manager",
            "{home-manager}",
            "--niri",
            "{niri}",
            "--scratch",
            "{scratch}",
        ),
        ("jq",),
    ),
    "graphical-workflows": Check(
        ("--scratch", "{scratch}", "--lua", "lua"), ("lua5_4", "file")
    ),
    "weather-regressions": Check(
        ("--nixpkgs", "{nixpkgs}", "--lua", "lua", "--scratch", "{scratch}"),
        ("lua5_4", "jq"),
    ),
    "gnome-regressions": Check(
        ("{nixpkgs}", "{home-manager}", "{shell_schemas}", "{desktop_schemas}")
    ),
    "package-runtime-regressions": Check(("{nixpkgs}",)),
}
COMMON_TOOLS = (
    "bash",
    "coreutils",
    "diffutils",
    "findutils",
    "gawk",
    "git",
    "gnugrep",
    "gnused",
)


def locked_sources(root):
    flake = json.dumps("git+" + root.as_uri())
    expression = f"""
      let
        flake = builtins.getFlake {flake};
      in builtins.mapAttrs (_: input: input.outPath) {{
        inherit (flake.inputs) nixpkgs home-manager niri;
      }}
    """
    return json.loads(
        subprocess.check_output(
            [
                "nix",
                "eval",
                "--no-write-lock-file",
                "--impure",
                "--json",
                "--expr",
                expression,
            ],
            cwd=root,
        )
    )


def build(nixpkgs, expression):
    expression = f"let pkgs = import (builtins.toPath {json.dumps(nixpkgs)}) {{}}; in {expression}"
    return Path(
        subprocess.check_output(
            [
                "nix",
                "build",
                "--impure",
                "--no-link",
                "--print-out-paths",
                "--expr",
                expression,
            ],
            text=True,
        ).strip()
    )


def run_check(name, check, root, scratch, sources):
    scratch.mkdir()
    context = sources | {"root": root, "scratch": scratch}
    python = sys.executable
    env = os.environ | {"TMPDIR": str(scratch), "PYTHONDONTWRITEBYTECODE": "1"}
    env.pop("PYTHONOPTIMIZE", None)
    if name == "terminal-recovery":
        env.update(FISH="fish", COMPRESS="compress", SEVENZIP="7z")
    elif name == "graphical-commands":
        build(sources["nixpkgs"], "pkgs.swaylock-effects")
    elif name == "gnome-regressions":
        manifest = build(
            sources["nixpkgs"],
            """
              pkgs.writeText "regression-gnome-tools.json" (builtins.toJSON {
                python = "${pkgs.python3.withPackages (ps: [ ps.pygobject3 ])}/bin/python3";
                typelib = "${pkgs.glib.out}/lib/girepository-1.0";
                shell_schemas = pkgs.glib.getSchemaPath pkgs.gnome-shell;
                desktop_schemas = pkgs.glib.getSchemaPath pkgs.gsettings-desktop-schemas;
              })
            """,
        )
        gnome = json.loads(manifest.read_text())
        python = gnome["python"]
        env["GI_TYPELIB_PATH"] = gnome["typelib"]
        context.update(gnome)

    script = root / "tests" / f"{name}.py"
    command = [python, str(script), *(arg.format_map(context) for arg in check.args)]
    print(f"+ {shlex.join(command)}", flush=True)
    packages = [
        f"path:{sources['nixpkgs']}#{tool}" for tool in (*check.tools, *COMMON_TOOLS)
    ]
    subprocess.run(
        ["nix", "shell", "--no-write-lock-file", *packages, "--command", *command],
        cwd=scratch if name == "package-runtime-regressions" else root,
        env=env,
        check=True,
    )


def main(argv=None):
    parser = argparse.ArgumentParser(prog="run-tests", description=__doc__)
    parser.add_argument(
        "checks", nargs="*", metavar="CHECK", help="checks to run (default: all)"
    )
    parser.add_argument(
        "--list", action="store_true", help="list the available checks and exit"
    )
    parser.add_argument(
        "--root", type=Path, help="checkout root (default: find it from this directory)"
    )
    parser.add_argument(
        "--scratch", type=Path, help="parent directory for this run's scratch files"
    )
    args = parser.parse_intermixed_args(argv)
    if args.list:
        print("\n".join(CHECKS))
        return 0

    selected = list(dict.fromkeys(args.checks or CHECKS))
    unknown = [name for name in selected if name not in CHECKS]
    if unknown:
        parser.error(f"unknown check(s): {', '.join(unknown)}; use --list")
    if platform.system() != "Linux":
        parser.error("the focused regression suite requires Linux")

    cwd = Path.cwd()
    root = args.root or next(
        (path for path in (cwd, *cwd.parents) if (path / "flake.lock").is_file()), cwd
    )
    root = root.resolve()
    if (
        not (root / "flake.lock").is_file()
        or not (root / "tests/module-regressions.py").is_file()
    ):
        parser.error(f"not a khanelinix checkout: {root}; use --root")

    cache = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache")
    parent = (args.scratch or cache / "khanelinix-regressions").resolve()
    try:
        sources = locked_sources(root)
        parent.mkdir(parents=True, exist_ok=True)
        scratch = Path(tempfile.mkdtemp(prefix="run-", dir=parent))
    except (OSError, subprocess.CalledProcessError) as error:
        print(f"Could not prepare regression run: {error}", file=sys.stderr)
        return 1

    print(f"Regression scratch: {scratch}", flush=True)
    failed = []
    for name in selected:
        print(f"\n== {name} ==", flush=True)
        try:
            run_check(name, CHECKS[name], root, scratch / name, sources)
        except (OSError, ValueError, subprocess.CalledProcessError) as error:
            print(f"FAIL {name}: {error}", file=sys.stderr, flush=True)
            failed.append(name)
        else:
            print(f"PASS {name}", flush=True)
    print(f"\n{len(selected) - len(failed)} passed, {len(failed)} failed", flush=True)
    if failed:
        print(f"Failed checks: {', '.join(failed)}", flush=True)
    return int(bool(failed))


if __name__ == "__main__":
    sys.exit(main())
