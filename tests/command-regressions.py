"""Run: python3 tests/command-regressions.py NIXPKGS HOME_MANAGER IGNORED_SCRATCH.

Use the effective locked source inputs. --source-root permits isolated corrected
copies before integration. Build real emitted helpers; no flake/host evaluation,
lock updates, desktop calls, systemd service, Zellij session or SSH agent.
"""

import argparse
import json
import os
import shlex
import subprocess
import sys
import tempfile
import time
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("nixpkgs", type=Path)
parser.add_argument("home_manager", type=Path)
parser.add_argument("scratch", type=Path)
parser.add_argument(
    "--data-home-name",
    default='data space\'s $literal "quote" `literal` \\tail',
    help="fixture name; also permits replaying configuration-specific build failures",
)
parser.add_argument(
    "--source-root", type=Path, default=Path(__file__).resolve().parent.parent
)
args = parser.parse_args()
root = args.source_root.resolve()
args.scratch.mkdir(parents=True, exist_ok=True)
work = Path(tempfile.mkdtemp(prefix="command-regressions-", dir=args.scratch.resolve()))
env = os.environ | {
    "HOME": str(work / "home"),
    "XDG_CONFIG_HOME": str(work / "config"),
    "XDG_DATA_HOME": str(work / "data"),
    "XDG_CACHE_HOME": str(work / "cache"),
    "TMPDIR": str(work),
    "TERM": "dumb",
    "GIT_CONFIG_GLOBAL": os.devnull,
    "GIT_CONFIG_NOSYSTEM": "1",
    "GIT_CEILING_DIRECTORIES": str(work),
}
Path(env["HOME"]).mkdir()
data_home = work / args.data_home_name
parameters = {
    "nixpkgs": args.nixpkgs.resolve(),
    "homeManager": args.home_manager.resolve(),
    "root": root,
}
expression = (
    f"import (builtins.toPath {json.dumps(str(Path(__file__).with_suffix('.nix')))}) {{ "
    + " ".join(
        f"{name} = builtins.toPath {json.dumps(str(path))};"
        for name, path in parameters.items()
    )
    + f" dataHome = {json.dumps(str(data_home))}; }}"
)


def run(argv, **kwargs):
    result = subprocess.run(
        argv, capture_output=True, text=True, timeout=600, check=False, **kwargs
    )
    assert result.returncode == 0, (
        argv,
        result.returncode,
        result.stdout,
        result.stderr,
    )
    return result.stdout


run(["nix", "build", "--impure", "--no-link", "--expr", f"({expression}).packages"])
run(
    [
        "nix-store",
        "--realise",
        json.loads(
            run(
                [
                    "nix",
                    "eval",
                    "--impure",
                    "--json",
                    "--expr",
                    f"({expression}).sessionDrv",
                ]
            )
        ),
    ]
)
r = json.loads(
    run(["nix", "eval", "--impure", "--json", "--expr", f"({expression}).rendered"])
)
(work / "rendered.json").write_text(json.dumps(r, indent=2) + "\n")
# Use only the supplied runtime tools and inert recorders for shell lookups.
env["PATH"] = r["coreutils"]
bin_dir = work / "bin"
bin_dir.mkdir()
recorder = (
    f"#!{sys.executable}\nimport json, os, sys\n"
    "from pathlib import Path\n"
    "Path(os.environ['ARGV_FILE']).write_text(json.dumps(sys.argv[1:]))\n"
)
for name in ["zellij", "compiler"]:
    path = bin_dir / name
    path.write_text(recorder)
    path.chmod(0o755)
env["PATH"] = str(bin_dir) + ":" + env["PATH"]
env["ARGV_FILE"] = str(work / "argv.json")
checks = []


def passed(name):
    checks.append(name)
    print("PASS:", name, flush=True)


# Git status runs only inside the isolated fixture, never a user repository.
project = work / "parent space" / "project space"
project.mkdir(parents=True)
months = {time.strftime("%Y-%m")}
for session in ["synthetic-one", "synthetic-two"]:
    run(
        [r["sessionEnd"]],
        input=json.dumps({"session_id": session, "cwd": str(project)}),
        cwd=project,
        env=env,
    )
months.add(time.strftime("%Y-%m"))
logs = list((data_home / "claude-code/sessions").glob("*.log"))
assert logs and {p.stem for p in logs} <= months
content = "".join(p.read_text() for p in logs)
assert content.count("Session ID: synthetic-one\n") == 1
assert content.count("Session ID: synthetic-two\n") == 1
assert content.count(f"Directory: {project}\n") == 2
assert all(p.parent == data_home / "claude-code/sessions" for p in logs)
passed(
    "built SessionEnd logs twice at exact monthly path with spaces, apostrophe and literal dollar"
)

for name, expected in {
    "zns": ["-s", project.name, "options", "--default-cwd", str(project)],
    "zas": ["a", project.name],
    "zds": ["delete-session", project.name],
}.items():
    run(
        [r["bash"], "--noprofile", "--norc", "-c", r["zellijAliases"][name]],
        cwd=project,
        env=env,
    )
    assert json.loads(Path(env["ARGV_FILE"]).read_text()) == expected
passed("three actual Zellij aliases preserve exact argv without sessions")

# Execute the actual helper referenced by the built launcher's source. Neither
# systemd-run nor its login-shell wrapper needs to start for exporter semantics.
environment = json.loads(
    run(
        [
            r["environment"],
            sys.executable,
            "-c",
            "import json,os; print(json.dumps(dict(os.environ)))",
        ],
        env=env,
        cwd=work,
    )
)
assert "OMIT" not in environment
assert {
    key: environment[key] for key in ["ENABLED", "DISABLED", "COUNT", "EXPAND", "EXTRA"]
} == {
    "ENABLED": "true",
    "DISABLED": "false",
    "COUNT": "3",
    "EXPAND": env["HOME"] + "/expanded",
    "EXTRA": "present",
}
assert environment["PATH"] == env["HOME"] + "/space directory:" + env["PATH"]
passed("built apply-hm-env preserves native Home Manager exports and spaced PATH")

functions = root / "modules/home/programs/terminal/shells/fish/functions"


def fish(name, body, flags=()):
    return run(
        [
            r["fish"],
            "--no-config",
            *flags,
            "-c",
            f"source {shlex.quote(str(functions / (name + '.fish')))}\n" + body,
        ],
        cwd=work,
        env=env,
    )


target = work / "target space"
target.mkdir()
# Nonzero sentinels prove the helper returns the failing command's status.
for name, invocation, stub in [
    ("mkcd", f"mkcd {shlex.quote(str(target))}", "function mkdir; return 17; end"),
    (
        "mvcd",
        f"mvcd missing {shlex.quote(str(target))}",
        "function mkdir; return 17; end",
    ),
    ("mvcd", f"mvcd missing {shlex.quote(str(target))}", "function mv; return 23; end"),
]:
    expected = 23 if "function mv;" in stub else 17
    output = fish(
        name,
        f'{stub}\n{invocation}\nset -l result $status\nprintf "%s\\n%s\\n" $result "$PWD"',
    )
    assert output.splitlines() == [str(expected), str(work)]
output = fish(
    "mvcd",
    f'mvcd missing {shlex.quote(str(target))}\nset -l result $status\nprintf "%s\\n%s\\n" $result "$PWD"',
)
assert output.splitlines() == ["1", str(work)]
new = work / "new directory space"
assert fish(
    "mkcd",
    f'mkcd {shlex.quote(str(new))}\nset -l result $status\nprintf "%s\\n%s\\n" $result "$PWD"',
).splitlines() == ["0", str(new)]
source = work / "source file space"
source.write_text("exact moved contents\n")
assert fish(
    "mvcd",
    f'mvcd {shlex.quote(str(source))} {shlex.quote(str(target))}\nset -l result $status\nprintf "%s\\n%s\\n" $result "$PWD"',
).splitlines() == ["0", str(target)]
assert (
    not source.exists()
    and (target / source.name).read_text() == "exact moved contents\n"
)
passed("Fish mkcd/mvcd propagate failures, preserve cwd and move spaced content")

# A function replaces keychain before the real helper can call it. The process
# has isolated login/interactive universal-variable storage and no private keys.
output = fish(
    "load_ssh",
    """function keychain; printf ""; end
set -U SSH_KEYS_TO_AUTOLOAD custom-key
load_ssh
load_ssh
printf "%s\\n" $SSH_KEYS_TO_AUTOLOAD
set -eU SSH_KEYS_TO_AUTOLOAD
exit 0
""",
    flags=("--login", "--interactive"),
)
assert output.splitlines() == ["custom-key", env["HOME"] + "/.ssh/id_rsa"]
passed("Fish repeated login/interactive load_ssh retains one universal default key")

assert r["nuAliases"]["probe"] == "^head -n 1"
assert r["nuAliases"]["leading"] == "^head -n 1"
assert r["nuAliases"]["argument"] == "printf '%s' head"
assert r["nuAliases"]["complex"] == r["complexBridge"]
for name, expected, invocation in [
    ("probe", "first", '"first\\nsecond" | regression'),
    ("leading", "first", '"first\\nsecond" | regression'),
    ("argument", "head", "regression"),
    ("complex", "onetwo", "regression"),
]:
    output = run(
        [
            r["nu"],
            "--no-config-file",
            "-c",
            f"alias regression = {r['nuAliases'][name]}; {invocation}",
        ],
        cwd=work,
        env=env,
    )
    assert output.strip() == expected, (name, output)
passed(
    "actual Nushell aliases execute with first-word caret, unchanged arguments and complex bridge"
)

for stem, extension in [("hello", "c"), ("hello world", "c"), ("hello world", "cpp")]:
    for path in work.glob("*.c*"):
        path.unlink()
    (work / (stem + "." + extension)).write_text("")
    flags = ["-DVALUE=two words", "-Iinclude *", "", "single'quote", "$HOME"]
    run(
        [r["compilerHelper"], stem, *flags],
        cwd=work,
        env=env | {"CC": "compiler", "CXX": "compiler"},
    )
    assert json.loads(Path(env["ARGV_FILE"]).read_text()) == [
        "-ggdb",
        stem + "." + extension,
        "-o",
        stem,
        "-lm",
        "-Wall",
        *flags,
    ]
passed(
    "built C/C++ helper preserves source, output, spaced flags, literal glob and empty argument"
)

assert r["groups"] == {"main": ["network", "wireshark"], "manager": ["networkmanager"]}
passed("both Snowfall owners assign exact groups under declared khanelisnow namespace")
(work / "results.json").write_text(json.dumps({"passed": checks}, indent=2) + "\n")
print(f"{len(checks)}/{len(checks)} groups passed; evidence: {work}")
