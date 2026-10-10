from __future__ import annotations

import json
import os
import shutil
import subprocess
import time
import unittest

import test_writers

SCRIPTS = test_writers.SCRIPTS


@unittest.skipUnless(shutil.which("pwsh"), "requires PowerShell")
class PowerShellLockTests(unittest.TestCase):
    setUp = test_writers.WriterTests.setUp
    plan = test_writers.WriterTests.plan
    run_writer = test_writers.WriterTests.run_writer
    snapshot = test_writers.WriterTests.snapshot

    def holder(self, sentinel):
        script = self.root / "hold-lock.ps1"
        ready = self.root / "lock-ready"
        ready.unlink(missing_ok=True)
        script.write_text(
            "param([string]$LockFile, [string]$ReadyFile)\n"
            '$ErrorActionPreference = "Stop"\n'
            "$fs = [System.IO.File]::Open($LockFile, "
            "[System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, "
            "[System.IO.FileShare]::None)\n"
            "try {\n"
            '    [Console]::WriteLine("HELD")\n'
            "    [Console]::Out.Flush()\n"
            '    [System.IO.File]::WriteAllText($ReadyFile, "ready")\n'
            "    [void][Console]::ReadLine()\n"
            "} finally { $fs.Dispose() }\n"
        )
        owner = subprocess.Popen(
            ["pwsh", "-NoProfile", "-File", str(script), str(sentinel), str(ready)],
            cwd=self.root,
            env=self.env,
            text=True,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        self.addCleanup(self.stop_process, owner)
        deadline = time.monotonic() + 10
        while (
            not ready.exists() and owner.poll() is None and time.monotonic() < deadline
        ):
            time.sleep(0.02)
        self.assertTrue(
            ready.exists(), "holder failed to acquire the lock within 10 seconds"
        )
        self.assertEqual("HELD", owner.stdout.readline().strip())
        return owner

    @staticmethod
    def stop_process(process):
        if process.poll() is None:
            process.kill()
        process.communicate(timeout=5)

    def release(self, owner):
        out, err = owner.communicate(input="release\n", timeout=5)
        self.assertEqual(0, owner.returncode, out + err)

    def test_held_native_lock_times_out_without_mutation(self):
        for name, args, lock in (
            ("phase-status", ("1", "complete"), ".write_lock"),
            ("ledger-append", ("note", "fixture"), ".ledger_lock"),
            ("attest-plan", (), ".attestation.lock"),
        ):
            with self.subTest(writer=name):
                sentinel = self.root / lock
                sentinel.write_bytes(b"retained sentinel\n")
                if name == "attest-plan":
                    (self.root / ".plan-attestation").write_text("0" * 64)
                owner = self.holder(sentinel)
                before = self.snapshot()
                started = time.monotonic()
                result = self.run_writer(name, "ps1", args, self.env)
                elapsed = time.monotonic() - started
                self.assertIsNone(owner.poll(), "owner exited before writer completed")
                self.assertNotEqual(0, result.returncode, result.stdout + result.stderr)
                self.assertIn("Timed out acquiring", result.stderr)
                self.assertGreaterEqual(elapsed, 5)
                self.assertEqual(before, self.snapshot())
                self.release(owner)
                # A retained file is not a stale lock: only a live handle blocks.
                result = self.run_writer(name, "ps1", args, self.env)
                self.assertEqual(0, result.returncode, result.stderr)
                self.assertEqual(b"retained sentinel\n", sentinel.read_bytes())
                self.assertEqual([], list(self.root.glob("*.tmp.*")))

    def concurrent(self, name, commands, lock):
        sentinel = self.root / lock
        sentinel.write_bytes(b"stable sentinel\n")
        original_stat = sentinel.stat()
        owner = self.holder(sentinel)
        processes = []
        try:
            for args in commands:
                process = subprocess.Popen(
                    [
                        "pwsh",
                        "-NoProfile",
                        "-File",
                        str(SCRIPTS / f"{name}.ps1"),
                        *args,
                    ],
                    cwd=self.root,
                    env=self.env,
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                )
                processes.append(process)
            # Let contenders enter their acquisition loops before releasing.
            time.sleep(1)
            self.release(owner)
            for process in processes:
                out, err = process.communicate(timeout=20)
                self.assertEqual(0, process.returncode, out + err)
        finally:
            for process in processes:
                self.stop_process(process)
        self.assertEqual(b"stable sentinel\n", sentinel.read_bytes())
        if os.name == "posix":
            self.assertEqual(original_stat.st_ino, sentinel.stat().st_ino)
        self.assertEqual([], list(self.root.glob("*.tmp.*")))
        # A fresh FileShare.None holder must still exclude the next writer.
        owner = self.holder(sentinel)
        before = self.snapshot()
        result = self.run_writer(name, "ps1", commands[0], self.env)
        self.assertNotEqual(0, result.returncode, result.stdout + result.stderr)
        self.assertEqual(before, self.snapshot())
        self.release(owner)

    def test_concurrent_phase_updates_are_all_retained(self):
        (self.root / "task_plan.md").write_text(
            "".join(f"### Phase {n}\n**Status:** pending\n" for n in range(1, 7))
        )
        self.concurrent(
            "phase-status", [(str(n), "complete") for n in range(1, 7)], ".write_lock"
        )
        plan = (self.root / "task_plan.md").read_text()
        self.assertEqual(6, plan.count("**Status:** complete"))
        self.assertNotIn("pending", plan)

    def test_concurrent_ledgers_have_unique_global_ticks(self):
        self.concurrent(
            "ledger-append",
            [("note", f"entry-{n}", "-Agent", f"worker-{n}") for n in range(8)],
            ".ledger_lock",
        )
        entries = [
            json.loads(line)
            for p in self.root.glob("ledger-*.jsonl")
            for line in p.read_text(encoding="utf-8-sig").splitlines()
        ]
        self.assertEqual(list(range(1, 9)), sorted(e["tick"] for e in entries))
        self.assertEqual(
            {f"entry-{n}" for n in range(8)}, {e["summary"] for e in entries}
        )

    def test_concurrent_attestation_writers_preserve_hash(self):
        import hashlib

        self.concurrent("attest-plan", [()] * 6, ".attestation.lock")
        self.assertEqual(
            hashlib.sha256((self.root / "task_plan.md").read_bytes()).hexdigest(),
            (self.root / ".plan-attestation").read_text().strip(),
        )

    def test_phase_failed_swap_cleans_temp_and_retains_sentinel(self):
        wrapper = self.root / "failed-swap.ps1"
        wrapper.write_text(
            "param([string]$Writer)\n"
            'function Move-Item { throw "injected swap failure" }\n'
            "& $Writer 1 complete\n"
        )
        sentinel = self.root / ".write_lock"
        sentinel.write_bytes(b"retained sentinel\n")
        before = (self.root / "task_plan.md").read_bytes()
        result = subprocess.run(
            [
                "pwsh",
                "-NoProfile",
                "-File",
                str(wrapper),
                str(SCRIPTS / "phase-status.ps1"),
            ],
            cwd=self.root,
            env=self.env,
            text=True,
            capture_output=True,
            timeout=15,
            check=False,
        )
        self.assertNotEqual(0, result.returncode)
        self.assertIn("injected swap failure", result.stderr)
        self.assertEqual(before, (self.root / "task_plan.md").read_bytes())
        self.assertEqual([], list(self.root.glob("*.tmp.*")))
        self.assertEqual(b"retained sentinel\n", sentinel.read_bytes())
        owner = self.holder(sentinel)
        self.release(owner)

    def test_failure_retains_sentinel_and_releases_lock(self):
        for name, args, lock in (
            ("phase-status", ("99", "complete"), ".write_lock"),
            ("ledger-append", ("note", "fixture"), ".ledger_lock"),
            ("attest-plan", (), ".attestation.lock"),
        ):
            with self.subTest(writer=name):
                sentinel = self.root / lock
                sentinel.write_bytes(b"retained sentinel\n")
                plan_before = (self.root / "task_plan.md").read_bytes()
                target = self.root / (
                    ".plan-attestation"
                    if name == "attest-plan"
                    else "ledger-main.jsonl"
                )
                if name != "phase-status":
                    target.mkdir()
                result = self.run_writer(name, "ps1", args, self.env)
                self.assertNotEqual(0, result.returncode)
                self.assertEqual(plan_before, (self.root / "task_plan.md").read_bytes())
                self.assertEqual(b"retained sentinel\n", sentinel.read_bytes())
                self.assertEqual([], list(self.root.glob("*.tmp.*")))
                owner = self.holder(sentinel)
                self.release(owner)
                if name != "phase-status":
                    target.rmdir()
                retry = self.run_writer(
                    name,
                    "ps1",
                    ("1", "complete") if name == "phase-status" else args,
                    self.env,
                )
                self.assertEqual(0, retry.returncode, retry.stderr)


if __name__ == "__main__":
    unittest.main()
