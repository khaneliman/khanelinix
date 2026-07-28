from __future__ import annotations

import importlib.util
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "scripts" / "audit_ai_tools.py"
SPEC = importlib.util.spec_from_file_location("audit_ai_tools", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
audit_ai_tools = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = audit_ai_tools
SPEC.loader.exec_module(audit_ai_tools)


def write_skill(root: Path, name: str, body: str) -> Path:
    skill = root / name
    skill.mkdir(parents=True)
    (skill / "SKILL.md").write_text(
        f"---\nname: {name}\ndescription: Test {name}.\n---\n\n# Test\n\n{body}\n",
        encoding="utf-8",
    )
    return skill


class AuditAiToolsTests(unittest.TestCase):
    def test_clean_linked_skill(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            skill = write_skill(
                root,
                "clean-skill",
                "Read [guide](references/guide.md). Run `<skill-dir>/scripts/run.py`.",
            )
            (skill / "references").mkdir()
            (skill / "references" / "guide.md").write_text(
                "# Guide\n", encoding="utf-8"
            )
            (skill / "scripts").mkdir()
            script = skill / "scripts" / "run.py"
            script.write_text(
                "#!/usr/bin/env python3\nfrom _helper import message\nprint(message)\n",
                encoding="utf-8",
            )
            os.chmod(script, 0o755)
            (skill / "scripts" / "_helper.py").write_text(
                "message = 'ok'\n", encoding="utf-8"
            )

            report = audit_ai_tools.audit_root(root)

            self.assertEqual(
                report["summary"], {"skills": 1, "errors": 0, "warnings": 0}
            )

    def test_ai_tools_root_prefers_canonical_skills_directory(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write_skill(root / "skills", "canonical-skill", "Canonical body.")
            write_skill(
                root / "provider-cache" / "nested",
                "generated-copy",
                "Generated provider copy.",
            )

            report = audit_ai_tools.audit_root(root)

            self.assertEqual(report["summary"]["skills"], 1)
            self.assertEqual(report["root"], str((root / "skills").resolve()))
            self.assertEqual(report["skills"][0]["name"], "canonical-skill")

    def test_objective_structure_findings(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            skill = root / "wrong-directory"
            skill.mkdir()
            (skill / "SKILL.md").write_text(
                "---\nname: other-name\ndescription: Test.\n---\n\n"
                "# One\n\n[missing](references/missing.md)\n",
                encoding="utf-8",
            )

            report = audit_ai_tools.audit_root(root, line_budget=5)
            codes = {finding["code"] for finding in report["findings"]}

            self.assertIn("name_path_mismatch", codes)
            self.assertIn("playbook_line_budget", codes)
            self.assertIn("broken_local_link", codes)
            self.assertEqual(
                report["summary"], {"skills": 1, "errors": 2, "warnings": 1}
            )

    def test_malformed_or_non_string_required_frontmatter_is_rejected(self) -> None:
        invalid_values = ("[unterminated", "{value: mapping}", "null", '"unterminated')
        for value in invalid_values:
            with self.subTest(value=value), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                skill = root / "invalid-skill"
                skill.mkdir()
                (skill / "SKILL.md").write_text(
                    "---\n"
                    "name: invalid-skill\n"
                    f"description: {value}\n"
                    "---\n\n# Invalid\n",
                    encoding="utf-8",
                )

                report = audit_ai_tools.audit_root(root)

                self.assertEqual(report["summary"]["errors"], 1)
                self.assertEqual(report["findings"][0]["code"], "invalid_frontmatter")

    def test_open_standard_name_and_description_limits_are_enforced(self) -> None:
        cases = (
            ("test-skill", "Invalid_Name", "Valid description.", "invalid_name"),
            ("test-skill", "double--hyphen", "Valid description.", "invalid_name"),
            ("test-skill", "-leading", "Valid description.", "invalid_name"),
            ("test-skill", "trailing-", "Valid description.", "invalid_name"),
            ("test-skill", "a" * 65, "Valid description.", "invalid_name"),
            ("valid-name", "valid-name", "x" * 1025, "description_too_long"),
        )
        for directory, name, description, expected_code in cases:
            with self.subTest(name=name), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                skill = root / directory
                skill.mkdir()
                (skill / "SKILL.md").write_text(
                    "---\n"
                    f"name: {name}\n"
                    f"description: {json.dumps(description)}\n"
                    "---\n\n# Invalid\n",
                    encoding="utf-8",
                )

                report = audit_ai_tools.audit_root(root)
                error_codes = [
                    finding["code"]
                    for finding in report["findings"]
                    if finding["severity"] == "error"
                ]

                self.assertEqual(report["summary"]["errors"], 1)
                self.assertEqual(error_codes, [expected_code])

    def test_open_standard_name_and_description_boundaries_pass(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            name = "a" * 64
            skill = root / name
            skill.mkdir()
            (skill / "SKILL.md").write_text(
                "---\n"
                f"name: {name}\n"
                f"description: {json.dumps('x' * 1024)}\n"
                "---\n\n# Valid\n",
                encoding="utf-8",
            )

            report = audit_ai_tools.audit_root(root)

            self.assertEqual(
                report["summary"], {"skills": 1, "errors": 0, "warnings": 0}
            )

    def test_multiline_description_limit_uses_parsed_block_value(self) -> None:
        descriptions = (
            ("a" * 512, "b" * 511, 0),
            ("a" * 512, "b" * 512, 1),
        )
        for first, second, expected_errors in descriptions:
            with (
                self.subTest(expected_errors=expected_errors),
                tempfile.TemporaryDirectory() as temporary,
            ):
                root = Path(temporary)
                skill = root / "block-description"
                skill.mkdir()
                (skill / "SKILL.md").write_text(
                    "---\n"
                    "name: block-description\n"
                    "description: >-\n"
                    f"  {first}\n"
                    f"  {second}\n"
                    "---\n\n# Block Description\n",
                    encoding="utf-8",
                )

                report = audit_ai_tools.audit_root(root)

                self.assertEqual(report["summary"]["errors"], expected_errors)
                error_codes = {
                    finding["code"]
                    for finding in report["findings"]
                    if finding["severity"] == "error"
                }
                self.assertEqual(
                    error_codes,
                    {"description_too_long"} if expected_errors else set(),
                )

    def test_folded_description_preserves_more_indented_breaks(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            skill_file = Path(temporary) / "SKILL.md"
            skill_file.write_text(
                "---\n"
                "name: folded-description\n"
                "description: >-\n"
                "  alpha\n"
                "\n"
                "    code\n"
                "---\n\n# Folded Description\n",
                encoding="utf-8",
            )

            frontmatter, error = audit_ai_tools.parse_frontmatter(skill_file)

            self.assertIsNone(error)
            self.assertEqual(frontmatter["description"], "alpha\n\n  code")

    def test_indented_frontmatter_boundary_is_block_content(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            skill_file = Path(temporary) / "SKILL.md"
            skill_file.write_text(
                "---\n"
                "name: boundary-description\n"
                "description: |-\n"
                "  ---\n"
                "---\n\n# Boundary Description\n",
                encoding="utf-8",
            )

            frontmatter, error = audit_ai_tools.parse_frontmatter(skill_file)

            self.assertIsNone(error)
            self.assertEqual(frontmatter["description"], "---")

    def test_orphan_and_non_executable_script_are_warnings(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            skill = write_skill(root, "warning-skill", "No resources are routed.")
            (skill / "references").mkdir()
            (skill / "references" / "orphan.md").write_text(
                "# Orphan\n", encoding="utf-8"
            )
            (skill / "scripts").mkdir()
            (skill / "scripts" / "unused.py").write_text(
                "#!/usr/bin/env python3\n", encoding="utf-8"
            )

            report = audit_ai_tools.audit_root(root)
            codes = {finding["code"] for finding in report["findings"]}

            self.assertEqual(report["summary"]["errors"], 0)
            self.assertIn("orphan_resource", codes)
            self.assertIn("script_uninvoked", codes)
            self.assertIn("script_not_executable", codes)

    def test_exact_normalized_duplicate_blocks_warn(self) -> None:
        duplicate = (
            "This deliberately long paragraph repeats exact architectural guidance across "
            "multiple skill files so duplicate detection has enough stable content to compare."
        )
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write_skill(root, "first-skill", duplicate)
            write_skill(root, "second-skill", "  ".join(duplicate.split()))

            report = audit_ai_tools.audit_root(root, minimum_duplicate_characters=80)
            duplicates = [
                finding
                for finding in report["findings"]
                if finding["code"] == "duplicate_block"
            ]

            self.assertEqual(len(duplicates), 1)
            self.assertEqual(duplicates[0]["severity"], "warning")
            self.assertEqual(report["summary"]["errors"], 0)

    def test_json_and_markdown_outputs_are_stable(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write_skill(root, "clean-skill", "Small body.")
            report = audit_ai_tools.audit_root(root)

            encoded = json.dumps(report, sort_keys=True)
            markdown = audit_ai_tools.render_markdown(report)

            self.assertEqual(json.loads(encoded)["summary"]["skills"], 1)
            self.assertIn("# AI Tools Audit", markdown)
            self.assertIn("No findings.", markdown)


if __name__ == "__main__":
    unittest.main()
