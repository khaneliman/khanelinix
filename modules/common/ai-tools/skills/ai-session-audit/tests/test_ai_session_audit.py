from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "scripts" / "ai_session_audit.py"
SPEC = importlib.util.spec_from_file_location("ai_session_audit", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
audit = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = audit
SPEC.loader.exec_module(audit)


def event(
    event_id: str,
    provider: str,
    event_type: str,
    *,
    thread: str,
    turn: str | None = None,
    payload: dict[str, object] | None = None,
    created_at: str = "2026-08-27T12:00:00Z",
) -> dict[str, object]:
    value: dict[str, object] = {
        "eventId": event_id,
        "provider": provider,
        "type": event_type,
        "threadId": thread,
        "createdAt": created_at,
        "payload": payload or {},
    }
    if turn is not None:
        value["turnId"] = turn
    return value


def canonical(value: dict[str, object]) -> str:
    return f"[2026-08-27T12:00:00.000Z] CANON: {json.dumps(value)}\n"


def fixture(directory: Path) -> Path:
    source = directory / "provider"
    source.mkdir()
    first = source / "events.first.log"
    records = [
        event("c1", "claudeAgent", "turn.started", thread="claude", turn="ct1"),
        event(
            "c2-start",
            "claudeAgent",
            "item.started",
            thread="claude",
            turn="ct1",
            payload={
                "itemType": "dynamic_tool_call",
                "status": "running",
                "data": {
                    "toolName": "Skill",
                    "input": {"skill": "technical-writing", "args": ""},
                },
            },
        ),
        event(
            "c2",
            "claudeAgent",
            "item.completed",
            thread="claude",
            turn="ct1",
            payload={
                "itemType": "dynamic_tool_call",
                "status": "completed",
                "data": {
                    "toolName": "Skill",
                    "input": {"skill": "technical-writing", "args": ""},
                },
            },
        ),
        event(
            "c3",
            "claudeAgent",
            "item.completed",
            thread="claude",
            turn="ct1",
            payload={
                "itemType": "collab_agent_tool_call",
                "status": "completed",
                "data": {
                    "toolName": "Agent",
                    "input": {"subagent_type": "reviewer", "model": "fable"},
                },
            },
        ),
        event(
            "c4",
            "claudeAgent",
            "task.started",
            thread="claude",
            turn="ct1",
            payload={"taskId": "task-c", "role": "reviewer", "model": "fable"},
        ),
        event(
            "c5",
            "claudeAgent",
            "thread.token-usage.updated",
            thread="claude",
            turn="ct1",
            payload={
                "usage": {
                    "inputTokens": 100,
                    "outputTokens": 20,
                    "usedTokens": 120,
                }
            },
        ),
        event("c6", "claudeAgent", "turn.completed", thread="claude", turn="ct1"),
        event("x1", "codex", "turn.started", thread="codex", turn="xt1"),
        event(
            "x2",
            "codex",
            "item.completed",
            thread="codex",
            turn="xt1",
            payload={
                "itemType": "command_execution",
                "status": "completed",
                "data": {
                    "item": {
                        "command": "sed -n '1,200p' /repo/skills/ai-tools-architect/SKILL.md",
                        "durationMs": 42,
                    }
                },
            },
        ),
        event(
            "x3",
            "codex",
            "item.completed",
            thread="codex",
            turn="xt1",
            payload={
                "itemType": "collab_agent_tool_call",
                "status": "completed",
                "data": {
                    "item": {
                        "tool": "spawnAgent",
                        "model": "gpt-5.6-sol",
                        "reasoningEffort": "high",
                    }
                },
            },
        ),
        event(
            "x4",
            "codex",
            "thread.token-usage.updated",
            thread="codex",
            payload={
                "usage": {
                    "inputTokens": 999,
                    "lastInputTokens": 200,
                    "cachedInputTokens": 80,
                    "lastCachedInputTokens": 50,
                    "outputTokens": 999,
                    "lastOutputTokens": 30,
                    "reasoningOutputTokens": 99,
                    "lastReasoningOutputTokens": 10,
                    "usedTokens": 230,
                }
            },
        ),
        event("x5", "codex", "turn.completed", thread="codex", turn="xt1"),
    ]
    first.write_text("".join(canonical(record) for record in records), encoding="utf-8")
    second = source / "events.first.log.1"
    second.write_text(
        canonical(records[0])
        + '[time] NTIVE: {"output": "] CANON: {not-an-event"}\n'
        + "[time] CANON: {truncated\n",
        encoding="utf-8",
    )
    return source


class SessionAuditTests(unittest.TestCase):
    def scan(self, source: Path, **filters: object):
        stats = audit.ScanStats()
        files = audit.source_files([str(source)])
        events = [
            audit.normalize(value)
            for value in audit.canonical_events(
                files,
                stats,
                since=filters.get("since"),
                until=filters.get("until"),
                providers=filters.get("providers", set()),
                thread_id=filters.get("thread_id"),
                strict=filters.get("strict", False),
            )
        ]
        return files, stats, events

    def test_summary_reports_turns_tools_skills_workers_and_tokens(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source = fixture(Path(temporary))
            files, stats, events = self.scan(source)
            report = audit.summarize(
                events,
                stats,
                sources=files,
                since=None,
                until=None,
                providers=[],
                selected_thread=None,
                policy_revision="revision-a",
                top=20,
            )

        self.assertEqual(report["totals"]["threads"], 2)
        self.assertEqual(report["totals"]["turns"], 2)
        self.assertEqual(report["totals"]["completed_turns"], 2)
        self.assertEqual(report["totals"]["tool_calls"], 4)
        self.assertEqual(report["totals"]["skill_observations"], 2)
        self.assertEqual(report["totals"]["delegation_calls"], 2)
        self.assertEqual(report["tokens"]["input_tokens"], 300)
        self.assertEqual(report["tokens"]["cached_input_tokens"], 50)
        self.assertEqual(report["tokens"]["output_tokens"], 50)
        self.assertEqual(report["tokens"]["reasoning_output_tokens"], 10)
        self.assertEqual(report["tokens"]["processed_tokens"], 350)
        self.assertEqual(
            {
                row["provider"]: row["processed_tokens"]
                for row in report["tokens"]["by_provider"]
            },
            {"claudeAgent": 120, "codex": 230},
        )
        self.assertEqual(report["scan"]["duplicate_events"], 1)
        self.assertEqual(report["scan"]["malformed_events"], 1)
        self.assertEqual(
            {row["skill"] for row in report["skills"]},
            {"technical-writing", "ai-tools-architect"},
        )
        self.assertEqual(report["worker_roles"], [{"role": "reviewer", "count": 1}])
        self.assertEqual(
            {row["method"] for row in report["skill_detection"]},
            {"tool", "skill-path-reference"},
        )
        self.assertEqual(
            {
                (row["provider"], row["method"], row["skill"])
                for row in report["skills_by_evidence"]
            },
            {
                ("claudeAgent", "tool", "technical-writing"),
                ("codex", "skill-path-reference", "ai-tools-architect"),
            },
        )
        self.assertEqual(
            report["models_by_provider"],
            [{"provider": "claudeAgent", "model": "fable", "count": 1}],
        )
        self.assertEqual(
            {
                (row["provider"], row["model"])
                for row in report["delegation_models_by_provider"]
            },
            {("claudeAgent", "fable"), ("codex", "gpt-5.6-sol")},
        )

    def test_provider_and_time_filters_are_applied_before_normalization(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source = fixture(Path(temporary))
            _, stats, events = self.scan(
                source,
                providers={"codex"},
                since=audit.parse_time("2026-08-27", "--since"),
            )

        self.assertTrue(events)
        self.assertEqual({value["provider"] for value in events}, {"codex"})
        self.assertGreater(stats.filtered_events, 0)

    def test_event_export_never_contains_raw_content_fields(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source = fixture(Path(temporary))
            _, _, events = self.scan(source)

        forbidden = {"raw", "prompt", "command", "input", "result", "reasoning"}
        for value in events:
            self.assertTrue(forbidden.isdisjoint(value))

    def test_free_form_categorical_input_is_scrubbed(self) -> None:
        secret = "sk-secret-value-that-must-not-survive"
        value = event(
            "unsafe",
            "claudeAgent",
            "item.completed",
            thread="thread",
            payload={
                "itemType": "dynamic_tool_call",
                "data": {"toolName": "Skill", "input": {"skill": secret}},
            },
        )

        normalized = audit.normalize(value)
        serialized = json.dumps(normalized)

        self.assertNotIn(secret, serialized)
        self.assertEqual(len(normalized["skill_names"]), 1)
        self.assertTrue(normalized["skill_names"][0].startswith("other-skill-"))
        self.assertIn("skill_name", normalized["scrubbed_fields"])

    def test_log_derived_prose_is_absent_from_every_output_format(self) -> None:
        secret = "PRIVATE phrase must not survive"
        identifier_secret = "private_key_material_7R3vN9qL2sX8"
        high_entropy_secret = "Qm9vdHN0cmFwX1NlY3JldF8xMjM0NTY3ODkw"
        values = [
            event(
                secret,
                "claudeAgent",
                "item.completed",
                thread=secret,
                turn=secret,
                created_at=secret,
                payload={
                    "itemType": "dynamic_tool_call",
                    "status": secret,
                    "data": {
                        "toolName": "Skill",
                        "input": {"skill": identifier_secret},
                    },
                },
            ),
            event(
                "agent-event",
                "claudeAgent",
                "item.completed",
                thread="thread",
                payload={
                    "itemType": "collab_agent_tool_call",
                    "data": {
                        "toolName": "Agent",
                        "input": {
                            "subagent_type": identifier_secret,
                            "model": high_entropy_secret,
                        },
                    },
                },
            ),
            event(
                "tool-event",
                "claudeAgent",
                "item.completed",
                thread="thread",
                payload={
                    "itemType": "dynamic_tool_call",
                    "data": {"toolName": high_entropy_secret},
                },
            ),
            event(
                "task-event",
                "codex",
                "task.started",
                thread="thread",
                payload={
                    "taskId": secret,
                    "role": high_entropy_secret,
                    "model": identifier_secret,
                    "effort": identifier_secret,
                },
            ),
            event(
                "category-event",
                secret,
                secret,
                thread="thread",
                payload={"itemType": secret, "status": secret},
            ),
        ]
        normalized = [audit.normalize(value) for value in values]
        stats = audit.ScanStats(files=1, canonical_lines=len(values))
        report = audit.summarize(
            normalized,
            stats,
            sources=[Path("events.test.log")],
            since=None,
            until=None,
            providers=[],
            selected_thread=None,
            policy_revision=None,
            top=20,
        )

        forbidden = (secret, identifier_secret, high_entropy_secret)
        for private_value in forbidden:
            self.assertNotIn(private_value, json.dumps(normalized))
            self.assertNotIn(private_value, json.dumps(report))
            self.assertNotIn(private_value, audit.render_markdown(report))

        with tempfile.TemporaryDirectory() as temporary:
            source = Path(temporary) / "events.test.log"
            source.write_text(
                "".join(canonical(value) for value in values), encoding="utf-8"
            )
            stdout = io.StringIO()
            with contextlib.redirect_stdout(stdout):
                audit.main(["events", "--source", str(source)])

        for private_value in forbidden:
            self.assertNotIn(private_value, stdout.getvalue())

    def test_mixed_timezone_offsets_use_instant_order(self) -> None:
        values = [
            event(
                "first",
                "codex",
                "thread.token-usage.updated",
                thread="thread",
                created_at="2026-08-27T12:00:00+02:00",
                payload={"usage": {"lastInputTokens": 1, "usedTokens": 10}},
            ),
            event(
                "last",
                "codex",
                "thread.token-usage.updated",
                thread="thread",
                created_at="2026-08-27T11:00:00Z",
                payload={"usage": {"lastInputTokens": 2, "usedTokens": 20}},
            ),
        ]
        report = audit.summarize(
            [audit.normalize(value) for value in values],
            audit.ScanStats(files=1, canonical_lines=2),
            sources=[Path("events.test.log")],
            since=None,
            until=None,
            providers=[],
            selected_thread=None,
            policy_revision=None,
            top=20,
        )

        self.assertEqual(report["threads"][0]["duration_seconds"], 3600.0)
        self.assertEqual(report["threads"][0]["first_event"], "2026-08-27T10:00:00Z")
        self.assertEqual(report["threads"][0]["last_event"], "2026-08-27T11:00:00Z")
        self.assertEqual(report["tokens"]["latest_context_tokens"], 20)

    def test_duplicate_task_start_counts_one_worker_role_and_model(self) -> None:
        values = [
            event(
                event_id,
                "codex",
                "task.started",
                thread="thread",
                payload={
                    "taskId": "task",
                    "role": "reviewer",
                    "model": "gpt-5.6-sol",
                    "effort": "high",
                },
            )
            for event_id in ("task-start-1", "task-start-2")
        ]
        report = audit.summarize(
            [audit.normalize(value) for value in values],
            audit.ScanStats(files=1, canonical_lines=2),
            sources=[Path("events.test.log")],
            since=None,
            until=None,
            providers=[],
            selected_thread=None,
            policy_revision=None,
            top=20,
        )

        self.assertEqual(report["totals"]["worker_tasks_started"], 1)
        self.assertEqual(report["worker_roles"], [{"role": "reviewer", "count": 1}])
        self.assertEqual(report["models"], [{"model": "gpt-5.6-sol", "count": 1}])
        self.assertEqual(report["reasoning_efforts"], [{"effort": "high", "count": 1}])

    def test_policy_revision_is_attached_without_reading_configuration(self) -> None:
        value = event("p1", "codex", "turn.started", thread="thread", turn="turn")

        normalized = audit.normalize(value, "revision-b")

        self.assertEqual(normalized["policy_revision"], "revision-b")

    def test_known_provider_artifacts_are_normalized(self) -> None:
        configured = event(
            "configured",
            "claudeAgent",
            "session.configured",
            thread="thread",
            payload={
                "status": "inProgress",
                "config": {"model": "claude-fable-5[1m]"},
            },
        )

        normalized = audit.normalize(configured)

        self.assertEqual(normalized["status"], "in_progress")
        self.assertEqual(normalized["model"], "claude-fable-5")
        self.assertEqual(normalized["scrubbed_fields"], [])

        malformed = event(
            "malformed",
            "codex",
            "turn.started",
            thread="thread",
            payload={"status": ["not", "a", "category"]},
        )
        malformed_normalized = audit.normalize(malformed)

        self.assertEqual(malformed_normalized["status"], "unknown")
        self.assertIn("status", malformed_normalized["scrubbed_fields"])

    def test_cli_defaults_to_stdout_and_does_not_write_source(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source = fixture(Path(temporary))
            before = sorted(path.name for path in source.iterdir())
            stdout = io.StringIO()
            with contextlib.redirect_stdout(stdout):
                status = audit.main(
                    ["summary", "--source", str(source), "--format", "json"]
                )
            after = sorted(path.name for path in source.iterdir())

        self.assertEqual(status, 0)
        self.assertEqual(before, after)
        self.assertEqual(json.loads(stdout.getvalue())["totals"]["threads"], 2)

    def test_cli_does_not_replace_existing_output_without_force(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = fixture(root)
            output = root / "report.json"
            output.write_text("keep\n", encoding="utf-8")
            stderr = io.StringIO()

            with contextlib.redirect_stderr(stderr), self.assertRaises(SystemExit):
                audit.main(
                    [
                        "summary",
                        "--source",
                        str(source),
                        "--format",
                        "json",
                        "--output",
                        str(output),
                    ]
                )

            self.assertEqual(output.read_text(encoding="utf-8"), "keep\n")
            self.assertIn("--force", stderr.getvalue())

    def test_force_rejects_hard_link_alias_of_source(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = fixture(root)
            source_file = source / "events.first.log"
            alias = root / "source-alias.log"
            alias.hardlink_to(source_file)
            before = source_file.read_bytes()
            stderr = io.StringIO()

            with contextlib.redirect_stderr(stderr), self.assertRaises(SystemExit):
                audit.main(
                    [
                        "events",
                        "--source",
                        str(source_file),
                        "--output",
                        str(alias),
                        "--force",
                    ]
                )

            self.assertEqual(source_file.read_bytes(), before)
            self.assertEqual(alias.read_bytes(), before)
            self.assertIn("aliases a source log", stderr.getvalue())

    def test_event_export_is_chronological_across_files(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source = Path(temporary)
            later = event(
                "later",
                "codex",
                "turn.started",
                thread="thread",
                turn="later",
                created_at="2026-08-27T13:00:00Z",
            )
            earlier = event(
                "earlier",
                "codex",
                "turn.started",
                thread="thread",
                turn="earlier",
                created_at="2026-08-27T11:00:00Z",
            )
            (source / "events.a.log").write_text(canonical(later), encoding="utf-8")
            (source / "events.z.log").write_text(canonical(earlier), encoding="utf-8")
            stdout = io.StringIO()

            with contextlib.redirect_stdout(stdout):
                audit.main(["events", "--source", str(source)])

        exported = [json.loads(line) for line in stdout.getvalue().splitlines()]
        self.assertEqual(
            [row["source_event_id"] for row in exported],
            [
                audit.opaque_identifier("earlier", "source_event_id", []),
                audit.opaque_identifier("later", "source_event_id", []),
            ],
        )

    def test_missing_ids_use_stable_deduplication_and_strict_rejects_them(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source = Path(temporary)
            value = event("temporary", "codex", "turn.started", thread="thread")
            del value["eventId"]
            (source / "events.a.log").write_text(canonical(value), encoding="utf-8")
            (source / "events.b.log").write_text(canonical(value), encoding="utf-8")

            _, stats, events = self.scan(source)
            self.assertEqual(len(events), 1)
            self.assertEqual(stats.missing_event_ids, 2)
            self.assertEqual(stats.duplicate_events, 1)
            with self.assertRaises(audit.AuditError):
                self.scan(source, strict=True)

    def test_strict_mode_rejects_truncated_canonical_json(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source = fixture(Path(temporary))
            with self.assertRaises(audit.AuditError):
                self.scan(source, strict=True)

    def test_strict_help_mentions_missing_event_ids(self) -> None:
        help_text = (
            audit.build_parser()
            ._subparsers._group_actions[0]
            .choices["events"]
            .format_help()
        )

        self.assertIn("missing event IDs", help_text)


if __name__ == "__main__":
    unittest.main()
