"""Run rendered selective-stash aliases only in disposable fixture repositories.

Usage: python3 regression.py SOURCE_ROOT SCRATCH_DIRECTORY
"""

import itertools
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SOURCE = Path(sys.argv.pop(1)).resolve()
SCRATCH = Path(sys.argv.pop(1)).resolve()
SCRATCH.mkdir(parents=True, exist_ok=True)
ENV = {
    key: value for key, value in os.environ.items() if not key.startswith("GIT_")
} | {
    "GIT_CONFIG_NOSYSTEM": "1",
    "GIT_CONFIG_GLOBAL": "/dev/null",
    "GIT_AUTHOR_NAME": "Fixture",
    "GIT_AUTHOR_EMAIL": "fixture@example.invalid",
    "GIT_COMMITTER_NAME": "Fixture",
    "GIT_COMMITTER_EMAIL": "fixture@example.invalid",
}
ALIASES = json.loads(
    subprocess.check_output(
        [
            "nix",
            "eval",
            "--json",
            "--file",
            str(SOURCE / "modules/home/programs/terminal/tools/git/aliases.nix"),
        ]
    )
)["aliases"]


class StashTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=SCRATCH)
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)
        self.git("init", "-q")
        for name in (
            "staged space.txt",
            "unstaged\nname.txt",
            "binary.bin",
            "unstaged.bin",
        ):
            (self.repo / name).write_bytes(b"base\nline\n")
        self.git("add", ".")
        self.git("commit", "-qm", "base")
        for name in ("stash-staged", "stash-unstaged"):
            self.git("config", "alias." + name, ALIASES[name])

    def git(self, *args, ok=True, cwd=None, input=None):
        result = subprocess.run(
            ["git", *args],
            cwd=cwd or self.repo,
            env=ENV,
            input=input,
            capture_output=True,
            check=False,
        )
        if ok:
            self.assertEqual(result.returncode, 0, result.stderr.decode())
        return result

    def state(self):
        return (
            self.git("diff", "--binary", "--cached").stdout,
            self.git("diff", "--binary").stdout,
            {
                p.relative_to(self.repo): p.read_bytes()
                for p in self.repo.rglob("*")
                if p.is_file() and ".git" not in p.parts
            },
        )

    def dirty(self):
        (self.repo / "staged space.txt").write_bytes(b"one  two  \n\tthree * four\n\n")
        (self.repo / "binary.bin").write_bytes(b"\x00staged\xff\x00")
        self.git("add", "-u")
        (self.repo / "unstaged\nname.txt").write_bytes(b"five  six  \n\tseven\n\n")
        (self.repo / "unstaged.bin").write_bytes(b"\x00unstaged\xff")
        (self.repo / "untracked space").write_bytes(b"\x00untracked\xff")

    def test_roundtrip(self):
        for mode, setting in itertools.product(
            ("staged", "unstaged"),
            (
                None,
                ("apply.whitespace", "fix"),
                ("diff.noprefix", "true"),
                ("diff.context", "0"),
            ),
        ):
            with self.subTest(mode=mode, setting=setting):
                if setting:
                    self.git("config", *setting)
                self.dirty()
                before = self.state()
                self.git("stash-" + mode, "-m", "message  with\nlines", input=b"yes\n")
                self.assertIn(b"message with lines", self.git("stash", "list").stdout)
                self.assertEqual(
                    (self.repo / "untracked space").read_bytes(), b"\x00untracked\xff"
                )
                selected = (
                    ("staged space.txt", "binary.bin")
                    if mode == "staged"
                    else ("unstaged\nname.txt", "unstaged.bin")
                )
                for name in (
                    "staged space.txt",
                    "binary.bin",
                    "unstaged\nname.txt",
                    "unstaged.bin",
                ):
                    self.assertEqual(
                        self.git("show", "stash:" + name).stdout,
                        before[2][Path(name)] if name in selected else b"base\nline\n",
                    )
                if mode == "staged":
                    self.assertEqual(self.git("diff", "--cached").stdout, b"")
                    self.assertEqual(
                        (self.repo / "binary.bin").read_bytes(), b"base\nline\n"
                    )
                    # Native stash --index also replays a patch; isolate the helper
                    # from native restoration's ambient whitespace rewriting.
                    self.git(
                        "-c", "apply.whitespace=nowarn", "stash", "apply", "--index"
                    )
                else:
                    self.assertEqual(self.git("diff").stdout, b"")
                    self.git("-c", "apply.whitespace=nowarn", "stash", "apply")
                self.assertEqual(self.state(), before)
                self.git("reset", "--hard", "-q")
                self.git("stash", "clear")
                if setting:
                    self.git("config", "--unset", setting[0])

    def test_refusal(self):
        self.dirty()
        before = self.state()
        for answer in (b"n\n", b""):
            self.assertNotEqual(
                self.git("stash-staged", input=answer, ok=False).returncode, 0
            )
            self.assertEqual(self.state(), before)
            self.assertEqual(list((self.repo / ".git").glob("stash-selected.*")), [])

    def test_failure_recovery(self):
        for mode, setting in itertools.product(
            ("staged", "unstaged"),
            (
                None,
                ("apply.whitespace", "fix"),
                ("diff.noprefix", "true"),
                ("diff.context", "0"),
            ),
        ):
            with self.subTest(mode=mode, setting=setting):
                if setting:
                    self.git("config", *setting)
                self.dirty()
                before = self.state()
                result = self.git(
                    "stash-" + mode, "--not-an-option", input=b"y\n", ok=False
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(
                    b"git -c apply.ignoreWhitespace=no apply -p1 --whitespace=nowarn --index",
                    result.stderr,
                )
                self.assertIn(
                    b"then unstaged.diff with git -c apply.ignoreWhitespace=no apply -p1 --whitespace=nowarn.",
                    result.stderr,
                )
                (recovery,) = (self.repo / ".git").glob("stash-selected.*")
                self.assertEqual(recovery.stat().st_mode & 0o777, 0o700)
                self.git("reset", "--hard", "-q")
                self.git(
                    "-c",
                    "apply.ignoreWhitespace=no",
                    "apply",
                    "-p1",
                    "--whitespace=nowarn",
                    "--index",
                    str(recovery / "staged.diff"),
                )
                self.git(
                    "-c",
                    "apply.ignoreWhitespace=no",
                    "apply",
                    "-p1",
                    "--whitespace=nowarn",
                    str(recovery / "unstaged.diff"),
                )
                self.assertEqual(self.state(), before)
                import shutil

                shutil.rmtree(recovery)
                self.git("reset", "--hard", "-q")
                if setting:
                    self.git("config", "--unset", setting[0])

    def test_empty_selection(self):
        for mode, other in (("staged", "unstaged"), ("unstaged", "staged")):
            (self.repo / "staged space.txt").write_bytes(b"other\n")
            if other == "staged":
                self.git("add", ".")
            before = self.state()
            self.git("stash-" + mode)
            self.assertEqual(self.state(), before)
            self.assertEqual(self.git("stash", "list").stdout, b"")
            self.git("reset", "--hard", "-q")

    def test_untracked_and_subdirectory(self):
        self.dirty()
        before = self.state()
        child = self.repo / "child dir"
        child.mkdir()
        self.git("stash-staged", "-u", input=b"y\n", cwd=child)
        self.assertFalse((self.repo / "untracked space").exists())
        self.git("stash", "apply", "--index")
        self.assertEqual(self.state(), before)

    def test_untracked_only(self):
        path = self.repo / "untracked space"
        path.write_bytes(b"untracked")
        self.git("stash-unstaged", "-u")
        self.assertFalse(path.exists())
        self.git("stash", "apply")
        self.assertEqual(path.read_bytes(), b"untracked")

    def test_color_configuration(self):
        self.git("config", "color.ui", "always")
        self.dirty()
        before = self.state()
        self.git("stash-staged", input=b"y\n")
        self.git("stash", "apply", "--index")
        self.assertEqual(self.state(), before)

    def test_added_and_deleted_files(self):
        for mode in ("staged", "unstaged"):
            with self.subTest(mode=mode):
                self.dirty()
                (self.repo / "added space").write_bytes(b"new\x00file")
                (self.repo / "binary.bin").unlink()
                self.git("add", "added space", "binary.bin")
                before = self.state()
                self.git("stash-" + mode, input=b"y\n")
                self.git("stash", "apply", *(["--index"] if mode == "staged" else []))
                self.assertEqual(self.state(), before)
                self.git("reset", "--hard", "-q")
                self.git("stash", "clear")

    def test_overlap_recovery(self):
        path = self.repo / "staged space.txt"
        path.write_bytes(b"staged\nline\n")
        self.git("add", ".")
        path.write_bytes(b"overlap\nline\n")
        before = self.state()
        self.assertNotEqual(
            self.git("stash-staged", input=b"y\n", ok=False).returncode, 0
        )
        (recovery,) = (self.repo / ".git").glob("stash-selected.*")
        self.git("reset", "--hard", "-q")
        self.git("apply", "--index", str(recovery / "staged.diff"))
        self.git("apply", str(recovery / "unstaged.diff"))
        self.assertEqual(self.state(), before)


class FishTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=SCRATCH)
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.cwd = self.root / "cwd"
        self.out = self.root / "elsewhere space"
        self.cwd.mkdir()
        self.out.mkdir()

    def fish(self, function, argument=None, *, env_extra=None):
        import shlex

        executable = os.environ["FISH"]
        source = (
            SOURCE
            / "modules/home/programs/terminal/shells/fish/functions"
            / (function + ".fish")
        )
        command = "source " + shlex.quote(str(source)) + "; " + function
        if argument is not None:
            command += " " + shlex.quote(str(argument))
        environment = os.environ | (env_extra or {})
        if environment.get("SEVENZIP"):
            environment["PATH"] = (
                str(Path(environment["SEVENZIP"]).parent)
                + os.pathsep
                + environment["PATH"]
            )
        return subprocess.run(
            [executable, "--no-config", "-c", command],
            cwd=self.cwd,
            env=environment,
            capture_output=True,
            check=False,
        )

    def test_bak_outside_cwd(self):
        target = self.out / "file space"
        backup = self.out / "file space.bak"
        decoy = self.cwd / "file space.bak"
        target.write_bytes(b"original")
        decoy.write_bytes(b"decoy")
        self.assertEqual(self.fish("bak", target).returncode, 0)
        self.assertFalse(target.exists())
        self.assertEqual(backup.read_bytes(), b"original")
        self.assertEqual(self.fish("bak", target).returncode, 0)
        self.assertEqual(target.read_bytes(), b"original")
        backup.write_bytes(b"backup")
        self.assertEqual(self.fish("bak", target).returncode, 0)
        self.assertEqual(target.read_bytes(), b"backup")
        self.assertEqual(backup.read_bytes(), b"original")
        self.assertEqual(decoy.read_bytes(), b"decoy")
        self.assertNotEqual(self.fish("bak").returncode, 0)

    def bak_entry(self, path):
        if path.is_symlink():
            referent = self.bak_entry(path.resolve()) if path.exists() else None
            return ("link", os.readlink(path), referent)
        if path.is_dir():
            return (
                "directory",
                tuple((p.name, self.bak_entry(p)) for p in sorted(path.iterdir())),
            )
        return ("file", path.read_bytes())

    def bak_fixture(self, path, kind, payload):
        if kind == "file":
            path.write_bytes(payload)
        elif kind == "directory":
            path.mkdir()
            (path / "payload").write_bytes(payload)
        else:
            referent = self.root / (kind + "-" + payload.decode())
            if kind == "link-file":
                referent.write_bytes(payload)
            elif kind == "link-directory":
                referent.mkdir(exist_ok=True)
                (referent / "payload").write_bytes(payload)
            path.symlink_to(referent)

    def test_bak_collision_and_path_types(self):
        kinds = ("file", "directory", "link-file", "link-directory", "dangling")
        for number, (target_kind, backup_kind) in enumerate(
            itertools.product(kinds, repeat=2)
        ):
            with self.subTest(target=target_kind, backup=backup_kind):
                parent = self.out / str(number)
                parent.mkdir()
                target = parent / "-file space"
                backup = parent / "-file space.bak"
                collision = parent / "-file space.bak.tmp"
                self.bak_fixture(target, target_kind, b"original")
                self.bak_fixture(collision, backup_kind, b"collision")
                original = self.bak_entry(target)
                untouched = self.bak_entry(collision)
                # Exercise a relative path outside cwd as well as absolute paths.
                argument = os.path.relpath(target, self.cwd) if number % 2 else target
                for _ in range(2):
                    result = self.fish("bak", argument)
                    self.assertEqual(result.returncode, 0, result.stderr.decode())
                self.assertEqual(self.bak_entry(target), original)
                self.assertFalse(backup.exists() or backup.is_symlink())
                self.bak_fixture(backup, backup_kind, b"backup")
                other = self.bak_entry(backup)
                result = self.fish("bak", argument)
                self.assertEqual(result.returncode, 0, result.stderr.decode())
                self.assertEqual(self.bak_entry(target), other)
                self.assertEqual(self.bak_entry(backup), original)
                self.assertEqual(self.bak_entry(collision), untouched)
                self.assertEqual(list(parent.glob(".bak.*")), [])

    def test_bak_move_failures(self):
        import shutil

        native_mv = shutil.which("mv")
        bindir = self.root / "bin"
        bindir.mkdir()
        # Fail before selected moves, delegate all others to the real platform mv.
        (bindir / "mv").write_text(
            "#!" + sys.executable + "\n"
            "import json,os,subprocess,sys\n"
            "from pathlib import Path\n"
            "log=Path(os.environ['MOVE_LOG'])\n"
            "calls=json.loads(log.read_text()) if log.exists() else []\n"
            "calls.append(sys.argv[1:]); log.write_text(json.dumps(calls))\n"
            "if len(calls) in json.loads(os.environ['FAIL_MOVES']): sys.exit(71)\n"
            "sys.exit(subprocess.run([os.environ['NATIVE_MV'],*sys.argv[1:]],check=False).returncode)\n"
        )
        (bindir / "mv").chmod(0o755)
        failures = ((1,), (2,), (3,), (2, 3), (3, 4), (3, 5))
        kinds = ("file", "directory", "link-file", "link-directory", "dangling")
        for number, (kind, fail_moves) in enumerate(itertools.product(kinds, failures)):
            with self.subTest(kind=kind, fail_moves=fail_moves):
                parent = self.out / str(number)
                parent.mkdir()
                target = parent / "file space"
                backup = parent / "file space.bak"
                self.bak_fixture(target, kind, b"original")
                self.bak_fixture(backup, kind, b"backup")
                original, other = self.bak_entry(target), self.bak_entry(backup)
                log = parent / "moves.json"
                result = self.fish(
                    "bak",
                    target,
                    env_extra={
                        "PATH": str(bindir) + os.pathsep + os.environ["PATH"],
                        "NATIVE_MV": native_mv,
                        "MOVE_LOG": str(log),
                        "FAIL_MOVES": json.dumps(fail_moves),
                    },
                )
                self.assertNotEqual(result.returncode, 0)
                recovery = list(parent.glob(".bak.*"))
                calls = json.loads(log.read_text())
                expected_calls = (
                    {1: 1, 2: 3, 3: 5}[fail_moves[0]]
                    if len(fail_moves) == 1
                    else fail_moves[-1]
                )
                self.assertEqual(len(calls), expected_calls)
                if len(fail_moves) == 1:
                    self.assertEqual(self.bak_entry(target), original)
                    self.assertEqual(self.bak_entry(backup), other)
                    self.assertEqual(recovery, [])
                else:
                    (retained,) = recovery
                    self.assertEqual(retained.stat().st_mode & 0o777, 0o700)
                    self.assertIn(str(retained).encode(), result.stderr)
                    self.assertEqual(self.bak_entry(retained / "original"), original)
                    location = target if fail_moves == (3, 4) else backup
                    vacant = backup if location == target else target
                    self.assertEqual(self.bak_entry(location), other)
                    self.assertFalse(vacant.exists() or vacant.is_symlink())

    def test_bak_suffix_and_directory_slashes(self):
        target = self.out / "file.bak"
        target.write_bytes(b"suffix original")
        result = self.fish("bak", target)
        # The historical suffix mapping chooses the same path, not file or .bak.bak.
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(target.read_bytes(), b"suffix original")
        self.assertEqual(list(self.out.iterdir()), [target])
        hidden = self.out / ".bak"
        hidden.write_bytes(b"hidden")
        self.assertEqual(self.fish("bak", hidden).returncode, 0)
        self.assertEqual((self.out / ".bak.bak").read_bytes(), b"hidden")
        directory = self.out / "folder space"
        directory.mkdir()
        (directory / "payload").write_bytes(b"directory")
        argument = str(directory) + "///"
        for _ in range(2):
            result = self.fish("bak", argument)
            self.assertEqual(result.returncode, 0, result.stderr.decode())
        backup = self.out / "folder space.bak"
        backup.mkdir()
        (backup / "payload").write_bytes(b"backup directory")
        result = self.fish("bak", argument)
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual((directory / "payload").read_bytes(), b"backup directory")
        self.assertEqual((backup / "payload").read_bytes(), b"directory")

    def test_bak_temp_creation_failure(self):
        bindir = self.root / "bin"
        bindir.mkdir()
        (bindir / "mktemp").write_text(
            "#!" + sys.executable + "\nimport sys\nsys.exit(71)\n"
        )
        (bindir / "mktemp").chmod(0o755)
        target, backup = self.out / "file", self.out / "file.bak"
        target.write_bytes(b"original")
        backup.write_bytes(b"backup")
        result = self.fish(
            "bak",
            target,
            env_extra={
                "PATH": str(bindir) + os.pathsep + os.environ["PATH"],
            },
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(target.read_bytes(), b"original")
        self.assertEqual(backup.read_bytes(), b"backup")
        self.assertEqual(list(self.out.glob(".bak.*")), [])

    def test_bak_dash_and_newline_names(self):
        for name in ("-file space", "file\nspace\n"):
            with self.subTest(name=name):
                target = self.cwd / name
                backup = self.cwd / (name + ".bak")
                target.write_bytes(b"original")
                for _ in range(2):
                    self.assertEqual(self.fish("bak", name).returncode, 0)
                backup.write_bytes(b"backup")
                self.assertEqual(self.fish("bak", name).returncode, 0)
                self.assertEqual(target.read_bytes(), b"backup")
                self.assertEqual(backup.read_bytes(), b"original")

    def test_bak_relative_symlinks(self):
        target, backup = self.out / "file", self.out / "file.bak"
        (self.out / "original").write_bytes(b"original")
        (self.out / "backup").write_bytes(b"backup")
        target.symlink_to("original")
        backup.symlink_to("backup")
        self.assertEqual(self.fish("bak", target).returncode, 0)
        self.assertEqual(os.readlink(target), "backup")
        self.assertEqual(os.readlink(backup), "original")
        self.assertEqual(target.read_bytes(), b"backup")
        self.assertEqual(backup.read_bytes(), b"original")
        self.assertEqual((self.out / "original").read_bytes(), b"original")
        self.assertEqual((self.out / "backup").read_bytes(), b"backup")

    def test_ex_outside_cwd(self):
        import bz2
        import gzip
        import zipfile

        payload = b"content  with\nwhitespace\n\x00binary"
        for extension, compress in (("gz", gzip.compress), ("bz2", bz2.compress)):
            archive = self.out / ("payload space." + extension)
            archive.write_bytes(compress(payload))
            result = self.fish("ex", archive)
            self.assertEqual(result.returncode, 0, result.stderr.decode())
            self.assertEqual(
                (self.cwd / "payload space" / "payload space").read_bytes(), payload
            )
            self.assertTrue(archive.exists())
            self.assertFalse((self.out / "payload space").exists())
        archive = self.out / "archive space.zip"
        with zipfile.ZipFile(archive, "w") as stream:
            stream.writestr("file space", payload)
        (self.cwd / "archive space.zip").write_bytes(b"not a zip")
        result = self.fish("ex", archive)
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(
            (self.cwd / "archive space" / "file space").read_bytes(), payload
        )
        self.assertNotEqual(self.fish("ex", self.out / "missing").returncode, 0)
        self.assertNotEqual(self.fish("ex").returncode, 0)
        bad = self.out / "bad.gz"
        bad.write_bytes(b"not gzip")
        self.assertNotEqual(self.fish("ex", bad).returncode, 0)
        self.assertEqual(bad.read_bytes(), b"not gzip")

    @unittest.skipUnless(
        os.environ.get("COMPRESS") and os.environ.get("SEVENZIP"),
        "Set COMPRESS and SEVENZIP for .Z and .7z fixtures",
    )
    def test_ex_z_and_7z_outside_cwd(self):
        payload = b"payload  with\nwhitespace\n"
        archive = self.out / "archive space.Z"
        compressed = subprocess.check_output(
            [os.environ["COMPRESS"], "-cf"], input=payload
        )
        archive.write_bytes(compressed)
        result = self.fish("ex", archive)
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(
            (self.cwd / "archive space" / "archive space").read_bytes(), payload
        )
        self.assertEqual(archive.read_bytes(), compressed)
        file = self.out / "file space"
        file.write_bytes(payload)
        archive = self.out / "seven space.7z"
        subprocess.run(
            [os.environ["SEVENZIP"], "a", str(archive), file.name],
            cwd=self.out,
            check=True,
            capture_output=True,
        )
        (self.cwd / archive.name).write_bytes(b"decoy")
        result = self.fish("ex", archive)
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual((self.cwd / "seven space" / file.name).read_bytes(), payload)


if __name__ == "__main__":
    unittest.main()
