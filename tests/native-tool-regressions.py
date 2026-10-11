"""Native Atuin/Yazi/Helix/WezTerm regressions on Linux, with isolated HOME/XDG and PTYs.

Run: python3 tests/native-tool-regressions.py /locked/nixpkgs /locked/home-manager ignored-scratch-dir
--source-root selects a scratch source tree for pre-integration checks.
Helix probes replay captured initialization options in real clangd with no compilation database.
Both Yazi platform branches are generated on Linux, not Darwin runtime tested.
WezTerm reads real HM Lua headlessly; font-family inputs are fixture-owned.
No sync, history, accounts, daemon, live trash or host/flake checks are invoked.
"""

import argparse
import fcntl
import json
import os
import pty
import queue
import re
import select
import shutil
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import threading
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
checked = 0


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


def expression(
    fixture, sync=False, darwin=False, helix_recorder=False, wezterm_settings=False
):
    paths = {
        "nixpkgs": args.nixpkgs,
        "homeManager": args.home_manager,
        "root": args.source_root,
    }
    parameters = " ".join(
        f"{key} = builtins.toPath {json.dumps(str(value.resolve()))};"
        for key, value in paths.items()
    )
    return f"import (builtins.toPath {json.dumps(str(HERE / 'native-tool-regressions.nix'))}) {{ {parameters} fixture = {json.dumps(str(fixture))}; sync = {str(sync).lower()}; darwin = {str(darwin).lower()}; helixRecorder = {str(helix_recorder).lower()}; weztermWithSettings = {str(wezterm_settings).lower()}; }}"


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
        "PATH": binaries["coreutils"] + ":/usr/bin:/bin",
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
    global checked
    checked += 1
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


def wezterm_case(with_settings):
    fixture = work / f"wezterm-{with_settings}"
    env = environment(fixture)
    expr = expression(fixture, wezterm_settings=with_settings)
    settings = evaluate(expr, "wezterm.settings")
    assert bool(settings) is with_settings, settings
    config = fixture / "generated.lua"
    shutil.copyfile(generated(expr, "wezterm"), config)
    status = fixture / "reader.json"
    observer = fixture / "observer.lua"
    # show-keys can exit 0 with defaults after storing a config error. Observe the
    # generated chunk without changing its result, then require the native binding.
    observer.write_text(
        "local wezterm = require 'wezterm'\n"
        f"local ok, result = pcall(function() return assert(loadfile({json.dumps(str(config))}))() end)\n"
        """
local record = { ok = ok }
if ok then
  for _, key in ipairs({ 'color_scheme', 'color_schemes', 'colors',
                         'font_size', 'scrollback_lines' }) do
    record[key] = result[key]
  end
  record.fonts_present = result.font ~= nil and #result.font_rules == 3
else
  record.error = tostring(result)
end
"""
        f"local file = assert(io.open({json.dumps(str(status))}, 'w'))\n"
        "file:write(wezterm.json_encode(record)); file:close()\n"
        "if not ok then error(result) end\nreturn result\n"
    )
    bindings = run(
        [binaries["wezterm"], "--config-file", str(observer), "show-keys", "--lua"],
        env=env,
        cwd=fixture,
    )
    (fixture / "bindings.lua").write_text(bindings + "\n")
    assert status.exists(), "WezTerm observer did not run"
    record = json.loads(status.read_text())
    assert record["ok"] is True, record
    assert re.search(
        r"\{\s*key = 'S',\s*mods = 'CTRL',\s*action = act\.PasteFrom 'PrimarySelection'\s*\}",
        bindings,
    ), "WezTerm used default keys instead of the wrapper's primary-selection binding"
    assert record["font_size"] == 13 and record["scrollback_lines"] == 10000, record
    assert record["fonts_present"] is True, record
    for key in ("color_scheme", "color_schemes", "colors"):
        if key in settings:
            assert record.get(key) == settings[key], (key, record, settings)
        else:
            assert key not in record, (key, record)


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


def clangd_diagnostics(fixture, env, initialize, document):
    """Replay Helix's captured options and document against the actual clangd."""
    messages = []
    responses = queue.Queue()
    stderr = (fixture / "clangd.log").open("w")
    argv = [
        binaries["clangd"],
        "--enable-config=0",
        "--background-index=0",
        "--clang-tidy=0",
        "--log=verbose",
        f"--compile-commands-dir={fixture}",
    ]
    proc = subprocess.Popen(
        argv,
        cwd=fixture,
        env=env,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=stderr,
    )

    def reader():
        while True:
            headers = {}
            while True:
                line = proc.stdout.readline()
                if not line:
                    return
                if line in (b"\r\n", b"\n"):
                    break
                key, value = line.decode().split(":", 1)
                headers[key.lower()] = value.strip()
            message = json.loads(proc.stdout.read(int(headers["content-length"])))
            messages.append(message)
            responses.put(message)

    thread = threading.Thread(target=reader, daemon=True)
    thread.start()

    def send(message):
        data = json.dumps({"jsonrpc": "2.0", **message}).encode()
        proc.stdin.write(f"Content-Length: {len(data)}\r\n\r\n".encode() + data)
        proc.stdin.flush()

    def wait_for(predicate):
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            try:
                message = responses.get(timeout=max(0.01, deadline - time.monotonic()))
            except queue.Empty:
                break
            if predicate(message):
                return message
        raise AssertionError("clangd did not return the expected response")

    try:
        params = {
            "processId": None,
            "rootUri": fixture.as_uri(),
            "capabilities": {},
        }
        if "initializationOptions" in initialize["params"]:
            params["initializationOptions"] = initialize["params"][
                "initializationOptions"
            ]
        send({"id": 1, "method": "initialize", "params": params})
        assert "result" in wait_for(lambda m: m.get("id") == 1)
        send({"method": "initialized", "params": {}})
        send({"method": "textDocument/didOpen", "params": document["params"]})
        diagnostics = wait_for(
            lambda m: (
                m.get("method") == "textDocument/publishDiagnostics"
                and m["params"]["uri"] == document["params"]["textDocument"]["uri"]
            )
        )["params"]["diagnostics"]
        send({"id": 2, "method": "shutdown", "params": None})
        wait_for(lambda m: m.get("id") == 2)
        send({"method": "exit", "params": None})
        proc.wait(timeout=5)
        assert proc.returncode == 0, f"clangd exit {proc.returncode}"
        (fixture / "clangd-result.json").write_text(
            json.dumps(
                {
                    "argv": argv,
                    "initialize": params,
                    "diagnostics": diagnostics,
                    "exit": proc.returncode,
                },
                indent=2,
            )
        )
        assert not [d for d in diagnostics if d.get("severity") == 1], diagnostics
    finally:
        if proc.poll() is None:
            proc.kill()
            proc.wait()
        thread.join(timeout=2)
        proc.stdin.close()
        proc.stdout.close()
        stderr.close()
        (fixture / "clangd-messages.json").write_text(json.dumps(messages, indent=2))


def helix_case(language, suffix, text):
    fixture = work / f"helix-{language}"
    env = environment(fixture)
    env["HELIX_PROBE_LOG"] = str(fixture / "lsp.jsonl")
    for server in ("clangd", "clangd-cpp"):
        recorder = fixture / f"{server}-recorder"
        recorder.write_text(
            "#!" + sys.executable + "\n" + (HERE / "helix-lsp-recorder.py").read_text()
        )
        recorder.chmod(0o755)
    expr = expression(fixture, helix_recorder=True)
    config = Path(env["XDG_CONFIG_HOME"]) / "helix"
    config.mkdir()
    shutil.copyfile(generated(expr, "helix"), config / "config.toml")
    language_file = Path(
        run(
            [
                "nix",
                "build",
                "--impure",
                "--no-link",
                "--print-out-paths",
                "--expr",
                f"({expr}).helix.languages",
            ]
        )
    )
    shutil.copyfile(language_file, config / "languages.toml")
    settings = evaluate(expr, "helix.settings")
    source = fixture / f"probe.{suffix}"
    source.write_text(text)
    run([binaries["helix"], "--health", language], env=env, cwd=fixture)
    master, slave = pty.openpty()
    proc = None
    output = bytearray()
    log = fixture / "hx.log"
    try:
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 120, 0, 0))
        argv = [binaries["helix"], "--log", str(log), "-vv", str(source)]
        (fixture / "helix-command.json").write_text(json.dumps(argv))
        proc = subprocess.Popen(
            argv,
            env=env,
            cwd=fixture,
            stdin=slave,
            stdout=slave,
            stderr=slave,
            start_new_session=True,
        )
        os.close(slave)
        slave = None
        deadline = time.monotonic() + 15
        phase = 0
        messages = []
        while time.monotonic() < deadline and proc.poll() is None:
            if select.select([master], [], [], 0.05)[0]:
                try:
                    chunk = os.read(master, 65536)
                except OSError:
                    break
                output.extend(chunk)
                if b"\x1b[6n" in chunk:
                    os.write(master, b"\x1b[1;1R")
            capture = Path(env["HELIX_PROBE_LOG"])
            if capture.exists():
                messages = [
                    json.loads(line)
                    for line in capture.read_text().splitlines(keepends=True)
                    if line.endswith("\n")
                ]
            status = log.read_text() if log.exists() else ""
            if phase == 0 and any(
                m.get("method") == "textDocument/didOpen" for m in messages
            ):
                os.write(master, b":get indent-guides\r")
                phase = 1
            elif phase == 1 and "editor status:" in status:
                os.write(master, b":indent-style\r")
                phase = 2
            elif phase == 2 and (
                language == "opencl" or "editor status: 2 spaces" in status
            ):
                os.write(master, b":quit!\r")
                phase = 3
        assert phase == 3, (
            "Helix did not consume config, detect language and inherit indentation"
        )
        proc.wait(timeout=3)
        assert proc.returncode == 0, output.decode(errors="replace")
        assert b"Bad config:" not in output, output.decode(errors="replace")
        initialize = next(m for m in messages if m.get("method") == "initialize")
        document = next(
            m for m in messages if m.get("method") == "textDocument/didOpen"
        )
        assert document["params"]["textDocument"]["languageId"] == language, document
        runtime_guides = json.loads(
            re.search(r"editor status: (\{[^\n]+\})", log.read_text())[1]
        )
        assert runtime_guides["render"] is True
        assert {
            key: runtime_guides.get(key) for key in settings["editor"]["indent-guides"]
        } == settings["editor"]["indent-guides"], runtime_guides
        # Diagnose the real document before checking flags, so a shared-flag mutation
        # exposes the C compiler regression as well as the dispatch mismatch.
        clangd_diagnostics(fixture, env, initialize, document)
        expected_server = "clangd-cpp" if language == "cpp" else "clangd"
        assert initialize["recorder"] == expected_server + "-recorder", initialize
        expected_options = (
            {"fallbackFlags": ["-std=c++2b"]} if language == "cpp" else None
        )
        assert initialize["params"].get("initializationOptions") == expected_options, (
            initialize
        )
    finally:
        if proc is not None and proc.poll() is None:
            os.killpg(proc.pid, signal.SIGTERM)
            proc.wait(timeout=3)
        if slave is not None:
            os.close(slave)
        os.close(master)
        (fixture / "terminal.log").write_bytes(output)


for language, suffix, text in [
    ("c", "c", "int main(void) { return 0; }\n"),
    (
        "cpp",
        "cpp",
        'static_assert(__cplusplus > 202002L, "C++23 fallback flags required");\n',
    ),
    ("opencl", "cl", "__kernel void probe(__global int *out) { out[0] = 1; }\n"),
]:
    check(
        f"Helix {language}: native dispatch/options and real clangd diagnostics",
        lambda language=language, suffix=suffix, text=text: helix_case(
            language, suffix, text
        ),
    )

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
for with_settings in (False, True):
    check(
        f"WezTerm settings={with_settings}: native load/bindings and exact colors",
        lambda with_settings=with_settings: wezterm_case(with_settings),
    )
print(f"{checked - len(failures)}/{checked} groups passed; artifacts: {work}")
raise SystemExit(bool(failures))
