"""Offline workflow checks. Run with --root TREE --scratch IGNORED_DIR --lua LUA54."""

import argparse
import contextlib
import importlib.util
import io
import os
import shutil
import subprocess
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
parser.add_argument("--scratch", type=Path, required=True)
parser.add_argument("--lua", required=True)
args = parser.parse_args()
root = args.root.resolve()
scratch = args.scratch.resolve()
scratch.mkdir(parents=True, exist_ok=True)
rofi = root / "modules/home/programs/graphical/launchers/rofi/config/spotlight"
bar = root / "modules/home/programs/graphical/bars/sketchybar"


class Workflows(unittest.TestCase):
    def test_lua_callbacks(self):
        subprocess.run(
            [args.lua, str(root / "tests/graphical-workflows.lua"), str(root)],
            check=True,
        )

    def test_web_main(self):
        spec = importlib.util.spec_from_file_location(
            "web_search", rofi / "web-search.py"
        )
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        for query, expected in [("! hello!", "hello!"), ("!!bang!", "!bang!")]:
            output = io.StringIO()
            with (
                patch.object(sys, "argv", ["web-search.py", query]),
                patch.object(
                    module, "fetch_suggestions", return_value=["a &amp; b"]
                ) as fetch,
                contextlib.redirect_stdout(output),
            ):
                module.main()
            fetch.assert_called_once_with(expected)
            self.assertIn(
                ":wb a & b\0icon\x1f" + str(rofi / "icons/google.svg"),
                output.getvalue(),
            )
        with (
            patch.object(sys, "argv", ["web-search.py", "hello!"]),
            patch.object(module.sp, "Popen") as browser,
        ):
            module.main()
        self.assertEqual(
            browser.call_args.args[0][-1], "https://www.google.com/search?q=hello%21"
        )
        self.assertFalse(browser.call_args.kwargs["shell"])

    def test_rofi_shell(self):
        case = scratch / "rofi fixture with spaces"
        if case.exists():
            shutil.rmtree(case)
        script_dir = case / "store config"
        script_dir.mkdir(parents=True)
        script = script_dir / "rofi-spotlight.sh"
        # Only relocate transient files to scratch; execute the actual shell logic.
        script.write_text(
            (rofi / script.name)
            .read_text()
            .replace('TMP_DIR="/tmp/rofi/${USER}/"', 'TMP_DIR="${TEST_RUNTIME}/"')
        )
        work = case / "cwd"
        work.mkdir()
        (work / "file with spaces.txt").write_text("text\n")
        (work / "quote's.txt").write_text("text\n")
        (work / "Folder with spaces").mkdir()
        (script_dir / "history.txt").write_text("old query\n")
        home = case / "home"
        home.mkdir()
        (home / "fixture.txt").write_text("home fixture")
        # Select the native find branch deterministically without depending on installed fd.
        bin_dir = case / "bin"
        bin_dir.mkdir()
        for command in [
            "bash",
            "realpath",
            "dirname",
            "mkdir",
            "cp",
            "touch",
            "sort",
            "readlink",
            "file",
            "tac",
            "find",
            "sed",
            "awk",
            "getconf",
            "xargs",
        ]:
            path = shutil.which(command)
            if path:
                (bin_dir / command).symlink_to(path)
        (bin_dir / "notify-send").write_text("#!/usr/bin/env bash\nexit 0\n")
        (bin_dir / "notify-send").chmod(0o755)
        env = os.environ | {
            "HOME": str(home),
            "XDG_STATE_HOME": str(case / "state"),
            "PATH": str(bin_dir),
            "TEST_RUNTIME": str(case / "runtime"),
        }

        def run(*arguments):
            result = subprocess.run(
                ["bash", str(script), *arguments],
                env=env,
                cwd=work,
                capture_output=True,
                timeout=10,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stderr, b"")
            return result.stdout

        listing = run()
        self.assertIn(b"file with spaces.txt\0icon\x1fapplication-text", listing)
        self.assertIn(b"quote's.txt\0icon\x1fapplication-text", listing)
        self.assertIn(b"Folder with spaces/\0icon\x1ffolder-blue", listing)
        history = case / "state/rofi/history.txt"
        self.assertEqual(history.read_text(), "old query\n")
        self.assertIn(
            b"old query\0icon\x1f" + str(script_dir / "icons/history.svg").encode(),
            run(":sh"),
        )
        run("?missing")
        self.assertEqual(history.read_text(), "old query\n?missing\n")
        self.assertEqual((script_dir / "history.txt").read_text(), "old query\n")
        run(":ch")
        self.assertEqual(history.read_text(), "")
        env["XDG_STATE_HOME"] = ""
        run(":sh")
        self.assertEqual(
            (home / ".local/state/rofi/history.txt").read_text(), "old query\n"
        )

    def test_skhd_rendered_commands(self):
        executable = scratch / "record-command"
        log = scratch / "skhd-argv.txt"
        executable.write_text(
            '#!/usr/bin/env bash\nprintf "%s\\n" "$@" >> "$TEST_ARGV_LOG"\n'
        )
        executable.chmod(0o755)
        quoted = str(executable)
        module_path = root / "modules/home/services/skhd/default.nix"
        expression = f"""let
          module = import {module_path};
          lib = rec {{
            mkIf = condition: value: value;
            getExe = package: package;
            mkEnableOption = description: {{}};
            types.str = {{}};
            khanelinix.mkOpt = type: default: description: {{}};
            attrByPath = path: default: value: default;
            optionalString = condition: value: if condition then value else "";
            mkForce = value: value;
            hm.dag.entryAfter = dependencies: value: value;
          }};
          config = {{
            khanelinix.services.skhd.enable = true;
            khanelinix.suites.business.enable = false;
            home.homeDirectory = "/fixture";
          }};
          pkgs = {{ sketchybar = "{quoted}"; yabai = "{quoted}";
            kitty = "{quoted}"; stdenv.hostPlatform.isDarwin = false; }};
        in (module {{ inherit lib config pkgs; }}).config.services.skhd.config"""
        rendered = subprocess.check_output(
            ["nix", "eval", "--impure", "--raw", "--expr", expression], text=True
        )
        env = os.environ | {"TEST_ARGV_LOG": str(log)}
        launch = scratch / "launchctl"
        launch.symlink_to(executable) if not launch.exists() else None
        env["PATH"] = str(scratch) + ":" + env["PATH"]
        uid = subprocess.check_output(["id", "-u"], text=True).strip()
        for key, expected in [
            (
                "ctrl + lalt + cmd - r",
                ["kickstart", "-k", f"gui/{uid}/org.nixos.yabai"],
            ),
            (
                "shift + lalt + cmd - r",
                ["kickstart", "-k", f"gui/{uid}/org.nix-community.home.skhd"],
            ),
            (
                "shift + lalt - p",
                [
                    "-m",
                    "window",
                    "--space",
                    "prev",
                    "-m",
                    "space",
                    "--focus",
                    "prev",
                    "--trigger",
                    "windows_on_spaces",
                ],
            ),
        ]:
            command = next(
                line.split(" : ", 1)[1]
                for line in rendered.splitlines()
                if line.strip().startswith("default < " + key + " :")
            )
            log.write_text("")
            subprocess.run(["bash", "-c", command], env=env, check=True)
            self.assertEqual(log.read_text().splitlines(), expected)

    def test_cpu_callback(self):
        bin_dir = scratch / "cpu-bin"
        bin_dir.mkdir(exist_ok=True)
        ps = bin_dir / "ps"
        ps.write_text(
            "#!/usr/bin/env bash\nprintf '%s\\n' ' %CPU COMM' ' 100 /bin/sketchybar' ' 99.5 /Applications/Busy App' ' 10 /bin/idle'\n"
        )
        ps.chmod(0o755)
        subprocess.run(
            [args.lua, str(root / "tests/graphical-workflows-cpu.lua"), str(root)],
            env=os.environ | {"PATH": str(bin_dir) + ":" + os.environ["PATH"]},
            check=True,
        )


if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0]])
