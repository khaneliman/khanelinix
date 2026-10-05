"""Native Darwin cold evaluation stores backed by the installed build daemon."""

import argparse
import json
import os
import pathlib
import platform
import shutil
import subprocess
import tempfile
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument(
    "snapshot", help="exact immutable source already archived onto this host"
)
parser.add_argument("evidence", type=pathlib.Path)
parser.add_argument("--hosts", nargs="+", default=["khanelimac", "khanelimac-m1"])
args = parser.parse_args()
if platform.system() != "Darwin":
    parser.error("run on native Darwin, not a Linux evaluator")
args.evidence.mkdir(parents=True, exist_ok=True)
cache = pathlib.Path(
    os.environ.get("XDG_CACHE_HOME", pathlib.Path.home() / "Library/Caches")
)
cache.mkdir(parents=True, exist_ok=True)
options = ["--option", "substituters", "https://cache.nixos.org/"]
archive_command = [
    "nix",
    "flake",
    "archive",
    "--json",
    "--no-update-lock-file",
    "--no-write-lock-file",
    *options,
    "path:" + args.snapshot,
]
archive = json.loads(subprocess.check_output(archive_command, text=True))
source_paths = set()


def sources(node):
    source_paths.add(node["path"])
    for child in node.get("inputs", {}).values():
        sources(child)


sources(archive)
(args.evidence / "archive.json").write_text(json.dumps(archive, indent=2) + "\n")
(args.evidence / "source-paths.txt").write_text("\n".join(sorted(source_paths)) + "\n")
records = []
for host in args.hosts:
    task_root = pathlib.Path(
        tempfile.mkdtemp(prefix="khanelinix-darwin-eval-", dir=cache)
    )
    # Accept unsigned outputs from the installed build daemon only in scratch.
    eval_store = "local?root=" + str(task_root / "eval-root") + "&require-sigs=false"
    environment = os.environ | {"XDG_CACHE_HOME": str(task_root / "cache")}
    (task_root / "cache").mkdir()
    commands = []
    try:
        copy = ["nix", "copy", "--from", "daemon", "--to", eval_store, "--stdin"]
        commands.append(copy)
        subprocess.run(
            copy,
            input="\n".join(sorted(source_paths)),
            text=True,
            env=environment,
            check=True,
        )
        list_paths = ["nix", "path-info", "--store", eval_store, "--all"]
        before = subprocess.check_output(
            list_paths, text=True, env=environment
        ).splitlines()
        assert not any(path.endswith(".drv") for path in before), (
            "cold store was seeded with derivations"
        )
        command = [
            "nix",
            "eval",
            "--store",
            "daemon",
            "--eval-store",
            eval_store,
            "--option",
            "eval-cache",
            "false",
            "--option",
            "trace-import-from-derivation",
            "true",
            *options,
            "--no-update-lock-file",
            "--no-write-lock-file",
            "--raw",
            "--show-trace",
            "--print-build-logs",
            "path:"
            + archive["path"]
            + "#darwinConfigurations."
            + host
            + ".system.drvPath",
        ]
        commands.append(command)
        start = time.monotonic()
        with (args.evidence / (host + ".stderr")).open("w") as log:
            result = subprocess.run(
                command,
                stdout=subprocess.PIPE,
                stderr=log,
                text=True,
                env=environment,
                check=False,
            )
        after = subprocess.check_output(
            list_paths, text=True, env=environment
        ).splitlines()
        records.append(
            {
                "host": host,
                "platform": platform.platform(),
                "commands": commands,
                "seededPaths": before,
                "addedPaths": sorted(set(after) - set(before)),
                "exit": result.returncode,
                "drvPath": result.stdout,
                "seconds": round(time.monotonic() - start, 2),
            }
        )
        (args.evidence / "results.json").write_text(
            json.dumps(records, indent=2) + "\n"
        )
        print(host, "PASS" if result.returncode == 0 else "FAIL", flush=True)
        if result.returncode:
            raise SystemExit(result.returncode)
    finally:
        # Only the fresh evaluator store is disposable; never GC the shared daemon.
        for directory, _, _ in os.walk(task_root):
            os.chmod(directory, 0o700)
        shutil.rmtree(task_root)
