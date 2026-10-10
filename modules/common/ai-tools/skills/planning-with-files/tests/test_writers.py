from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
WRITERS = (
    ("phase-status", ("1", "complete")),
    ("attest-plan", ()),
    ("ledger-append", ("note", "fixture")),
)


class WriterTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.env = dict(os.environ)
        self.env.pop("PWF_SESSION_ID", None)
        self.env.pop("PLAN_ID", None)
        self.plan(self.root)

    def plan(self, root: Path) -> None:
        root.mkdir(parents=True, exist_ok=True)
        (root / "task_plan.md").write_text("### Phase 1\n**Status:** pending\n")

    def run_writer(
        self, name: str, suffix: str, args: tuple[str, ...], env: dict[str, str]
    ) -> subprocess.CompletedProcess[str]:
        if suffix == "ps1":
            if not shutil.which("pwsh"):
                self.skipTest("PowerShell is unavailable")
            command = ["pwsh", "-NoProfile", "-File"]
        else:
            command = ["sh"]
        return subprocess.run(
            command + [str(SCRIPTS / f"{name}.{suffix}"), *args],
            cwd=self.root,
            env=env,
            text=True,
            capture_output=True,
            timeout=15,
            check=False,
        )

    def snapshot(self) -> dict[str, bytes]:
        return {
            str(p.relative_to(self.root)): p.read_bytes()
            for p in self.root.rglob("*")
            if p.is_file()
        }

    def assert_effect(self, name: str, root: Path) -> None:
        if name == "phase-status":
            self.assertIn("**Status:** complete", (root / "task_plan.md").read_text())
        elif name == "attest-plan":
            self.assertEqual(
                len(
                    (
                        root
                        / (".plan-attestation" if root == self.root else ".attestation")
                    )
                    .read_text()
                    .strip()
                ),
                64,
            )
        else:
            entries = (
                (root / "ledger-main.jsonl")
                .read_text(encoding="utf-8-sig")
                .splitlines()
            )
            self.assertEqual(json.loads(entries[-1])["summary"], "fixture")

    def test_unresolved_sessions_never_fall_back(self) -> None:
        other = self.root / ".planning" / "other"
        self.plan(other)
        (other.parent / ".active_plan").write_text("other")
        (other.parent / "sessions").mkdir()
        for session, attachment in (
            ("missing", None),
            ("invalid/id", None),
            ("stale", "deleted"),
            ("bad", "../other"),
        ):
            if attachment is not None:
                (other.parent / "sessions" / f"{session}.attached").write_text(
                    attachment
                )
            for suffix in ("sh", "ps1"):
                for name, args in WRITERS:
                    with self.subTest(session=session, writer=name, suffix=suffix):
                        before = self.snapshot()
                        result = self.run_writer(
                            name,
                            suffix,
                            args,
                            {**self.env, "PWF_SESSION_ID": session, "PLAN_ID": "other"},
                        )
                        self.assertNotEqual(result.returncode, 0, result.stdout)
                        self.assertEqual(before, self.snapshot())

    def test_attached_session_selects_exact_plan(self) -> None:
        selected = self.root / ".planning" / "selected"
        self.plan(selected)
        self.plan(self.root / ".planning" / "other")
        sessions = selected.parent / "sessions"
        sessions.mkdir()
        (sessions / "current.attached").write_text("selected\n")
        legacy = (self.root / "task_plan.md").read_bytes()
        for suffix in ("sh", "ps1"):
            for name, args in WRITERS:
                with self.subTest(writer=name, suffix=suffix):
                    result = self.run_writer(
                        name,
                        suffix,
                        args,
                        {**self.env, "PWF_SESSION_ID": "current", "PLAN_ID": "other"},
                    )
                    self.assertEqual(0, result.returncode, result.stderr)
                    self.assert_effect(name, selected)
                    self.assertEqual(legacy, (self.root / "task_plan.md").read_bytes())

    def test_legacy_and_explicit_root_attachment(self) -> None:
        for session in ("", "current"):
            if session:
                sessions = self.root / ".planning" / "sessions"
                sessions.mkdir(parents=True)
                (sessions / "current.attached").write_text(".\n")
            for suffix in ("sh", "ps1"):
                for name, args in WRITERS:
                    with self.subTest(session=session, writer=name, suffix=suffix):
                        result = self.run_writer(
                            name, suffix, args, {**self.env, "PWF_SESSION_ID": session}
                        )
                        self.assertEqual(0, result.returncode, result.stderr)
                        self.assert_effect(name, self.root)

    def shim(self, name: str, body: str) -> dict[str, str]:
        directory = self.root / "bin"
        directory.mkdir(exist_ok=True)
        script = directory / name
        script.write_text("#!/bin/sh\n" + body)
        script.chmod(0o755)
        return {**self.env, "PATH": str(directory) + os.pathsep + self.env["PATH"]}

    def test_phase_rename_failure_reports_failure_and_cleans_temp(self) -> None:
        original = (self.root / "task_plan.md").read_bytes()
        result = self.run_writer(
            "phase-status", "sh", ("1", "complete"), self.shim("mv", "exit 1\n")
        )
        self.assertNotEqual(0, result.returncode)
        self.assertEqual(original, (self.root / "task_plan.md").read_bytes())
        self.assertEqual([], list(self.root.glob("task_plan.md.tmp.*")))

    def test_attestation_retry_remains_atomic(self) -> None:
        real_mv = shutil.which("mv")
        marker = self.root / "first-move"
        env = self.shim(
            "mv",
            f'if [ ! -f "{marker}" ]; then touch "{marker}"; exit 1; fi\nexec "{real_mv}" "$@"\n',
        )
        result = self.run_writer("attest-plan", "sh", (), env)
        self.assertEqual(0, result.returncode, result.stderr)
        self.assert_effect("attest-plan", self.root)
        self.assertEqual([], list(self.root.glob("*.tmp.*")))
        self.assertEqual([], list(self.root.glob("*.fb.*")))

    def test_failed_flock_never_writes(self) -> None:
        env = self.shim("flock", "exit 1\n")
        for name, args in WRITERS:
            with self.subTest(writer=name):
                original = (self.root / "task_plan.md").read_bytes()
                result = self.run_writer(name, "sh", args, env)
                self.assertNotEqual(0, result.returncode)
                self.assertEqual(original, (self.root / "task_plan.md").read_bytes())
                self.assertFalse((self.root / ".plan-attestation").exists())
                self.assertFalse((self.root / "ledger-main.jsonl").exists())
                self.assertEqual([], list(self.root.glob("*.tmp.*")))
                self.assertEqual([], list(self.root.glob("*.fb.*")))

    @unittest.skipUnless(shutil.which("flock"), "requires flock")
    def test_concurrent_ledger_writers_allocate_unique_ticks(self) -> None:
        processes = [
            subprocess.Popen(
                [
                    "sh",
                    str(SCRIPTS / "ledger-append.sh"),
                    "note",
                    "fixture",
                    "--agent",
                    f"worker-{n}",
                ],
                cwd=self.root,
                env=self.env,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            for n in range(12)
        ]
        try:
            for process in processes:
                stdout, stderr = process.communicate(timeout=15)
                self.assertEqual(0, process.returncode, stderr + stdout)
        finally:
            for process in processes:
                if process.poll() is None:
                    process.kill()
                process.wait()
        ticks = [
            json.loads(p.read_text())["tick"] for p in self.root.glob("ledger-*.jsonl")
        ]
        self.assertEqual(list(range(1, 13)), sorted(ticks))

    @unittest.skipUnless(
        os.name == "posix" and shutil.which("flock"), "requires POSIX flock"
    )
    def test_open_lock_descriptor_stays_on_writer_sentinel(self) -> None:
        import fcntl

        real_flock = shutil.which("flock")
        env = self.shim("flock", f'exec "{real_flock}" -w 0.1 9\n')
        for name, args in WRITERS:
            with self.subTest(writer=name):
                sentinel = (
                    self.root
                    / {
                        "phase-status": ".write_lock",
                        "attest-plan": ".attestation.lock",
                        "ledger-append": ".ledger_lock",
                    }[name]
                )
                # A queued writer can already have opened the sentinel when a peer
                # completes. Its descriptor must remain the inode new writers lock.
                with sentinel.open("a") as queued:
                    first = self.run_writer(name, "sh", args, env)
                    self.assertEqual(0, first.returncode, first.stderr)
                    fcntl.flock(queued, fcntl.LOCK_EX)
                    before = self.snapshot()
                    second = self.run_writer(name, "sh", args, env)
                    self.assertNotEqual(0, second.returncode)
                    self.assertEqual(before, self.snapshot())


if __name__ == "__main__":
    unittest.main()
