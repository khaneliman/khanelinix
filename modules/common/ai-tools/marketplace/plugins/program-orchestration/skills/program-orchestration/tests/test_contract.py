"""Contract tests for the explicit program-control overlay."""

from __future__ import annotations

import json
import unittest
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[1]
SKILL_MD = SKILL_ROOT / "SKILL.md"
REFERENCES = SKILL_ROOT / "references"
OPENAI = SKILL_ROOT / "agents" / "openai.yaml"
EVENT_SCHEMA = SKILL_ROOT / "schemas" / "event-v1.schema.json"
AI_TOOLS = SKILL_ROOT.parents[1]
CATALOG = AI_TOOLS / "marketplace" / "catalog.json"
AI_TOOLS_DEFAULT = AI_TOOLS / "default.nix"
CODEX_REQUIREMENTS = AI_TOOLS / "program-orchestration/codex/requirements.nix"
REPOSITORY_ROOT = AI_TOOLS.parents[2]
CLAUDE_HOOK = (
    REPOSITORY_ROOT
    / "modules/home/programs/terminal/tools/claude-code/hooks"
    / "program-orchestration.nix"
)
MAX_PLAYBOOK_LINES = 100
EVENT_TYPES = {
    "program_initialized",
    "unit_added",
    "unit_readied",
    "unit_blocked",
    "unit_unblocked",
    "unit_cancelled",
    "grant_recorded",
    "grant_revoked",
    "lease_acquired",
    "lease_renewed",
    "lease_reconciled",
    "occurrence_receipt_recorded",
    "handoff_receipt_recorded",
    "receipt_invalidated",
    "unit_landed",
    "unit_reopened",
    "program_paused",
    "program_resumed",
    "program_completed",
    "program_aborted",
}


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def normalized(path: Path) -> str:
    return " ".join(read(path).split()).lower()


class ProgramOrchestrationContract(unittest.TestCase):
    def test_root_playbook_stays_lean(self) -> None:
        self.assertLessEqual(len(read(SKILL_MD).splitlines()), MAX_PLAYBOOK_LINES)

    def test_codex_invocation_is_explicit_only(self) -> None:
        metadata = read(OPENAI)
        self.assertIn("allow_implicit_invocation: false", metadata)
        self.assertIn("$program-orchestration", metadata)

    def test_program_does_not_take_unit_lifecycle(self) -> None:
        text = normalized(SKILL_MD)
        self.assertIn("does not implement, verify, review, or commit a unit", text)
        self.assertIn("each unit names one existing lifecycle owner", text)
        self.assertIn("`verified-slice` evidence remains authoritative", text)

    def test_size_alone_never_selects_program(self) -> None:
        text = normalized(REFERENCES / "control-model.md")
        self.assertIn("must explicitly invoke", text)
        self.assertIn("does not satisfy this predicate alone", text)

    def test_control_states_are_not_lifecycle_phases(self) -> None:
        text = normalized(REFERENCES / "control-model.md")
        for state in (
            "planned",
            "ready",
            "leased",
            "landed",
            "blocked",
            "cancelled",
        ):
            self.assertIn(f"`{state}`", text)
        self.assertIn("not lifecycle phases", text)

    def test_grants_cannot_widen_host_permission(self) -> None:
        text = normalized(REFERENCES / "authority.md")
        self.assertIn("current host permits", text)
        self.assertIn("cannot prove current host permission", text)
        self.assertIn("do not infer one capability from another", text)

    def test_expired_lease_requires_reconciliation(self) -> None:
        text = normalized(REFERENCES / "authority.md")
        self.assertIn("expired lease still owns its scopes", text)
        self.assertIn("never transfer a lease automatically", text)

    def test_journal_is_canonical_and_recovery_is_non_destructive(self) -> None:
        control = normalized(REFERENCES / "control-model.md")
        recovery = normalized(REFERENCES / "recovery.md")
        self.assertIn("`journal.jsonl` is canonical", control)
        self.assertIn("recovery apply never modifies journal history", recovery)
        self.assertIn("never break `.state-lock`", recovery)

    def test_event_schema_closes_version_names_and_payloads(self) -> None:
        schema = json.loads(read(EVENT_SCHEMA))
        properties = schema["properties"]
        self.assertEqual(properties["schema_version"]["const"], 1)
        self.assertEqual(set(properties["event_type"]["enum"]), EVENT_TYPES)
        conditional_types = {
            item["if"]["properties"]["event_type"]["const"] for item in schema["allOf"]
        }
        self.assertEqual(conditional_types, EVENT_TYPES)
        for item in schema["allOf"]:
            payload = item["then"]["properties"]["payload"]
            definition = schema["$defs"][payload["$ref"].rsplit("/", 1)[1]]
            self.assertFalse(definition["additionalProperties"])
            self.assertTrue(
                set(definition["required"]).issubset(definition["properties"])
            )

    def test_human_event_map_matches_machine_registry(self) -> None:
        text = read(REFERENCES / "events-v1.md")
        for event_type in EVENT_TYPES:
            self.assertIn(f"`{event_type}`", text)

    def test_hooks_are_bounded_and_non_semantic(self) -> None:
        text = normalized(REFERENCES / "hook-contract.md")
        self.assertIn("limit emitted context to 4 kib", text)
        self.assertIn("must not", text)
        for forbidden in (
            "select or invoke a skill",
            "infer or grant permission",
            "repair state",
        ):
            self.assertIn(forbidden, text)

    def test_codex_and_claude_project_one_read_only_renderer(self) -> None:
        if not AI_TOOLS_DEFAULT.is_file():
            self.skipTest("provider adapters are not installed")
        codex = read(CODEX_REQUIREMENTS)
        default = read(AI_TOOLS_DEFAULT)
        claude = read(CLAUDE_HOOK)

        for event in ("SessionStart", "UserPromptSubmit"):
            self.assertIn(event, codex)
            self.assertIn(event, claude)
        self.assertIn("program_context.py codex session-start", codex)
        self.assertIn("program_context.py codex user-prompt", codex)
        self.assertIn("program_context.py claude ${event}", claude)
        self.assertIn('hook "session-start"', claude)
        self.assertIn('hook "user-prompt"', claude)
        self.assertIn("programOrchestration.codex.requirements", default)
        self.assertIn("program_context.py $out/program-orchestration/", default)
        self.assertIn("program_state.py $out/program-orchestration/", default)
        self.assertNotIn("Stop", codex)
        self.assertNotIn("PreToolUse", codex)
        self.assertNotIn("Stop", claude)
        self.assertNotIn("PreToolUse", claude)

    def test_marketplace_bundle_contains_program_overlay(self) -> None:
        if not CATALOG.is_file():
            self.skipTest("marketplace catalog is not installed")
        catalog = json.loads(read(CATALOG))
        published = {plugin["name"] for plugin in catalog["plugins"]}
        members = set(catalog["bundles"]["workflow-core"]["plugins"])
        self.assertIn("program-orchestration", published)
        self.assertIn("program-orchestration", members)


if __name__ == "__main__":
    unittest.main()
