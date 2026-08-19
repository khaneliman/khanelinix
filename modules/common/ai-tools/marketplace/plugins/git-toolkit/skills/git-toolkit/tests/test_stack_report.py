from __future__ import annotations

import importlib.util
import json
import subprocess
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "scripts" / "stack_report.py"
SPEC = importlib.util.spec_from_file_location("stack_report", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
stack_report = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(stack_report)


def completed(stdout: bytes = b"", stderr: bytes = b"", code: int = 0):
    return subprocess.CompletedProcess([], code, stdout, stderr)


class FakeGit:
    def __init__(self) -> None:
        self.calls: list[tuple[Path, tuple[str, ...], bool]] = []

    def __call__(self, repository: Path, arguments, check: bool):
        args = tuple(arguments)
        self.calls.append((repository, args, check))
        responses = {
            ("rev-parse", "--show-toplevel"): completed(b"/repo\n"),
            (
                "rev-parse",
                "--verify",
                "--end-of-options",
                "main^{commit}",
            ): completed(b"base\n"),
            (
                "rev-parse",
                "--verify",
                "--end-of-options",
                "HEAD^{commit}",
            ): completed(b"head\n"),
            ("merge-base", "base", "head"): completed(b"merge\n"),
            (
                "rev-list",
                "--left-right",
                "--count",
                "base...head",
            ): completed(b"1 2\n"),
            (
                "rev-list",
                "--reverse",
                "--topo-order",
                "base..head",
            ): completed(b"commit-one\ncommit-two\n"),
            (
                "status",
                "--porcelain=v1",
                "-z",
                "--untracked-files=all",
            ): completed(b"?? z.txt\0 M a.txt\0"),
            ("symbolic-ref", "--quiet", "--short", "HEAD"): completed(b"topic\n"),
            (
                "show",
                "--no-patch",
                "--format=%H%x00%P%x00%an%x00%ae%x00%aI%x00%B",
                "commit-two",
            ): completed(
                b"commit-two\0parent\0Ada\0ada@example.test\0"
                b"2026-01-02T03:04:05+00:00\0subject\n\nwhy\n"
            ),
            (
                "diff",
                "--name-status",
                "-z",
                "-M",
                "--no-ext-diff",
                "parent",
                "commit-two",
                "--",
            ): completed(b"R100\0old.txt\0new.txt\0M\0same.txt\0"),
        }
        try:
            return responses[args]
        except KeyError as error:
            raise AssertionError(f"unexpected git command: {args}") from error


class StackReportTests(unittest.TestCase):
    def test_report_is_sorted_bounded_and_json_stable(self) -> None:
        fake = FakeGit()

        report = stack_report.build_report(
            Path("/repo"), "main", "HEAD", max_commits=1, git=fake
        )

        self.assertEqual(report["ahead_behind"], {"base_only": 1, "head_only": 2})
        self.assertEqual(report["commits_total"], 2)
        self.assertEqual(report["commits_omitted"], 1)
        self.assertEqual(report["commits"][0]["body"], "why")
        self.assertFalse(report["commits"][0]["body_truncated"])
        self.assertEqual(
            [entry["path"] for entry in report["worktree"]["entries"]],
            ["a.txt", "z.txt"],
        )
        self.assertEqual(
            [entry["path"] for entry in report["commits"][0]["paths"]],
            ["new.txt", "same.txt"],
        )
        first = json.dumps(report, sort_keys=True)
        second = json.dumps(report, sort_keys=True)
        self.assertEqual(first, second)

    def test_status_paths_and_bodies_are_independently_bounded(self) -> None:
        report = stack_report.build_report(
            Path("/repo"),
            "main",
            "HEAD",
            max_commits=1,
            max_status_entries=1,
            max_paths_per_commit=1,
            max_body_chars=2,
            git=FakeGit(),
        )

        self.assertEqual(report["worktree"]["entries_total"], 2)
        self.assertEqual(report["worktree"]["entries_omitted"], 1)
        self.assertTrue(report["worktree"]["entries_truncated"])
        commit = report["commits"][0]
        self.assertEqual(commit["paths_total"], 2)
        self.assertEqual(commit["paths_omitted"], 1)
        self.assertTrue(commit["paths_truncated"])
        self.assertEqual(commit["body"], "wh")
        self.assertEqual(commit["body_chars_total"], 3)
        self.assertEqual(commit["body_chars_omitted"], 1)
        self.assertTrue(commit["body_truncated"])

    def test_status_parser_preserves_rename_source(self) -> None:
        entries = stack_report.parse_status(b"R  new name\0old name\0")
        self.assertEqual(
            entries,
            [{"code": "R ", "original_path": "old name", "path": "new name"}],
        )


if __name__ == "__main__":
    unittest.main()
