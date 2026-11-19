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
env["PATH"] = r["coreutils"] + ":" + r["grep"]
bin_dir = work / "bin"
bin_dir.mkdir()
recorder = (
    f"#!{sys.executable}\nimport json, os, sys\n"
    "from pathlib import Path\n"
    "Path(os.environ['ARGV_FILE']).write_text(json.dumps(sys.argv[1:]))\n"
    "if Path(sys.argv[0]).name == 'nixpkgs-review': print(os.environ.get('NIX_CONFIG', ''))\n"
)
for name in ["zellij", "compiler", "eza", "nix", "nixpkgs-review"]:
    path = bin_dir / name
    path.write_text(recorder)
    path.chmod(0o755)
env["PATH"] = str(bin_dir) + ":" + env["PATH"]
env["ARGV_FILE"] = str(work / "argv.json")
checks = []


def passed(name):
    checks.append(name)
    print("PASS:", name, flush=True)


darwin_system = work / "darwin-system"
(darwin_system / "sw/bin").mkdir(parents=True)
for relative, body in {
    "sw/bin/nix-env": """
        printf '%s\\n' "$NIX_REMOTE" "$@" >> "$DEPLOY_LOG"
        exit "$PROFILE_STATUS"
    """,
    "activate": 'printf "activate\\n" >> "$DEPLOY_LOG"',
}.items():
    executable = darwin_system / relative
    executable.write_text("#!/bin/sh\n" + body + "\n")
    executable.chmod(0o755)
deploy_setup = """
hostname() { echo command-regression-client; }
nix() {
    case "$1" in
        build) echo "$DARWIN_SYSTEM" ;;
        copy) echo copy >> "$DEPLOY_LOG" ;;
        *) return 99 ;;
    esac
}
sudo() { "$@"; }
export -f sudo
ssh() {
    if [ "$1" = -o ]; then return 0; fi
    [ "$1" = khanelimac ] && "$BASH" -c "$2"
}
"""
deploy_log = work / "deploy.log"
for profile_status in (0, 42):
    deploy_log.write_text("")
    result = subprocess.run(
        [r["bash"], "-euc", deploy_setup + r["deploy"], "deploy", "khanelimac"],
        env=env
        | {
            "DARWIN_SYSTEM": str(darwin_system),
            "DEPLOY_LOG": str(deploy_log),
            "NIX_SSHOPTS": "",
            "PROFILE_STATUS": str(profile_status),
        },
        stdin=subprocess.DEVNULL,
        timeout=10,
        check=False,
    )
    assert result.returncode == profile_status, result.returncode
    assert deploy_log.read_text().splitlines() == [
        "copy",
        "daemon",
        "--profile",
        "/nix/var/nix/profiles/system",
        "--set",
        str(darwin_system),
    ] + (["activate"] if profile_status == 0 else [])
passed(
    "Darwin switch registers the copied system and skips activation on profile failure"
)


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
    "zo": [
        "attach",
        "--create",
        project.name,
        "options",
        "--default-cwd",
        str(project),
    ],
}.items():
    run(
        [r["bash"], "--noprofile", "--norc", "-c", r["zellijAliases"][name]],
        cwd=project,
        env=env,
    )
    assert json.loads(Path(env["ARGV_FILE"]).read_text()) == expected
    Path(env["ARGV_FILE"]).unlink()
    run(
        [r["fish"], "--no-config", "-c", r["zellijFishFunctions"][name]["body"]],
        cwd=project,
        env=env,
    )
    assert json.loads(Path(env["ARGV_FILE"]).read_text()) == expected
passed(
    "four actual Zellij aliases preserve exact argv through Bash and Fish without sessions"
)

for name, expected in {
    "quoted": ["one two"],
    "unquoted": ["one", "two"],
    "assignment": ["one two"],
    "loop": ["one", "two"],
    "awk": ["two"],
    "positional": ["arg space", "computed", "arg space", "second"],
    "chained": ["one", "two three"],
}.items():
    body = r["fishSubstitutions"][name]["body"]
    output = run(
        [
            r["fish"],
            "--no-config",
            "-c",
            f"function probe\n{body}\nend\nprobe 'arg space' second",
        ],
        cwd=project,
        env=env,
    )
    assert output.splitlines() == expected, (name, output, expected)
passed(
    "Fish translator preserves quoted/unquoted substitution, assignment, loops, AWK and arguments"
)

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

assert {
    name for name, complex_alias in r["complexAliases"].items() if complex_alias
} == {
    "assignment",
    "backticks",
    "complex",
    "nativeOverride",
    "pipeline",
    "positional",
    "redirect",
    "sequence",
}


def invoke_alias(shell, name, *args, alias_env=env):
    aliases = r[f"{shell}Aliases"]
    if shell == "nu":
        setup = f"alias {name} = {aliases[name]}\n"
        if name in ("la", "tree"):
            setup = "alias eza = " + aliases["eza"] + "\n" + setup
        cmd = [r["nu"], "--no-config-file", "-c"]
        invocation = " ".join([name, *(json.dumps(arg) for arg in args)])
    else:
        quoted_args = " ".join(shlex.quote(arg) for arg in args)
        invocation = f"{name} {quoted_args}"
        if shell == "fish":
            cmd = [r["fish"], "--no-config", "-c"]
            if name in r["fishFunctions"]:
                setup = f"function {name}\n{r['fishFunctions'][name]['body']}\nend\n"
            else:
                setup = f"alias {name} {shlex.quote(aliases[name])}\n"
            if name in ("la", "tree", "ls"):
                setup = f"alias eza {shlex.quote(aliases['eza'])}\n" + setup
        else:
            cmd = (
                [r["bash"], "--noprofile", "--norc", "-c"]
                if shell == "bash"
                else [r["zsh"], "-f", "-c"]
            )
            setup = "shopt -s expand_aliases\n" if shell == "bash" else ""
            if name in ("la", "tree", "ls"):
                setup += f"alias eza={shlex.quote(aliases['eza'])}\n"
            setup += f"alias {name}={shlex.quote(aliases[name])}\n"
            invocation = "eval " + shlex.quote(invocation)
    return run([*cmd, setup + invocation], cwd=work, env=alias_env)


eza_options = [
    "--icons",
    "auto",
    "--git",
    "--group-directories-first",
    "--header",
    "--hyperlink",
    "--follow-symlinks",
]
for shell in ("bash", "zsh", "fish", "nu"):
    aliases = r[f"{shell}Aliases"]
    assert aliases["nativeOnly"] == "printf " + ("nushell" if shell == "nu" else shell)
    assert invoke_alias(shell, "nativeOverride") == "native"
    for name, options in {
        "la": ["-lah", "--tree"],
        "tree": ["--tree", "--icons=always"],
        **({} if shell == "nu" else {"ls": []}),
    }.items():
        invoke_alias(shell, name, "path with spaces")
        assert json.loads(Path(env["ARGV_FILE"]).read_text()) == [
            *eza_options,
            *options,
            "path with spaces",
        ]
assert "ls" not in r["nuAliases"]
assert r["fishAbbrs"]["la"] == "printf user-la"
assert r["fishAbbrs"]["ls"] == "eza"
assert "positional" not in r["fishAbbrs"]
assert "positional" in r["fishAbbrFunctions"]
assert "positional" not in r["fishAliases"]
assert "nativeOverride" not in r["fishFunctions"]
passed(
    "shared alias adaptation keeps native aliases, eza options and Fish abbreviations"
)

for shell in ("bash", "zsh", "fish", "nu"):
    assert invoke_alias(shell, "literal").splitlines() == ["$1 ; && || | > `word`"]
    assert invoke_alias(shell, "pipeline", "two words").splitlines() == ["two words"]
    assert invoke_alias(shell, "sequence").splitlines() == ["one", "two"]
    assert invoke_alias(shell, "positional", "two words", "other").splitlines() == [
        "two words",
        "two words",
        "other",
    ]
    assert invoke_alias(shell, "backticks").splitlines() == ["computed"]
    assert invoke_alias(shell, "assignment").splitlines() == ["two words"]
    redirected = work / f"{shell}-redirect"
    assert not invoke_alias(
        shell,
        "redirect",
        "two words",
        alias_env=env | {"REDIRECT_FILE": str(redirected)},
    )
    assert redirected.read_text() == "two words\n"
passed(
    "complex aliases preserve literal syntax, redirects, pipelines and argv across four shells"
)

for shell in ("bash", "zsh", "fish", "nu"):
    invoke_alias(shell, "nras", "review ref")
    assert json.loads(Path(env["ARGV_FILE"]).read_text()) == [
        "pr",
        "review ref",
        "--systems",
        "aarch64-darwin x86_64-linux aarch64-linux",
    ]
    for name, package in {
        "lua-update-all": "luarocks-packages-updater",
        "vim-update-all": "vimPluginsUpdater",
    }.items():
        invoke_alias(
            shell, name, "extra arg", alias_env=env | {"GITHUB_TOKEN": "fixture token"}
        )
        assert json.loads(Path(env["ARGV_FILE"]).read_text()) == [
            "run",
            f"nixpkgs#{package}",
            "--",
            "--github-token=fixture token",
            "extra arg",
        ]
    assert invoke_alias(
        shell, "npr-beast", "one arg", alias_env=env | {"NIX_CONFIG": ""}
    ).splitlines() == ["max-jobs = auto", "cores = 0"]
    assert json.loads(Path(env["ARGV_FILE"]).read_text()) == ["one arg"]
passed("developer review and updater aliases preserve exact argv across four shells")

op = work / "config space's" / "op"
op.mkdir(parents=True)
(op / "plugins.sh").write_text("printf 'wrong\\n'\n")
cmd = [r["fish"], "--no-config", "-c", r["fishInteractiveInit"]]
assert run(cmd, cwd=work, env=env) == ""
(op / "plugins.fish").write_text("printf 'native\\n'\n")
assert run(cmd, cwd=work, env=env) == "native\n"
passed("Fish startup skips the POSIX 1Password script and sources its native file")

zsh_setup = """
date() { [[ $1 == +%Y-%m-%d ]] && printf '2001-02-03'; }
autoload() { return 0; }
zmodload() { return 0; }
bashcompinit() { return 0; }
compinit() { print -r -- "$2"; }
"""
assert (
    run(
        [r["zsh"], "-f", "-c", zsh_setup + r["zshCompletionInit"]],
        cwd=work,
        env=env,
    )
    .strip()
    .endswith("-2001-02-03")
)
passed("Zsh completion uses portable date arguments for its daily cache path")

for stem, extension in [("hello", "c"), ("hello world", "c"), ("hello world", "cpp")]:
    for path in work.glob("*.c*"):
        path.unlink()
    (work / (stem + "." + extension)).write_text("")
    flags = ["-DVALUE=two words", "-I./include *", "", "single'quote", "$HOME"]
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
