from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "scripts" / "style_guard.py"
SPEC = importlib.util.spec_from_file_location("style_guard", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
STYLE_GUARD = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = STYLE_GUARD
SPEC.loader.exec_module(STYLE_GUARD)


class StyleGuardTests(unittest.TestCase):
    def run_hook(self, provider: str, payload: dict[str, object]) -> dict[str, object]:
        result = subprocess.run(
            [sys.executable, "-B", str(SCRIPT), "hook", provider],
            input=json.dumps(payload),
            text=True,
            capture_output=True,
            check=True,
        )
        return json.loads(result.stdout)

    def test_supplied_phrase_variants_are_blocked(self) -> None:
        text = "Honestly load bearing belt-and-suspenders blast radius"
        policy_ids = {item["policy_id"] for item in STYLE_GUARD.style_violations(text)}
        self.assertEqual(
            policy_ids, {"phrase-01", "phrase-02", "phrase-03", "phrase-04"}
        )

    def test_canned_phrases_emoji_and_dash_are_blocked(self) -> None:
        text = "A seamless tapestry \N{EM DASH} \N{ROCKET}"
        kinds = {item["kind"] for item in STYLE_GUARD.style_violations(text)}
        self.assertEqual(kinds, {"blocked-phrase", "emoji", "unicode-dash"})

    def test_emoji_presentation_does_not_block_plain_check_marks(self) -> None:
        plain_symbols = "Tests \u2713; lint \u2717; flags \U0001f3f3; desktop \U0001f5a5; weather \U0001f324."
        self.assertEqual(STYLE_GUARD.style_violations(plain_symbols), [])
        for text in ("\u2714\ufe0f", "\N{ROCKET}", "\U0001f004", "\U0001f170\ufe0f"):
            with self.subTest(text=text):
                kinds = {item["kind"] for item in STYLE_GUARD.style_violations(text)}
                self.assertIn("emoji", kinds)

    def test_sycophancy_phrases_are_blocked(self) -> None:
        text = (
            "Great question. That makes a lot of sense. "
            "You are absolutely right. Definitely."
        )
        policy_ids = {item["policy_id"] for item in STYLE_GUARD.style_violations(text)}
        self.assertEqual(
            policy_ids,
            {"phrase-18", "phrase-19", "phrase-20", "phrase-21"},
        )

    def test_plain_technical_text_passes(self) -> None:
        self.assertEqual(
            STYLE_GUARD.style_violations(
                "The hook validates final output before the provider stops."
            ),
            [],
        )

    def test_claude_hook_blocks_direct_message(self) -> None:
        output = self.run_hook(
            "claude", {"last_assistant_message": "This is honestly complete."}
        )
        self.assertEqual(output["decision"], "block")

    def test_claude_hook_allows_clean_message(self) -> None:
        self.assertEqual(
            self.run_hook("claude", {"last_assistant_message": "Tests pass."}),
            {},
        )

    def test_stop_retry_is_allowed(self) -> None:
        self.assertEqual(
            self.run_hook(
                "claude",
                {
                    "last_assistant_message": "A game changer.",
                    "stop_hook_active": True,
                },
            ),
            {},
        )

    def test_codex_hook_reads_transcript(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            transcript = Path(temporary) / "codex.jsonl"
            transcript.write_text(
                json.dumps(
                    {
                        "type": "response_item",
                        "payload": {
                            "type": "message",
                            "role": "assistant",
                            "content": [
                                {"type": "output_text", "text": "A game changer."}
                            ],
                        },
                    }
                )
                + "\n",
                encoding="utf-8",
            )
            output = self.run_hook("codex", {"transcript_path": str(transcript)})
            self.assertEqual(output["decision"], "block")

    def test_codex_subagent_is_exempt(self) -> None:
        output = self.run_hook(
            "codex",
            {
                "source": {"subagent": {"thread_spawn": {}}},
                "last_assistant_message": "A paradigm shift.",
            },
        )
        self.assertEqual(output, {})

    def test_codex_subagent_transcript_head_is_exempt(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            transcript = Path(temporary) / "codex.jsonl"
            records = [
                {
                    "type": "session_meta",
                    "payload": {"source": {"subagent": {"thread_spawn": {}}}},
                },
                {"type": "noise", "payload": "x" * (4 * 1024 * 1024 + 1024)},
                {
                    "type": "event_msg",
                    "payload": {
                        "type": "agent_message",
                        "message": "A paradigm shift.",
                    },
                },
            ]
            transcript.write_text(
                "".join(json.dumps(record) + "\n" for record in records),
                encoding="utf-8",
            )
            output = self.run_hook("codex", {"transcript_path": str(transcript)})
            self.assertEqual(output, {})

    def test_corrupt_transcript_head_fails_open(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            transcript = Path(temporary) / "corrupt.jsonl"
            transcript.write_bytes(b"\xff\n")
            output = self.run_hook("codex", {"transcript_path": str(transcript)})
            self.assertEqual(output, {})

    def test_claude_sidechain_message_is_ignored(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            transcript = Path(temporary) / "claude.jsonl"
            records = [
                {
                    "type": "assistant",
                    "message": {
                        "role": "assistant",
                        "content": [{"type": "text", "text": "Tests pass."}],
                    },
                },
                {
                    "type": "assistant",
                    "isSidechain": True,
                    "message": {
                        "role": "assistant",
                        "content": [{"type": "text", "text": "A game changer."}],
                    },
                },
            ]
            transcript.write_text(
                "".join(json.dumps(record) + "\n" for record in records),
                encoding="utf-8",
            )
            output = self.run_hook("claude", {"transcript_path": str(transcript)})
            self.assertEqual(output, {})

    def test_antigravity_uses_provider_decisions(self) -> None:
        blocked = self.run_hook(
            "antigravity", {"last_assistant_message": "A testament to work."}
        )
        self.assertEqual(blocked["decision"], "continue")
        allowed = self.run_hook(
            "antigravity", {"last_assistant_message": "Validation passed."}
        )
        self.assertEqual(allowed, {"decision": "stop"})

    def test_valid_commit_message_passes(self) -> None:
        message = (
            "feat(ai-tools): add style guard\n\n"
            "Reject measurable output markers before provider delivery.\n"
        )
        self.assertEqual(STYLE_GUARD.commit_errors(message), [])

    def test_commit_limits_and_body_are_enforced(self) -> None:
        subject = "feat(ai-tools): " + "x" * 40
        errors = STYLE_GUARD.commit_errors(subject + "\n")
        self.assertTrue(any("limit is 50" in error for error in errors))
        self.assertIn("add a blank line and a commit body", errors)

    def test_fixup_subject_keeps_structure_exemption(self) -> None:
        self.assertEqual(
            STYLE_GUARD.commit_errors("fixup! feat(ai-tools): add style guard\n"),
            [],
        )

    def test_revert_subject_keeps_style_exemption(self) -> None:
        self.assertEqual(
            STYLE_GUARD.commit_errors(
                'Revert "feat(ai-tools): seamless integration"\n'
            ),
            [],
        )

    def test_commit_scissors_content_is_ignored(self) -> None:
        message = (
            "feat(ai-tools): add style guard\n\n"
            "Reject measurable markers.\n"
            "# ------------------------ >8 ------------------------\n"
            "+ definitely unrelated diff text\n"
        )
        self.assertEqual(STYLE_GUARD.commit_errors(message), [])

    def test_trailer_shaped_body_line_obeys_limit(self) -> None:
        message = f"feat(ai-tools): add style guard\n\nNote: {'x' * 80}\n"
        errors = STYLE_GUARD.commit_errors(message)
        self.assertTrue(any("line 3" in error for error in errors))

    def test_known_trailing_git_fields_do_not_use_prose_budget(self) -> None:
        message = (
            "feat(ai-tools): add style guard\n\n"
            "Keep commit history useful.\n\n"
            "Co-authored-by: Contributor With Long Name "
            "<contributor.with.a.long.address@example.com>\n"
            "Signed-off-by: Maintainer <maintainer@example.com>\n"
        )
        self.assertEqual(STYLE_GUARD.commit_errors(message), [])

    def test_scope_is_required(self) -> None:
        errors = STYLE_GUARD.commit_errors(
            "feat: add style guard\n\nExplain the reason.\n"
        )
        self.assertIn(
            "subject must use an approved scoped Conventional Commit form", errors
        )

    def test_score_detects_loss_and_preserves_tables(self) -> None:
        source = (
            "The service waits 30 seconds.\n\n"
            "| Item | Limit |\n| --- | --- |\n| A | 30 s |\n"
        )
        candidate = "The service waits.\n"
        report = STYLE_GUARD.score_rewrite(
            source,
            candidate,
            mode="descriptive",
            minimum_retention=0.85,
            required_facts=[],
        )
        self.assertFalse(report["passed"])
        self.assertLess(report["number_retention"], 1.0)
        self.assertLess(report["tables_preserved"], 1.0)

    def test_score_accepts_loss_free_sentence_split(self) -> None:
        source = "The service validates the configuration and writes the exact result."
        candidate = (
            "The service validates the configuration. It writes the exact result."
        )
        report = STYLE_GUARD.score_rewrite(
            source,
            candidate,
            mode="descriptive",
            minimum_retention=0.85,
            required_facts=[],
        )
        self.assertTrue(report["passed"])

    def test_score_normalizes_number_unit_spelling(self) -> None:
        source = "Wait 30 seconds."
        candidate = "Wait 30s."
        self.assertEqual(
            STYLE_GUARD.counter_retention(
                STYLE_GUARD.NUMBER_RE.findall(source),
                STYLE_GUARD.NUMBER_RE.findall(candidate),
            ),
            1.0,
        )

    def test_code_tokens_do_not_count_fenced_inline_syntax_twice(self) -> None:
        text = "```sh\necho `value`\n```\n\nUse `value`."
        self.assertEqual(
            STYLE_GUARD.code_tokens(text),
            ["```sh\necho `value`\n```", "value"],
        )

    def test_score_rejects_deleted_tilde_fence(self) -> None:
        prose = (
            "The service validates configuration values and retains every "
            "documented constraint."
        )
        source = f"{prose}\n\n~~~~sh\nprintf value\n~~~~"
        report = STYLE_GUARD.score_rewrite(
            source,
            prose,
            mode="descriptive",
            minimum_retention=0.85,
            required_facts=[],
        )
        self.assertEqual(report["code_retention"], 0.0)
        self.assertFalse(report["passed"])

    def test_inline_pipe_sentence_is_measured(self) -> None:
        text = "Use `left | right` with " + " ".join(["word"] * 25) + "."
        sentences = STYLE_GUARD.markdown_sentences(text)
        self.assertEqual(len(sentences), 1)
        self.assertGreater(len(STYLE_GUARD.WORD_RE.findall(sentences[0])), 25)

    def test_inline_pipe_after_table_is_not_part_of_table(self) -> None:
        source = (
            "Name | Value\n"
            "--- | ---\n"
            "alpha | one\n"
            "Use `left | right` for the next command."
        )
        candidate = source.replace("next command", "following command")
        self.assertEqual(
            STYLE_GUARD.table_blocks(source),
            ["Name | Value\n--- | ---\nalpha | one"],
        )
        self.assertEqual(
            STYLE_GUARD.table_blocks(source), STYLE_GUARD.table_blocks(candidate)
        )


if __name__ == "__main__":
    unittest.main()
