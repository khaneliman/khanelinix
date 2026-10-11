"""Run: python3 tests/angular-wrappers.py NIXPKGS IGNORED_SCRATCH.

Build and execute actual Angular wrappers without installing the Angular app.
--native-fixture optionally reuses already-restored locked TS7 node_modules;
no registry access, dependency changes, flake/host checks or daemon startup.
"""

import argparse
import json
import os
import queue
import shutil
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("nixpkgs", type=Path)
parser.add_argument("scratch", type=Path)
parser.add_argument(
    "--source-root", type=Path, default=Path(__file__).resolve().parents[1]
)
parser.add_argument("--native-fixture", type=Path)
args = parser.parse_args()
root = args.source_root.resolve()
args.scratch.mkdir(parents=True, exist_ok=True)
work = Path(tempfile.mkdtemp(prefix="angular-wrappers-", dir=args.scratch.resolve()))
env = os.environ | {
    "HOME": str(work / "home"),
    "XDG_CONFIG_HOME": str(work / "config"),
    "XDG_CACHE_HOME": str(work / "cache"),
    "TMPDIR": str(work),
    "npm_config_cache": str(work / "npm-cache"),
    "npm_config_offline": "true",
    "ESLINT_CALLS": str(work / "eslint-calls"),
}
Path(env["HOME"]).mkdir()
records = []


def run(argv, cwd=work, expected=0):
    result = subprocess.run(
        argv, cwd=cwd, env=env, text=True, capture_output=True, timeout=120, check=False
    )
    records.append(
        {
            "command": argv,
            "cwd": str(cwd),
            "exit": result.returncode,
            "stdout": result.stdout,
            "stderr": result.stderr,
        }
    )
    (work / "results.json").write_text(json.dumps(records, indent=2) + "\n")
    assert result.returncode == expected, records[-1]
    return result.stdout, result.stderr


def nix_path(path):
    return "builtins.toPath " + json.dumps(str(path.resolve()))


expression = (
    f"import ({nix_path(Path(__file__).with_suffix('.nix'))}) {{ "
    f"nixpkgs = {nix_path(args.nixpkgs)}; root = {nix_path(root)}; }}"
)
outputs = json.loads(
    run(
        [
            "nix",
            "build",
            "--impure",
            "--no-link",
            "--json",
            "--expr",
            f"({expression}).packages",
        ]
    )[0]
)
bins = [Path(p["outputs"]["out"]) / "bin" for p in outputs]
wrappers = {
    name: str(next(p / name for p in bins if (p / name).is_file()))
    for name in ("ng", "tsc", "typescript-lsp")
}
rendered = json.loads(
    run(["nix", "eval", "--impure", "--json", "--expr", f"({expression}).rendered"])[0]
)
(work / "rendered.json").write_text(json.dumps(rendered, indent=2) + "\n")
traps = work / "traps"
traps.mkdir()
for name in ("npm", "npx"):
    trap = traps / name
    trap.write_text(
        f'#!{rendered["bash"]}\nprintf "%s\\n" "$0 $*" >> "$REGISTRY_CALLS"\nexit 98\n'
    )
    trap.chmod(0o755)
env.update(
    PATH=str(traps) + os.pathsep + rendered["runtimePath"],
    REGISTRY_CALLS=str(work / "registry-calls"),
)
run([rendered["bash"], "-c", rendered["shellHook"]])
assert not Path(env["ESLINT_CALLS"]).exists(), "shell hook started ESLint"
empty = work / "empty"
empty.mkdir()
for name, executable in wrappers.items():
    _, stderr = run([executable, "--help"], cwd=empty, expected=1)
    assert "npm ci" in stderr and "project root" in stderr, (name, stderr)
fixture = work / "project with spaces"
local_bin = fixture / "node_modules/.bin"
local_bin.mkdir(parents=True)
for name in ("ng", "tsc"):
    recorder = local_bin / name
    recorder.write_text(
        f"#!{sys.executable}\nimport json,sys\nprint(json.dumps(sys.argv[1:]))\n"
    )
    recorder.chmod(0o755)
argv = ["--stdio", "two words", "", "literal *", "$(touch forbidden)", "quote'\"\\tail"]
for name, executable in wrappers.items():
    stdout, _ = run([executable, *argv], cwd=fixture)
    assert json.loads(stdout) == (["--lsp"] if name == "typescript-lsp" else []) + argv
    # An installed but non-executable local binary must also fail locally.
    binary = local_bin / ("ng" if name == "ng" else "tsc")
    binary.chmod(0o644)
    _, stderr = run([executable, "--help"], cwd=fixture, expected=1)
    assert "npm ci" in stderr and "project root" in stderr
    binary.chmod(0o755)
assert not (fixture / "forbidden").exists()
assert not Path(env["REGISTRY_CALLS"]).exists(), "wrapper called npm/npx"
assert not Path(env["npm_config_cache"]).exists(), "wrapper populated an npm cache"
print(
    "PASS generated ng/tsc/LSP: literal argv, --lsp, missing/non-executable install, no npm/npx or ESLint startup"
)

if args.native_fixture:
    native = work / "native"
    native.mkdir()
    shutil.copytree(
        args.native_fixture / "node_modules", native / "node_modules", symlinks=True
    )
    lock = json.loads((root / "templates/angular/package-lock.json").read_text())[
        "packages"
    ]
    for package in list((native / "node_modules").glob("*/package.json")) + list(
        (native / "node_modules").glob("@*/*/package.json")
    ):
        key = package.parent.relative_to(native).as_posix()
        assert (
            key in lock
            and json.loads(package.read_text())["version"] == lock[key]["version"]
        ), key
    source = 'const greeting: string = "hello";\ngreeting;\n'
    (native / "hello.ts").write_text(source)
    (native / "tsconfig.json").write_text(
        '{"compilerOptions":{"strict":true,"noEmit":true},"files":["hello.ts"]}\n'
    )
    stdout, _ = run([wrappers["tsc"], "--version"], cwd=native)
    assert lock["node_modules/typescript"]["version"] in stdout
    run([wrappers["tsc"], "--noEmit"], cwd=native)
    proc = subprocess.Popen(
        [wrappers["typescript-lsp"], "--stdio"],
        cwd=native,
        env=env,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    messages = queue.Queue()
    frames = []

    def read_frames():
        try:
            while True:
                headers = {}
                while True:
                    line = proc.stdout.readline()
                    if not line:
                        return
                    if line == b"\r\n":
                        break
                    key, value = line.decode().split(":", 1)
                    headers[key.lower()] = value.strip()
                message = json.loads(proc.stdout.read(int(headers["content-length"])))
                frames.append(message)
                messages.put(message)
        except (OSError, ValueError, KeyError) as error:
            messages.put({"reader_error": str(error)})

    def send(message):
        data = json.dumps(message).encode()
        proc.stdin.write(f"Content-Length: {len(data)}\r\n\r\n".encode() + data)
        proc.stdin.flush()

    def response(request_id):
        deadline = time.monotonic() + 20
        while True:
            message = messages.get(timeout=max(0, deadline - time.monotonic()))
            assert "reader_error" not in message, message
            if "method" in message and "id" in message:
                send(
                    {
                        "jsonrpc": "2.0",
                        "id": message["id"],
                        "result": []
                        if message["method"] == "workspace/configuration"
                        else None,
                    }
                )
            elif message.get("id") == request_id:
                assert "error" not in message, message
                return message["result"]

    threading.Thread(target=read_frames, daemon=True).start()
    try:
        send(
            {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": {
                    "processId": None,
                    "rootUri": native.as_uri(),
                    "capabilities": {},
                },
            }
        )
        assert response(1)["capabilities"]["hoverProvider"]
        send({"jsonrpc": "2.0", "method": "initialized", "params": {}})
        uri = (native / "hello.ts").as_uri()
        send(
            {
                "jsonrpc": "2.0",
                "method": "textDocument/didOpen",
                "params": {
                    "textDocument": {
                        "uri": uri,
                        "languageId": "typescript",
                        "version": 1,
                        "text": source,
                    }
                },
            }
        )
        send(
            {
                "jsonrpc": "2.0",
                "id": 2,
                "method": "textDocument/hover",
                "params": {
                    "textDocument": {"uri": uri},
                    "position": {"line": 1, "character": 3},
                },
            }
        )
        hover = json.dumps(response(2))
        assert "greeting" in hover and "string" in hover, hover
        send({"jsonrpc": "2.0", "id": 3, "method": "shutdown"})
        assert response(3) is None
        send({"jsonrpc": "2.0", "method": "exit"})
        # TS7's open-stdin exit notification currently exits 1, not 0.
        exitcode = proc.wait(timeout=15)
        assert exitcode == 1, exitcode
        print(
            "PASS locked native TypeScript: version, noEmit, initialize/hover/shutdown; native exit 1 retained"
        )
    finally:
        if proc.poll() is None:
            proc.kill()
            proc.wait()
        (work / "lsp.json").write_text(
            json.dumps(
                {
                    "frames": frames,
                    "exit": proc.returncode,
                    "stderr": proc.stderr.read().decode(),
                },
                indent=2,
            )
            + "\n"
        )
else:
    print(
        "SKIP native protocol: provide --native-fixture with restored locked node_modules"
    )
print(f"Evidence: {work}")
