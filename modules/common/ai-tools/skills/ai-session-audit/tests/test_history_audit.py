from __future__ import annotations

import contextlib
import datetime as dt
import importlib.util
import io
import json
import os
import sqlite3
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any

SCRIPT = Path(__file__).parents[1] / "scripts" / "history_audit.py"
SPEC = importlib.util.spec_from_file_location("history_audit", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
history = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = history
SPEC.loader.exec_module(history)

SCHEMA = """
create table sessions (id text primary key, project text, agent text, started_at text, entrypoint text,
  is_automated integer default 0, relationship_type text, cwd text, file_path text);
create table messages (id integer primary key, session_id text, ordinal integer, role text, content text,
  timestamp text, is_system integer default 0, has_tool_use integer default 0, source_subtype text);
create table tool_calls (id integer primary key, message_id integer, session_id text, tool_name text,
  skill_name text, input_json text, file_path text);
"""


class Archive:
    def __init__(self, path: Path):
        self.db = sqlite3.connect(path)
        self.db.executescript(SCHEMA)
        self.message_id = 0

    def session(
        self,
        sid: str,
        agent: str,
        started: str,
        project: str = "proj",
        relationship: str = "",
    ) -> None:
        self.db.execute(
            "insert into sessions (id, project, agent, started_at, relationship_type) values (?,?,?,?,?)",
            (sid, project, agent, started, relationship),
        )

    def message(
        self, sid: str, ordinal: int, role: str, content: str, *, tool_use: int = 0
    ) -> int:
        self.message_id += 1
        self.db.execute(
            "insert into messages (id, session_id, ordinal, role, content, timestamp, has_tool_use) "
            "values (?,?,?,?,?,?,?)",
            (
                self.message_id,
                sid,
                ordinal,
                role,
                content,
                f"2026-09-{10 + ordinal:02d}T00:00:00Z",
                tool_use,
            ),
        )
        return self.message_id

    def tool(
        self,
        sid: str,
        message_id: int,
        name: str,
        *,
        skill: str = "",
        inp: str = "{}",
        path: str | None = None,
    ) -> None:
        self.db.execute(
            "insert into tool_calls (message_id, session_id, tool_name, skill_name, input_json, file_path) "
            "values (?,?,?,?,?,?)",
            (message_id, sid, name, skill, inp, path),
        )

    def close(self) -> None:
        self.db.commit()
        self.db.close()


def build_archive(path: Path) -> None:
    archive = Archive(path)
    archive.session("codex:review", "codex", "2026-09-10T08:00:00Z", "home_manager")
    archive.message(
        "codex:review",
        0,
        "user",
        "<T3_WORKSPACE_CONTEXT>\nCurrent working directory: /x\n</T3_WORKSPACE_CONTEXT>\n\n"
        + "Can you review https://github.com/nix-community/home-manager/pull/1 please",
    )
    read = archive.message(
        "codex:review", 1, "assistant", "[Bash] sed -n 1,80p SKILL.md", tool_use=1
    )
    archive.tool(
        "codex:review",
        read,
        "exec_command",
        inp=json.dumps(
            {
                "cmd": "sed -n '1,80p' /home/u/.config/codex/skills/github-toolkit/SKILL.md"
            }
        ),
    )
    archive.message("codex:review", 2, "assistant", "Two findings in the module.")
    archive.message(
        "codex:review",
        3,
        "user",
        '<hook_prompt hook_run_id="stop:1">[okf-memory] check</hook_prompt>',
    )
    archive.message(
        "codex:review",
        4,
        "user",
        "that read like a robot. did you verify this? add a pending review, do not submit. "
        + "atomic conventional commits",
    )
    archive.message("codex:review", 5, "assistant", "Rewrote both comments.")

    archive.session("codex:fix", "codex", "2026-09-11T08:00:00Z", "khanelinix")
    archive.message(
        "codex:fix", 0, "user", "Fix the flake build error in modules/foo.nix"
    )
    edit = archive.message("codex:fix", 1, "assistant", "[apply_patch]", tool_use=1)
    archive.tool(
        "codex:fix",
        edit,
        "apply_patch",
        inp="*** Begin Patch\n*** Update File: modules/foo.nix\n@@\n-a\n+b\n*** End Patch",
    )
    source = archive.message(
        "codex:fix", 2, "assistant", "[Bash] reading skill source", tool_use=1
    )
    archive.tool(
        "codex:fix",
        source,
        "exec_command",
        inp=json.dumps(
            {"cmd": "sed -n 1,40p modules/common/ai-tools/skills/nix-toolkit/SKILL.md"}
        ),
    )
    archive.message("codex:fix", 3, "assistant", "Done.")
    archive.message(
        "codex:fix", 4, "user", "CHANGES MADE:\n- [a.rs](/x/a.rs:1): worker report"
    )
    archive.message(
        "codex:fix",
        5,
        "user",
        "no, don't touch the other modules again. atomic conventional commits please",
    )
    archive.message("codex:fix", 6, "assistant", "Reverted the unrelated modules.")

    archive.session("claude:explicit", "claude", "2026-08-01T08:00:00Z", "khanelinix")
    archive.message(
        "claude:explicit",
        0,
        "user",
        "$github-toolkit review https://github.com/o/r/pull/2",
    )
    skill = archive.message("claude:explicit", 1, "assistant", "[Skill]", tool_use=1)
    archive.tool(
        "claude:explicit",
        skill,
        "Skill",
        skill="nix-toolkit",
        inp=json.dumps({"skill": "nix-toolkit"}),
    )
    archive.message("claude:explicit", 2, "user", "<command-name>/model</command-name>")
    change = archive.message("claude:explicit", 3, "assistant", "[Edit]", tool_use=1)
    archive.tool("claude:explicit", change, "Edit", path="/repo/modules/bar.nix")
    archive.message("claude:explicit", 4, "user", "commit please")
    archive.message(
        "claude:explicit",
        5,
        "assistant",
        "API Error: Request rejected (429) · All credentials for model claude-x "
        + "are cooling down via provider claude",
    )
    archive.message("claude:explicit", 6, "user", "sorry, continue")
    archive.message(
        "claude:explicit",
        7,
        "user",
        "# Files mentioned by the user:\n\n## a.png: /tmp/a.png\n\n## My request for Codex:\n"
        + "Can you help me fix this ssh error token=ghp_ABCDEFGHIJKLMNOPQRSTUV1234",
    )
    archive.message(
        "claude:explicit",
        8,
        "user",
        "PLEASE IMPLEMENT THIS PLAN:\n# Plan\nagent-authored body",
    )

    archive.session(
        "claude:worker", "claude", "2026-09-12T08:00:00Z", relationship="subagent"
    )
    archive.message("claude:worker", 0, "user", "worker packet")
    archive.session("codex:probe", "codex", "2026-09-12T08:00:00Z")
    archive.message("codex:probe", 0, "user", "reply with exactly: ok")
    archive.session("opencode:notice", "opencode", "2026-09-12T08:00:00Z")
    archive.message("opencode:notice", 0, "user", "▣ DCP | ~5K tokens saved total")
    archive.message("opencode:notice", 1, "user", "Can you help me fix waybar")
    archive.close()


@contextlib.contextmanager
def fixture():
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        db = root / "sessions.db"
        build_archive(db)
        yield root, db


def run_cli(*args: str) -> tuple[int, str, str]:
    stdout, stderr = io.StringIO(), io.StringIO()
    with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
        code = history.main(list(args))
    return code, stdout.getvalue(), stderr.getvalue()


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


class ExtractTests(unittest.TestCase):
    def test_extract_keeps_human_prompts_and_drops_injected_content(self) -> None:
        with fixture() as (root, db):
            code, _, stderr = run_cli(
                "extract", "--db", str(db), "--out", str(root / "run")
            )
            self.assertEqual(code, 0, stderr)
            prompts = read_jsonl(root / "run" / "prompts.jsonl")
            texts = [str(prompt["text"]) for prompt in prompts]
            summary = json.loads((root / "run" / "extract-summary.json").read_text())

        self.assertIn(
            "Can you review https://github.com/nix-community/home-manager/pull/1 please",
            texts,
        )
        self.assertIn("/model", texts)
        self.assertIn("<plan-implement action>", texts)
        self.assertIn("Can you help me fix this ssh error <redacted-secret>", texts)
        self.assertIn("Can you help me fix waybar", texts)
        self.assertFalse(
            any(
                "CHANGES MADE" in text or "hook_prompt" in text or "DCP" in text
                for text in texts
            )
        )
        self.assertFalse(
            any(
                "worker packet" in text or "reply with exactly" in text
                for text in texts
            )
        )
        self.assertEqual(summary["dropped"]["agent-relayed"], 2)
        self.assertEqual(summary["dropped"]["injected"], 1)
        self.assertEqual(summary["dropped"]["subagent-session"], 1)
        self.assertEqual(summary["dropped"]["probe-session"], 1)

    def test_outputs_are_private_and_not_overwritten(self) -> None:
        with fixture() as (root, db):
            out = root / "run"
            self.assertEqual(
                run_cli("extract", "--db", str(db), "--out", str(out))[0], 0
            )
            mode = stat.S_IMODE((out / "prompts.jsonl").stat().st_mode)
            directory = stat.S_IMODE(out.stat().st_mode)
            again, _, stderr = run_cli("extract", "--db", str(db), "--out", str(out))
            forced, _, _ = run_cli(
                "extract", "--db", str(db), "--out", str(out), "--force"
            )

        self.assertEqual(mode, 0o600)
        self.assertEqual(directory, 0o700)
        self.assertEqual(again, 2)
        self.assertIn("--force", stderr)
        self.assertEqual(forced, 0)

    def test_missing_archive_is_invalid_input(self) -> None:
        code, _, stderr = run_cli("status", "--db", "/nonexistent/sessions.db")
        self.assertEqual(code, 2)
        self.assertIn("archive not found", stderr)

    def test_status_reports_staleness(self) -> None:
        with fixture() as (_, db):
            report = history.status(
                history.connect(db),
                now=dt.datetime(2026, 9, 14, 8, tzinfo=dt.timezone.utc),
            )
        self.assertEqual(report["newest_session"], "2026-09-12T08:00:00Z")
        self.assertEqual(report["stale_days"], 2.0)


class DigestTests(unittest.TestCase):
    def test_review_threads_and_digests_pair_follow_ups_with_replies(self) -> None:
        with fixture() as (root, db):
            out = root / "run"
            run_cli("extract", "--db", str(db), "--out", str(out))
            self.assertEqual(
                run_cli("threads", "--db", str(db), "--out", str(out))[0], 0
            )
            review = read_jsonl(out / "threads-review.jsonl")
            code, _, stderr = run_cli("digest", "--db", str(db), "--out", str(out))
            self.assertEqual(code, 0, stderr)
            digest = (out / "digests" / "review-1.md").read_text()

        self.assertEqual(
            {row["session_id"] for row in review}, {"codex:review", "claude:explicit"}
        )
        codex = next(row for row in review if row["session_id"] == "codex:review")
        self.assertEqual(codex["skills_loaded"], ["github-toolkit"])
        self.assertEqual(
            codex["turns"][0]["assistant_final"], "Two findings in the module."
        )
        self.assertIn("T1 USER: that read like a robot", digest)
        self.assertIn("T1 AGENT: Rewrote both comments.", digest)

    def test_small_chunks_split_digests(self) -> None:
        chunks = history.render_chunks(["a" * 50, "b" * 50, "c" * 50], 120)
        self.assertEqual(len(chunks), 2)

    def test_correction_digest_uses_previous_reply_and_skips_review_sessions(
        self,
    ) -> None:
        with fixture() as (root, db):
            out = root / "run"
            run_cli("extract", "--db", str(db), "--out", str(out))
            run_cli("threads", "--db", str(db), "--out", str(out))
            code, _, stderr = run_cli("corrections", "--db", str(db), "--out", str(out))
            self.assertEqual(code, 0, stderr)
            digest = (out / "digests" / "corrections-1.md").read_text()

        self.assertIn("USER T1: no, don't touch the other modules again", digest)
        self.assertIn("AGENT(prev, tail): Done.", digest)
        self.assertNotIn("robot", digest)


class RoutingTests(unittest.TestCase):
    def test_routing_counts_installed_reads_explicit_mentions_and_windows(self) -> None:
        with fixture() as (root, db):
            out = root / "run"
            run_cli("extract", "--db", str(db), "--out", str(out))
            code, _, stderr = run_cli(
                "routing",
                "--db",
                str(db),
                "--out",
                str(out),
                "--boundary",
                "2026-09-01",
            )
            self.assertEqual(code, 0, stderr)
            report = json.loads((out / "routing.json").read_text())

        rows = {
            (row["agent"], row["skill"], row["window"]): row for row in report["rows"]
        }
        self.assertEqual(rows[("codex", "github-toolkit", ">=2026-09-01")]["auto"], 1)
        self.assertEqual(
            rows[("claude", "github-toolkit", "<2026-09-01")]["explicit"], 1
        )
        # Reading the repository source of a skill is not a routing load.
        self.assertEqual(
            rows[("codex", "nix-toolkit", ">=2026-09-01")].get("auto", 0), 0
        )
        self.assertEqual(rows[("codex", "nix-toolkit", ">=2026-09-01")]["missing"], 2)
        edits = {(row["agent"], row["skill"]): row for row in report["edits"]}
        self.assertEqual(edits[("claude", "nix-toolkit")]["before-edit"], 1)
        self.assertEqual(edits[("codex", "nix-toolkit")]["never"], 1)

    def test_window_labels_use_half_open_boundaries(self) -> None:
        boundaries = ["2026-08-27", "2026-09-22"]
        self.assertEqual(history.window_label("2026-08-26", boundaries), "<2026-08-27")
        self.assertEqual(
            history.window_label("2026-08-27", boundaries), "2026-08-27..2026-09-22"
        )
        self.assertEqual(history.window_label("2026-09-22", boundaries), ">=2026-09-22")
        self.assertEqual(history.window_label("2026-09-22", []), "all")

    def test_invalid_triggers_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "triggers.json"
            path.write_text(json.dumps({"skills": {"x": {}}}))
            with self.assertRaises(history.HistoryError):
                history.load_triggers(path)


class SignalTests(unittest.TestCase):
    def test_phrases_rank_cross_session_repeats(self) -> None:
        with fixture() as (root, db):
            out = root / "run"
            run_cli("extract", "--db", str(db), "--out", str(out))
            report = history.phrases(read_jsonl(out / "prompts.jsonl"), 2, 20)
        self.assertIn(
            "atomic conventional commits",
            [item["phrase"] for item in report["phrases"]],
        )

    def test_signals_count_prompt_and_harness_signals(self) -> None:
        with fixture() as (root, db):
            out = root / "run"
            run_cli("extract", "--db", str(db), "--out", str(out))
            code, _, stderr = run_cli("signals", "--db", str(db), "--out", str(out))
            self.assertEqual(code, 0, stderr)
            report = json.loads((out / "signals.json").read_text())

        prompt_rows = {row["agent"]: row for row in report["prompt_signals"]}
        self.assertEqual(prompt_rows["claude"]["bare-commit"], 1)
        self.assertEqual(prompt_rows["claude"]["stall-nudge"], 1)
        self.assertEqual(prompt_rows["codex"]["pending-review-ask"], 1)
        self.assertEqual(prompt_rows["codex"]["verification-ask"], 1)
        errors = {
            (row["agent"], row["session_kind"]): row for row in report["harness_errors"]
        }
        self.assertEqual(errors[("claude", "root")]["gateway-cooldown"], 1)


def git(repo: Path, *args: str, date: str = "2026-09-01T00:00:00Z") -> None:
    env = {
        "PATH": os.environ["PATH"],
        "HOME": str(repo),
        "GIT_CONFIG_GLOBAL": os.devnull,
        "GIT_CONFIG_SYSTEM": os.devnull,
        "GIT_AUTHOR_DATE": date,
        "GIT_COMMITTER_DATE": date,
    }
    subprocess.run(
        [
            "git",
            "-c",
            "user.name=t",
            "-c",
            "user.email=t@example.com",
            "-c",
            "commit.gpgsign=false",
            *args,
        ],
        cwd=repo,
        env=env,
        check=True,
        capture_output=True,
    )


class RunAndLedgerTests(unittest.TestCase):
    def test_run_writes_manifest_and_refuses_non_empty_output(self) -> None:
        with fixture() as (root, db):
            out = root / "run"
            code, _, stderr = run_cli(
                "run", "--db", str(db), "--out", str(out), "--boundary", "2026-09-01"
            )
            self.assertEqual(code, 0, stderr)
            manifest = json.loads((out / "manifest.json").read_text())
            again, _, _ = run_cli("run", "--db", str(db), "--out", str(out))

        self.assertEqual(manifest["arguments"]["boundaries"], ["2026-09-01"])
        self.assertTrue(manifest["review_digests"])
        self.assertEqual(again, 2)

    def test_ledger_attributes_blocks_to_commits(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            repo = Path(temporary)
            git(repo, "init", "-q")
            base = repo / "base.md"
            base.write_text("## Output\n\nLead with the outcome.\n")
            git(repo, "add", "base.md")
            git(
                repo,
                "commit",
                "-q",
                "-m",
                "docs: add output rule\n\nUsers asked for outcomes first.",
            )
            base.write_text(
                "## Output\n\nLead with the outcome.\n\n- Default to concise.\n"
            )
            git(
                repo,
                "commit",
                "-q",
                "-am",
                "docs: second rule\n\nReplies ran long.",
                date="2026-09-15T00:00:00Z",
            )
            report = history.ledger(base, None)

        blocks = report["blocks"]
        self.assertEqual([block["lines"] for block in blocks], ["1-1", "3-3", "5-5"])
        self.assertEqual(
            blocks[1]["commits"][0]["why"], "Users asked for outcomes first."
        )
        self.assertEqual(blocks[1]["first_added"], "2026-09-01")
        self.assertEqual(blocks[2]["commits"][-1]["subject"], "docs: second rule")
        self.assertEqual(blocks[2]["first_added"], "2026-09-15")

    def test_creation_dates_count_renamed_predecessors(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            git(root, "init", "-q")
            (root / "writing-nix").mkdir()
            (root / "writing-nix" / "SKILL.md").write_text("old\n")
            git(root, "add", ".")
            git(
                root, "commit", "-q", "-m", "add old skill", date="2026-01-20T00:00:00Z"
            )
            (root / "nix-toolkit").mkdir()
            (root / "nix-toolkit" / "SKILL.md").write_text("new\n")
            git(root, "add", ".")
            git(
                root, "commit", "-q", "-m", "add new skill", date="2026-05-20T00:00:00Z"
            )
            triggers = {
                "aliases": {"writing-nix": "nix-toolkit"},
                "skills": {
                    "nix-toolkit": {"prompt": "nix"},
                    "how": {"prompt": "how", "since": "2026-08-19"},
                },
            }
            created = history.creation_dates(triggers, root)
        self.assertEqual(created, {"nix-toolkit": "2026-01-20", "how": "2026-08-19"})

    def test_ledger_rejects_file_outside_repository(self) -> None:
        with (
            tempfile.TemporaryDirectory() as first,
            tempfile.TemporaryDirectory() as second,
        ):
            repo = Path(first)
            git(repo, "init", "-q")
            outside = Path(second) / "base.md"
            outside.write_text("rule\n")
            code, _, stderr = run_cli(
                "ledger",
                "--file",
                str(outside),
                "--repo",
                str(repo),
                "--out",
                str(Path(second) / "out"),
            )
        self.assertEqual(code, 2)
        self.assertIn("outside", stderr)


if __name__ == "__main__":
    unittest.main()
