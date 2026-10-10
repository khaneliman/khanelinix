"""Offline rendered weather checks; no native GUI or weather requests.

Run with --nixpkgs LOCAL_LOCKED_NIXPKGS --lua LUA54. Source defaults to the
repository containing tests/. Use --tree for just the three corrected module
copies, --root for a complete alternate repository, and --simple-home to expose
the baseline JSON-quote failure without unusual home-path quoting failing first.
Fixtures are removed even on failure. --scratch must be outside tests/ and either
outside the repository or ignored by Git; it defaults to the user's cache.
Requires Python 3, Nix, jq, gawk, Bash, /bin/sh, and Lua 5.4 already installed.
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


def nix_string(value):
    return json.dumps(value, ensure_ascii=False).replace("${", r"\${")


def run_checks(root, tree, nixpkgs, lua, work, simple_home):
    # The fixture path exercises Nix-to-shell quoting as well as value quoting.
    home = work / "home space ' quote $dollar"
    if simple_home:
        home = work / "plain-home"
    home.mkdir(exist_ok=True)
    bin_dir = work / "bin"
    bin_dir.mkdir(exist_ok=True)
    log = work / "argv.json"
    for name, alt in [("wttrbar", False), ("ashell-wttrbar", True)]:
        executable = bin_dir / name
        executable.write_text(
            "#!"
            + sys.executable
            + "\n"
            + "import json,os,sys\nfrom pathlib import Path\n"
            + 'Path(os.environ["ARGV_LOG"]).write_text(json.dumps(sys.argv[1:]))\n'
            + 'print(json.dumps({"text":"sun 72",'
            + ('"alt"' if alt else '"tooltip"')
            + ':"<b>Today</b>\\n10am sun 72 Clear, humidity"}))\n'
        )
        executable.chmod(0o755)
    (bin_dir / "jq").unlink(missing_ok=True)
    (bin_dir / "jq").symlink_to(shutil.which("jq"))
    jq = Path(shutil.which("jq")).resolve()
    gawk = shutil.which("gawk")
    assert gawk
    # Use the current root library; only package construction is replaced by bodies
    # and harmless executable fixtures. No flake/host evaluation or build is needed.
    expression = """let
      realLib = import (builtins.toPath NIXPKGS + "/lib");
      lib = realLib // { getExe = p: if p ? body then p.body else realLib.getExe p; };
      package = exe: { type = "derivation"; outPath = builtins.dirOf (builtins.dirOf exe); meta.mainProgram = builtins.baseNameOf exe; };
      pkgs = {
        jq = package JQ;
        gawk = package GAWK;
        wttrbar = (package WTTR) // { overrideAttrs = attrs: package ALT; };
        writeShellScriptBin = name: body: { inherit body; };
      };
      config = {
        home.homeDirectory = HOME;
        khanelinix.services.sops.enable = ENABLE;
      };
      helpers.weatherDetailPopup = package WTTR;
      waybar = import WAYBAR { inherit config lib pkgs; };
      ashell = import ASHELL { inherit config lib pkgs helpers; };
    in { waybar = waybar."custom/weather".exec;
         ashell = ashell.CustomWeather.listen_cmd;
         popup = ashell.CustomWeather.command; }
    """
    for key, value in {
        "NIXPKGS": str(nixpkgs),
        "JQ": str(jq),
        "GAWK": str(Path(gawk).resolve()),
        "WTTR": str(bin_dir / "wttrbar"),
        "ALT": str(bin_dir / "ashell-wttrbar"),
        "HOME": str(home),
    }.items():
        expression = expression.replace(key, nix_string(value))
    for key, path in {
        "WAYBAR": "modules/home/programs/graphical/bars/waybar/modules/custom-modules.nix",
        "ASHELL": "modules/home/programs/graphical/bars/ashell/custom-modules.nix",
    }.items():
        expression = expression.replace(
            key, "(builtins.toPath " + nix_string(str(tree / path)) + ")"
        )
    commands = {}
    for enabled in [True, False]:
        rendered = json.loads(
            subprocess.check_output(
                [
                    "nix",
                    "eval",
                    "--offline",
                    "--impure",
                    "--json",
                    "--expr",
                    expression.replace("ENABLE", "true" if enabled else "false"),
                ],
                text=True,
            )
        )
        for owner in ["waybar", "ashell"]:
            commands[(owner, enabled)] = rendered[owner]
        assert rendered["popup"] == str(bin_dir / "wttrbar")
    commands[("sketchybar", True)] = subprocess.check_output(
        [
            lua,
            str(Path(__file__).with_name("weather-command.lua")),
            str(root),
            str(
                tree
                / "modules/home/programs/graphical/bars/sketchybar/config/items/today/weather.lua"
            ),
        ],
        text=True,
    )
    env = os.environ | {
        "HOME": str(home),
        "PATH": str(bin_dir) + ":" + os.environ["PATH"],
        "ARGV_LOG": str(log),
    }
    valid = [
        "Paris",
        "New York",
        '''O'Fallon "city"''',
        "a; $(touch SHOULD_NOT_EXIST) `false` $HOME * \\",
        "-leading",
        "Montréal",
        " trailing ",
    ]
    invalid = [
        None,
        "",
        12,
        False,
        [],
        {},
        "a\nb",
        "a\n",
        "\na",
        "a\rb",
        "a\tb",
        "a\0b",
        "a\x1bb",
        "a\x7fb",
    ]
    config = home / "weather_config.json"
    checks = 0
    for (owner, enabled), command in commands.items():

        def run(raw, owner=owner, command=command):
            config.unlink(missing_ok=True)
            if raw is not None:
                config.write_text(raw)
            log.unlink(missing_ok=True)
            return subprocess.run(
                ["bash" if owner != "sketchybar" else "/bin/sh", "-c", command],
                env=env,
                cwd=work,
                capture_output=True,
                text=True,
                timeout=5,
                check=False,
            )

        if not enabled:
            result = run(None)
            assert result.returncode == 0, result.stderr
            assert json.loads(log.read_text()) == ["--fahrenheit", "--ampm"]
            checks += 1
            continue
        for location in valid:
            result = run(json.dumps({"wttr": {"location": location}}))
            assert result.returncode == 0, (owner, location, result.stderr)
            assert json.loads(log.read_text()) == [
                "--fahrenheit",
                "--ampm",
                "--location=" + location,
            ], (owner, location, json.loads(log.read_text()))
            payload = json.loads(result.stdout)
            assert payload["text"] == "sun 72"
            if owner == "ashell":
                assert "alt" in payload and "tooltip" not in payload
            elif owner == "waybar":
                assert payload["tooltip"] == "Today\n  10am sun 72 Clear"
            checks += 1
        malformed = [
            None,
            "",
            "{",
            "{}",
            '{"wttr":{}}',
            '{"wttr":null}',
            "null",
            "[]",
            '{"wttr":{"location":"Paris"}} {"wttr":{"location":"York"}}',
        ]
        malformed += [
            json.dumps({"wttr": {"location": location}}) for location in invalid
        ]
        for raw in malformed:
            result = run(raw)
            assert result.returncode != 0, (owner, raw, result)
            assert result.stderr, (owner, raw)
            assert not log.exists(), (owner, raw)
            checks += 1
    assert checks == 92, checks
    assert not (work / "SHOULD_NOT_EXIST").exists()
    print(
        f"PASS: {checks} rendered executions; 3 owners, Linux SOPS-disabled fallback, SketchyBar popup callbacks"
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    repository = Path(__file__).resolve().parents[1]
    parser.add_argument("--root", type=Path, default=repository)
    parser.add_argument("--tree", type=Path)
    parser.add_argument(
        "--nixpkgs",
        type=Path,
        required=True,
        help="already-local Nixpkgs source for this repository's current root lock",
    )
    parser.add_argument("--lua", required=True, help="path or command for Lua 5.4")
    parser.add_argument("--simple-home", action="store_true")
    parser.add_argument(
        "--scratch",
        type=Path,
        default=Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache")
        / "khanelinix/weather-tests",
    )
    args = parser.parse_args()
    root = args.root.resolve()
    tree = (args.tree or root).resolve()
    nixpkgs = args.nixpkgs.resolve()
    if not (nixpkgs / "lib/default.nix").is_file():
        parser.error("--nixpkgs must name an already-local Nixpkgs source directory")
    for tool in ("nix", "jq", "gawk", "bash"):
        if not shutil.which(tool):
            parser.error(f"required executable not found: {tool}")
    lua = shutil.which(args.lua)
    if not lua:
        parser.error("--lua executable not found")
    version = subprocess.check_output([lua, "-e", "io.write(_VERSION)"], text=True)
    if version != "Lua 5.4":
        parser.error(f"--lua must be Lua 5.4, got {version}")
    scratch = args.scratch.resolve()
    for source_root in {repository, root, tree}:
        if scratch.is_relative_to(source_root / "tests"):
            parser.error("--scratch must not be inside tests/")
        if scratch.is_relative_to(source_root):
            ignored = subprocess.run(
                ["git", "-C", str(source_root), "check-ignore", "-q", str(scratch)],
                capture_output=True,
                check=False,
            )
            if ignored.returncode:
                parser.error("--scratch inside a source tree must be ignored by Git")
    scratch.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="weather-", dir=scratch) as directory:
        run_checks(root, tree, nixpkgs, lua, Path(directory), args.simple_home)


if __name__ == "__main__":
    main()
