"""Native Atuin/Yazi regressions on Linux, with isolated HOME/XDG and PTYs.

Run: python3 tests/native-tool-regressions.py /locked/nixpkgs /locked/home-manager ignored-scratch-dir
--source-root selects a scratch source tree for pre-integration checks.
Both Yazi platform branches are generated on Linux, not Darwin runtime tested.
No sync, history, accounts, daemon, live trash or host/flake checks are invoked.
"""

import argparse
import fcntl
import json
import os
import pty
import select
import shutil
import struct
import subprocess
import tempfile
import termios
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("nixpkgs", type=Path)
parser.add_argument("home_manager", type=Path)
parser.add_argument("scratch", type=Path)
parser.add_argument("--source-root", type=Path, default=HERE.parent)
args = parser.parse_args()
args.scratch.mkdir(parents=True, exist_ok=True)
work = Path(tempfile.mkdtemp(prefix="native-tools-", dir=args.scratch.resolve()))
commands = []
failures = []


def run(argv, **kwargs):
    result = subprocess.run(
        argv, text=True, capture_output=True, timeout=300, check=False, **kwargs
    )
    commands.append(
        {
            "argv": argv,
            "exit": result.returncode,
            "stdout": result.stdout,
            "stderr": result.stderr,
        }
    )
    (work / "commands.json").write_text(json.dumps(commands, indent=2))
    assert result.returncode == 0, result.stderr
    return result.stdout.strip()


def expression(fixture, sync=False, darwin=False):
    paths = {
        "nixpkgs": args.nixpkgs,
        "homeManager": args.home_manager,
        "root": args.source_root,
    }
    parameters = " ".join(
        f"{key} = builtins.toPath {json.dumps(str(value.resolve()))};"
        for key, value in paths.items()
    )
    return f"import (builtins.toPath {json.dumps(str(HERE / 'native-tool-regressions.nix'))}) {{ {parameters} fixture = {json.dumps(str(fixture))}; sync = {str(sync).lower()}; darwin = {str(darwin).lower()}; }}"


def evaluate(expr, attribute):
    return json.loads(
        run(["nix", "eval", "--impure", "--json", "--expr", f"({expr}).{attribute}"])
    )


def generated(expr, tool):
    return Path(
        run(
            [
                "nix",
                "build",
                "--impure",
                "--no-link",
                "--print-out-paths",
                "--expr",
                f"({expr}).{tool}.generated",
            ]
        )
    )


def environment(fixture):
    env = {
        "PATH": "/usr/bin:/bin",
        "TERM": "xterm-256color",
        "LANG": "C.UTF-8",
        "HOME": str(fixture / "home space"),
    }
    for key, folder in [
        ("XDG_CONFIG_HOME", "config"),
        ("XDG_DATA_HOME", "data"),
        ("XDG_STATE_HOME", "state"),
        ("XDG_CACHE_HOME", "cache"),
        ("XDG_RUNTIME_DIR", "runtime"),
    ]:
        env[key] = str(fixture / folder)
    for key, value in env.items():
        if key == "HOME" or key.startswith("XDG_"):
            Path(value).mkdir(parents=True, exist_ok=True)
    Path(env["XDG_RUNTIME_DIR"]).chmod(0o700)
    return env


def check(name, test):
    try:
        test()
        print("PASS:", name, flush=True)
    except AssertionError as error:
        failures.append(name)
        print("FAIL:", name, error, flush=True)


expr = expression(work)
run(["nix", "build", "--impure", "--no-link", "--expr", f"({expr}).packages"])
binaries = evaluate(expr, "binaries")


def atuin_case(sync):
    fixture = work / f"atuin-{sync}"
    env = environment(fixture)
    expr = expression(fixture, sync=sync)
    settings = evaluate(expr, "atuin.settings")
    config = Path(env["XDG_CONFIG_HOME"]) / "atuin"
    config.mkdir()
    shutil.copyfile(generated(expr, "atuin"), config / "config.toml")
    env["ATUIN_CONFIG_DIR"] = str(config)
    actual = run(
        [binaries["atuin"], "config", "get", "auto_sync", "--resolved"],
        env=env,
        cwd=fixture,
    )
    assert actual == str(sync).lower(), f"native auto_sync: {actual}, expected {sync}"
    assert settings["auto_sync"] is sync
    if sync:
        assert settings["sync_address"] == "https://api.atuin.sh"
        assert settings["sync_frequency"] == "30m"
    else:
        assert "sync_address" not in settings and "sync_frequency" not in settings


def drain(master, seconds):
    output = b""
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        if select.select(
            [master], [], [], min(0.05, max(0, deadline - time.monotonic()))
        )[0]:
            try:
                chunk = os.read(master, 65536)
            except OSError:
                break
            if not chunk:
                break
            output += chunk
            # Yazi waits for the emulator's DA1 reply before normal shutdown.
            if b"\x1b[0c" in output:
                os.write(master, b"\x1b[?1;2c")
                output = output.replace(b"\x1b[0c", b"[DA1 answered]")
    return output


def navigate(binary, fixture, env, key, expected):
    cwdfile = fixture / f"{key}-cwd.txt"
    master, slave = pty.openpty()
    proc = None
    output = b""
    try:
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 120, 0, 0))
        proc = subprocess.Popen(
            [binary, "--cwd-file", str(cwdfile), str(fixture)],
            stdin=slave,
            stdout=slave,
            stderr=slave,
            env=env,
            cwd=fixture,
            start_new_session=True,
        )
        os.close(slave)
        slave = None
        deadline = time.monotonic() + 5
        while b"\x1b[?2026l" not in output and time.monotonic() < deadline:
            output += drain(master, 0.1)
        assert b"\x1b[?2026l" in output, "terminal did not finish startup"
        os.write(master, ("g" + key).encode())
        output += drain(master, 0.4)
        os.write(master, b"q")
        output += drain(master, 0.3)
        try:
            proc.wait(timeout=3)
        except subprocess.TimeoutExpired:
            raise AssertionError("Yazi did not exit normally")
        assert proc.returncode == 0, f"Yazi exit {proc.returncode}"
        actual = cwdfile.read_text().strip() if cwdfile.exists() else None
        assert actual == str(expected), (
            f"g {key}: {actual!r}, expected {str(expected)!r}"
        )
    finally:
        if proc is not None and proc.poll() is None:
            proc.kill()
            proc.wait()
        if slave is not None:
            os.close(slave)
        os.close(master)
        (fixture / f"{key}-terminal.log").write_bytes(output)


for sync in (False, True):

    def gates(sync=sync):
        assert evaluate(expression(work, sync=sync), "gates") is True

    check(f"Both wrappers disabled, sync={sync}: no output beyond HM defaults", gates)
    check(
        f"Atuin sync={sync}: native resolved config", lambda sync=sync: atuin_case(sync)
    )
for darwin in (False, True):
    fixture = work / ("darwin-generated" if darwin else "linux-generated")
    env = environment(fixture)
    expr = expression(fixture, darwin=darwin)
    keymap = evaluate(expr, "yazi.keymap")
    config = fixture / "yazi-config"
    config.mkdir()
    shutil.copyfile(generated(expr, "yazi"), config / "keymap.toml")
    env["YAZI_CONFIG_HOME"] = str(config)
    commands_by_key = {
        entry["on"][1]: entry["run"] for entry in keymap["prepend_keymap"]
    }
    assert commands_by_key["b"] == "plugin trash"
    assert commands_by_key["<Space>"] == "cd --interactive"
    assert (
        commands_by_key["r"] == 'shell -- ya emit cd "$(git rev-parse --show-toplevel)"'
    )
    (fixture / "generated-commands.json").write_text(
        json.dumps(commands_by_key, indent=2)
    )
    cases = [("h", "home space"), ("c", "config space"), ("w", "data space/wallpapers")]
    if darwin:
        cases.append(("C", "home space/Library/Mobile Documents/com~apple~CloudDocs"))
    for key, tail in cases:
        expected = fixture / tail
        expected.mkdir(parents=True, exist_ok=True)
        check(
            f"Yazi {fixture.name} g {key}: exact native cwd with spaces",
            lambda fixture=fixture, env=env, key=key, expected=expected: navigate(
                binaries["yazi"], fixture, env, key, expected
            ),
        )
print(f"{11 - len(failures)}/11 groups passed; artifacts: {work}")
raise SystemExit(bool(failures))
