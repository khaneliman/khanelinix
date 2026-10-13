"""Terminal regressions using isolated module renders and real Fish/Git execution.

Run from the repository on Linux with Nix, Python 3 and Git:
    python3 tests/terminal-regressions.py /path/to/effective/locked/nixpkgs
Use the source selected by the root flake.lock nixpkgs input, not another node.
--source-root selects a scratch source tree for pre-integration checks.
Temporary files stay under $XDG_CACHE_HOME (default: ~/.cache); no host or
whole-flake evaluation, desktop notification, activation or lock update occurs.
Codex/OpenCode/editor doubles record argv and status; Git check-ignore and cd
repository discovery use real Git in a temporary, uncommitted repository.
Grep and !alias expansion use locked Git; nested alias commands are recorded
with GIT_EXEC_PATH isolated and all Git network protocols denied.
Darwin window settings are rendered on Linux, not tested on a Darwin runtime.
"""

import argparse
import json
import os
import shlex
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("nixpkgs", type=Path, help="local effective locked nixpkgs source")
parser.add_argument("--source-root", type=Path, default=HERE.parent)
args = parser.parse_args()
REPO = args.source_root.resolve()
SOURCE = REPO / "modules/home/programs/terminal"
cache = (
    Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
    / "khanelinix/terminal-regressions"
)
cache.mkdir(parents=True, exist_ok=True)


def run(args, **kwargs):
    return subprocess.run(
        args, text=True, capture_output=True, timeout=300, check=False, **kwargs
    )


def expression(gateway=False):
    paths = {"source": SOURCE, "repo": REPO, "nixpkgs": args.nixpkgs.resolve()}
    parameters = " ".join(
        f"{name} = builtins.toPath {json.dumps(str(path))};"
        for name, path in paths.items()
    )
    return f"import (builtins.toPath {json.dumps(str(HERE / 'terminal-regressions.nix'))}) {{ {parameters} gatewayEnabled = {str(gateway).lower()}; }}"


expr = expression()
build = run(["nix", "build", "--impure", "--no-link", "--expr", f"({expr}).packages"])
assert build.returncode == 0, build.stderr
r = run(
    [
        "nix",
        "eval",
        "--impure",
        "--json",
        "--expr",
        f'builtins.removeAttrs ({expr}) ["packages"]',
    ]
)
assert r.returncode == 0, r.stderr
render = json.loads(r.stdout)
build = run(["nix-store", "--realise", *render["notifyDrvs"]])
assert build.returncode == 0, build.stderr
fish = render["fish"]
failures = []


def check(name, test):
    try:
        test()
        print("PASS", name, flush=True)
    except (AssertionError, subprocess.CalledProcessError) as error:
        failures.append(name)
        print("FAIL", name, str(error), flush=True)


with tempfile.TemporaryDirectory(prefix="runtime-", dir=cache) as directory:
    work = Path(directory)
    env = os.environ | {
        "HOME": str(work / "home"),
        "XDG_CONFIG_HOME": str(work / "config"),
        "XDG_DATA_HOME": str(work / "data"),
    }
    Path(env["HOME"]).mkdir()
    bindir = work / "bin"
    bindir.mkdir()
    env["PATH"] = str(bindir) + ":" + env["PATH"]
    env["ARGS_FILE"] = str(work / "argv.json")
    env["COMMAND_FILE"] = str(work / "command")
    env["COMMAND_STATUS"] = "0"
    env["GIT_CEILING_DIRECTORIES"] = str(work)
    env["GIT_CONFIG_GLOBAL"] = os.devnull
    env["GIT_CONFIG_NOSYSTEM"] = "1"
    repository = work / "repository"
    result = run(
        ["git", "init", "-q", str(repository)],
        env=os.environ | {"GIT_CONFIG_GLOBAL": os.devnull, "GIT_CONFIG_NOSYSTEM": "1"},
    )
    assert result.returncode == 0, result.stderr
    (repository / "nested").mkdir()
    for command in ["codex", "opencode", "git", "code"]:
        path = bindir / command
        path.write_text(
            "#!"
            + sys.executable
            + '\nimport json,os,sys\nfrom pathlib import Path\nPath(os.environ["ARGS_FILE"]).write_text(json.dumps(sys.argv[1:]))\nPath(os.environ["COMMAND_FILE"]).write_text(Path(sys.argv[0]).name)\nsys.exit(int(os.environ["COMMAND_STATUS"]))\n'
        )
        path.chmod(0o755)
    (bindir / "code").write_text(
        "#!"
        + sys.executable
        + '\nimport os\nfrom pathlib import Path\nPath(os.environ["CODE_MARKER"]).touch()\n'
    )
    env["CODE_MARKER"] = str(work / "editor-invoked")

    def execute(body, test, external_git=False):
        Path(env["ARGS_FILE"]).unlink(missing_ok=True)
        Path(env["COMMAND_FILE"]).unlink(missing_ok=True)
        script = work / "test.fish"
        script.write_text("function onefetch\n return 0\nend\n" + body + "\n" + test)
        syntax = run([fish, "--no-config", "-n", str(script)])
        assert syntax.returncode == 0, syntax.stderr
        execution_env = dict(env)
        if external_git:
            execution_env["PATH"] = os.environ["PATH"]
        result = run(
            [fish, "--no-config", str(script)], env=execution_env, cwd=repository
        )
        assert result.returncode == 0, result.stderr + result.stdout
        return result

    def window():
        for platform, decoration in [("linux", "None"), ("darwin", "Buttonless")]:
            assert render["windows"][platform] == {
                "decorations": decoration,
                "dimensions": {"columns": 0, "lines": 0},
                "padding": {"x": 10, "y": 10},
                "dynamic_padding": True,
                "dynamic_title": True,
                "opacity": 0.98,
            }

    check("Alacritty window merge, Linux and Darwin value renders", window)

    def notification():
        program = Path(render["notify"][0])
        assert program.is_file() and os.access(program, os.X_OK)
        assert run([render["notifyExe"], "--version"]).returncode == 0
        assert run([str(program), '{"type":"other-event"}'], env=env).returncode == 0
        # Render the same module with only the desktop notifier replaced. This
        # exercises the generated executable without a desktop or D-Bus session.
        log = work / "notify-argv"
        notification_env = env | {"NOTIFY_LOG": str(log)}

        def notify(payload):
            result = run(
                [render["testNotify"], json.dumps(payload)], env=notification_env
            )
            assert result.returncode == 0, result.stderr

        turn = {
            "type": "agent-turn-complete",
            "client": "codex-tui",
            "cwd": "/project/space dir",
            "last-assistant-message": (
                "- Fixed **A & B** in [notify](/project/default.nix:1)\n\n"
                "- Kept `Vec<T>`\n"
                "  ```nix\n  x = 1;\n  ```"
            ),
        }
        notify(turn)
        # A bullet-led body must not be parsed as a notify-send option.
        assert log.read_text().splitlines() == [
            "--app-name=Codex",
            "--",
            "space dir",
            "- Fixed A &amp; B in notify",
            "- Kept Vec&lt;T&gt;",
            "x = 1;",
        ]
        log.unlink()
        notify({"type": "other-event"})
        notify(turn | {"client": "codex_exec"})
        assert not log.exists()

    check(
        "Codex real notification helper build and executable resolution", notification
    )

    def aliases():
        expected = {
            "gpfl": "git push --force-with-lease",
            "gpflo": "git push --force-with-lease origin",
            "gpoa": "git push origin --all",
            "gpu": "git push -u",
            "gpuo": "git push -u origin",
            "grba": "git rebase --abort",
            "grbc": "git rebase --continue",
            "grbi": "git rebase -i",
            "grbo": "git rebase --onto",
            "grbs": "git rebase --skip",
        }
        for name, command in expected.items():
            # Exercise the actual rendered alias through Fish and verify argv.
            execute(
                f"function {name}\n {render['gitAliases'][name]} $argv\nend",
                f'{name} "arg with spaces"',
            )
            assert json.loads(Path(env["ARGS_FILE"]).read_text()) == command.split()[
                1:
            ] + ["arg with spaces"], name

    check("ten Git aliases, rendered argv", aliases)

    def ignores():
        exclude = work / "ignore"
        exclude.write_text("\n".join(render["ignores"]) + "\n")
        result = run(
            [
                "git",
                "--git-dir",
                str(repository / ".git"),
                "--work-tree",
                str(work),
                "-c",
                f"core.excludesFile={exclude}",
                "check-ignore",
                "--no-index",
                "__pycache__/uncompiled.txt",
            ],
            cwd=repository,
        )
        assert result.returncode == 0, result.stderr

    check("Python cache directory, real Git check-ignore", ignores)

    def wrapped():
        assert set(render["wrapped"]) == {
            "codex-local",
            "codex-exo",
            "opencode-exo",
            "opencode-ollama",
        }
        args = [
            "model with spaces",
            "prompt with spaces",
            "",
            "single'quote",
            "$HOME; echo BAD",
            "line\nbreak",
        ]
        gateway_expr = expression(gateway=True)
        gateway_result = run(
            [
                "nix",
                "eval",
                "--impure",
                "--json",
                "--expr",
                f'builtins.removeAttrs ({gateway_expr}) ["packages"]',
            ]
        )
        assert gateway_result.returncode == 0, gateway_result.stderr
        gateway_render = json.loads(gateway_result.stdout)
        cases = [
            (variant, name)
            for variant in [render, gateway_render]
            for name in variant["wrapped"]
        ]
        for variant, name in cases:
            body = f"function {name}\n{variant['functions'][name]['body']}\nend\n"
            # Fish accepts this single-quote escaping. The literal arguments are
            # also compared against execution of the existing Bash bridge.
            invocation = name + " " + " ".join(shlex.quote(arg) for arg in args)
            execute(body, invocation)
            actual = json.loads(Path(env["ARGS_FILE"]).read_text())
            assert Path(env["COMMAND_FILE"]).read_text() == name.split("-")[0], name
            expected = run(
                [
                    variant["bashAliases"][name].split()[0],
                    "-c",
                    variant["bashAliases"][name] + ' "$@"',
                    "--",
                    *args,
                ],
                env=env,
            )
            assert expected.returncode == 0, expected.stderr
            assert actual == json.loads(Path(env["ARGS_FILE"]).read_text()), name
            assert actual[-len(args[1:]) :] == args[1:], (name, actual)
            if name.startswith("codex-"):
                assert actual[actual.index("-m") + 1] == args[0], (name, actual)
                provider = "llama-swap" if name == "codex-local" else "exo"
                assert "model_provider=" + json.dumps(provider) in actual, (
                    name,
                    actual,
                )
            else:
                provider = "exo" if name == "opencode-exo" else "ollama"
                assert actual[:2] == ["--model", provider + "/" + args[0]], (
                    name,
                    actual,
                )
            env["COMMAND_STATUS"] = "23"
            execute(body, invocation + "\nset -l result $status\ntest $result -eq 23")
            env["COMMAND_STATUS"] = "0"

    check("four actual Codex/OpenCode wrappers: Fish syntax, argv, status", wrapped)

    cd_body = (SOURCE / "shells/fish/functions/cd.fish").read_text()
    nested = work / "space dir"
    nested.mkdir()
    (nested / "file.txt").write_text("fixture")
    missing = work / "missing-directory"
    check(
        "Fish cd no arguments uses HOME",
        lambda: execute(
            cd_body,
            'cd\nset -l result $status\ntest $result -eq 0; and test "$PWD" = "$HOME"',
            external_git=True,
        ),
    )
    check(
        "Fish cd missing path preserves builtin failure and cwd",
        lambda: execute(
            cd_body,
            f'set -l start "$PWD"\nbuiltin cd "{missing}" 2>/dev/null\nset -l expected $status\ncd "{missing}" 2>/dev/null\nset -l actual $status\ntest $actual -eq $expected; and test "$PWD" = "$start"',
            external_git=True,
        ),
    )
    check(
        "Fish cd directory and file with spaces",
        lambda: execute(
            cd_body,
            f'cd "{nested}"\nset -l result $status\ntest $result -eq 0; and test "$PWD" = "{nested}"; or exit 1\ncd "{nested}/file.txt"\ntest "$PWD" = "{nested}"',
            external_git=True,
        ),
    )
    check(
        "Fish cd repository root and root while already there",
        lambda: execute(
            cd_body,
            f'function onefetch\nreturn 0\nend\nbuiltin cd "{repository}/nested"\ncd :/\ntest "$PWD" = "{repository}"; or exit 1\ncd :/\ntest "$PWD" = "{repository}"',
            external_git=True,
        ),
    )
    check(
        "Fish cd root outside repository fails without moving",
        lambda: execute(
            cd_body,
            'builtin cd "$HOME"\ncd :/ 2>/dev/null\nset -l result $status\ntest $result -ne 0; and test "$PWD" = "$HOME"',
            external_git=True,
        ),
    )

    git_body = (SOURCE / "shells/fish/functions/git.fish").read_text()

    def grep_status():
        native_env = env | {
            "PATH": str(Path(render["git"]).parent)
            + ":"
            + str(Path(render["perl"]).parent)
        }
        (repository / "grep fixture.txt").write_text("needle " + "x" * 700 + "\n")
        for arguments, expected in (
            (["grep", "--no-index", "needle", "--", "grep fixture.txt"], 0),
            (["grep", "--no-index", "absent", "--", "grep fixture.txt"], 1),
            (["grep", "--invalid-regression-option"], 129),
        ):
            native = run([render["git"], *arguments], env=native_env, cwd=repository)
            assert native.returncode == expected, native.stderr
            script = work / "grep.fish"
            script.write_text(
                git_body
                + "\ngit "
                + " ".join(map(shlex.quote, arguments))
                + "\nexit $status\n"
            )
            actual = run(
                [fish, "--no-config", str(script)], env=native_env, cwd=repository
            )
            assert actual.returncode == native.returncode, (
                arguments,
                actual.returncode,
                native.returncode,
            )
            if expected == 0:
                assert "...(truncated)" in actual.stdout
                assert len(actual.stdout) < len(native.stdout)

    check("Fish grep native match/no-match/error status and truncation", grep_status)

    def command_aliases():
        # Git itself expands !aliases. Its nested git commands hit a recorder,
        # never a real fetch/reset/pull. All protocols are also denied.
        calls = work / "git-calls.jsonl"
        recorder = work / "git-recorder"
        recorder.mkdir()
        command = recorder / "git"
        command.write_text(
            "#!" + sys.executable + "\n"
            "import json, os, sys\n"
            "with open(os.environ['GIT_CALLS'], 'a') as log: log.write(json.dumps(sys.argv[1:]) + '\\n')\n"
            "if sys.argv[1:3] == ['remote', 'get-url']: print('https://example.invalid/repository')\n"
        )
        command.chmod(0o755)
        alias_env = env | {
            "PATH": str(recorder),
            "GIT_CALLS": str(calls),
            "GIT_ALLOW_PROTOCOL": "",
            "GIT_EXEC_PATH": str(recorder),
        }

        def invoke(name, arguments, expected, stdin=None):
            calls.unlink(missing_ok=True)
            result = run(
                [
                    render["git"],
                    "-c",
                    f"alias.{name}={render['commandAliases'][name]}",
                    name,
                    *arguments,
                ],
                cwd=repository,
                env=alias_env,
                input=stdin,
            )
            assert result.returncode == 0, (name, result.stderr)
            actual = [json.loads(line) for line in calls.read_text().splitlines()]
            assert actual == expected, (name, actual, expected)

        # Newlines in caller arguments must remain data, not shell commands.
        argument = "topic with spaces\nsecond line"
        invoke("pullhead", ["topic"], [["pull", "origin", "topic"]])
        invoke(
            "mergetest",
            [argument],
            [["merge", "--no-commit", "--no-ff", argument], ["merge", "--abort"]],
        )
        invoke(
            "pullf",
            [argument],
            [["fetch", "origin", argument], ["reset", "--hard", "origin/" + argument]],
            "y\n",
        )
        for remote, number in (("origin", "42"), ("origin", ""), ("upstream", "731")):
            invoke(
                "fetch-pr",
                [remote] + ([number] if number else []),
                [
                    ["remote", "get-url", remote],
                    [
                        "fetch",
                        remote,
                        f"+refs/pull/{number or '*'}/head:refs/remotes/{remote}/pr/{number or '*'}",
                    ],
                ],
            )

    check(
        "Git native multiline !alias argv and inert fetch-pr refspec", command_aliases
    )

    def git_status():
        Path(env["ARGS_FILE"]).unlink(missing_ok=True)
        result = execute(
            git_body, "git commit\nset -l result $status\ntest $result -eq 0"
        )
        assert "Commit subject length:" in result.stdout, result.stderr
        assert json.loads(Path(env["ARGS_FILE"]).read_text()) == [
            "log",
            "-1",
            "--format=%s",
        ]
        env["COMMAND_STATUS"] = "23"
        result = execute(
            git_body, "git commit\nset -l result $status\ntest $result -eq 23"
        )
        assert "Commit subject length:" not in result.stdout
        assert json.loads(Path(env["ARGS_FILE"]).read_text()) == ["commit"]
        env["COMMAND_STATUS"] = "0"
        assert not Path(env["CODE_MARKER"]).exists(), (
            "git invoked the editor executable"
        )

    check("Fish git saved exit status, without invoking code", git_status)

print(f"{13 - len(failures)}/13 groups passed; failures: {failures}")
raise SystemExit(bool(failures))
