from __future__ import annotations

import importlib.util
import io
import json
import os
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "scripts" / "audit_ai_tools.py"
SPEC = importlib.util.spec_from_file_location("audit_ai_tools", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
audit_ai_tools = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = audit_ai_tools
SPEC.loader.exec_module(audit_ai_tools)


def find_repository_skills() -> Path | None:
    """Return the repository skills tree that ships to every provider."""
    for candidate in Path(__file__).resolve().parents:
        if candidate.name != "ai-tools" or candidate.parent.name != "common":
            continue
        skills = candidate / "skills"
        if (skills / "ai-tools-architect" / "SKILL.md").is_file():
            return skills
    return None


REPOSITORY_SKILLS = find_repository_skills()


def write_skill(root: Path, name: str, body: str) -> Path:
    skill = root / name
    skill.mkdir(parents=True)
    (skill / "SKILL.md").write_text(
        f"---\nname: {name}\ndescription: Test {name}.\n---\n\n# Test\n\n{body}\n",
        encoding="utf-8",
    )
    return skill


def expected_summary(
    *, skills: int, errors: int, warnings: int, description_characters: int
) -> dict[str, int | bool]:
    return {
        "skills": skills,
        "errors": errors,
        "warnings": warnings,
        "description_characters": description_characters,
        "implicit_skills": skills,
        "explicit_only_skills": 0,
        "implicit_description_characters": description_characters,
        "implicit_description_budget": 7_000,
        "implicit_description_budget_exceeded": False,
    }


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
                report["summary"],
                expected_summary(
                    skills=1,
                    errors=0,
                    warnings=0,
                    description_characters=len("Test clean-skill."),
                ),
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
                report["summary"],
                expected_summary(
                    skills=1,
                    errors=2,
                    warnings=1,
                    description_characters=len("Test."),
                ),
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

    def test_unsupported_or_malformed_nested_frontmatter_is_rejected(self) -> None:
        cases = (
            "hooks:\n  Stop: value\n",
            'metadata:\n    version: "1"\n',
        )
        for extra in cases:
            with self.subTest(extra=extra), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                skill = root / "invalid-skill"
                skill.mkdir()
                (skill / "SKILL.md").write_text(
                    "---\n"
                    "name: invalid-skill\n"
                    "description: Invalid nested metadata.\n"
                    f"{extra}"
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
                report["summary"],
                expected_summary(
                    skills=1,
                    errors=0,
                    warnings=0,
                    description_characters=1024,
                ),
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
            (skill / "scripts" / "unused").write_text(
                "#!/usr/bin/env python3\n", encoding="utf-8"
            )

            report = audit_ai_tools.audit_root(root)
            codes = {finding["code"] for finding in report["findings"]}

            self.assertEqual(report["summary"]["errors"], 0)
            self.assertIn("orphan_resource", codes)
            self.assertIn("script_uninvoked", codes)
            self.assertIn("script_not_executable", codes)

    def test_interpreter_script_and_static_dependencies_do_not_need_exec_bits(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            skill = write_skill(
                root,
                "dependency-skill",
                "Run `python3 scripts/run.py`.\n",
            )
            scripts = skill / "scripts"
            scripts.mkdir()
            (scripts / "run.py").write_text(
                "#!/usr/bin/env python3\nfrom . import helper\n",
                encoding="utf-8",
            )
            (scripts / "helper.py").write_text("VALUE = 1\n", encoding="utf-8")
            (scripts / "__init__.py").write_text("", encoding="utf-8")
            (scripts / "requirements.txt").write_text("example==1\n", encoding="utf-8")

            report = audit_ai_tools.audit_root(root)

            self.assertEqual(
                report["summary"],
                expected_summary(
                    skills=1,
                    errors=0,
                    warnings=0,
                    description_characters=len("Test dependency-skill."),
                ),
            )

    def test_invocation_policy_controls_implicit_budget(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            implicit = write_skill(root, "implicit-skill", "Small body.")
            explicit = write_skill(root, "explicit-skill", "Small body.")
            for skill in (implicit, explicit):
                agents = skill / "agents"
                agents.mkdir()
                policy = (
                    "policy:\n  allow_implicit_invocation: false\n"
                    if skill == explicit
                    else ""
                )
                (agents / "openai.yaml").write_text(
                    "interface:\n"
                    f'  display_name: "{skill.name}"\n'
                    '  short_description: "Useful policy validation fixture"\n'
                    f'  default_prompt: "Use ${skill.name} for this fixture."\n'
                    f"{policy}",
                    encoding="utf-8",
                )

            report = audit_ai_tools.audit_root(root, implicit_description_budget=1)
            summary = report["summary"]

            self.assertEqual(summary["implicit_skills"], 1)
            self.assertEqual(summary["explicit_only_skills"], 1)
            self.assertEqual(
                summary["implicit_description_characters"],
                len("Test implicit-skill."),
            )
            self.assertTrue(summary["implicit_description_budget_exceeded"])
            records = {record["name"]: record for record in report["skills"]}
            self.assertTrue(records["implicit-skill"]["implicit_invocation"])
            self.assertFalse(records["explicit-skill"]["implicit_invocation"])

    def test_cli_rejects_default_implicit_budget_excess(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            lengths = [1_000] * 7 + [1]
            for index, length in enumerate(lengths):
                name = f"budget-skill-{index}"
                skill = root / name
                skill.mkdir()
                (skill / "SKILL.md").write_text(
                    f"---\nname: {name}\ndescription: {'x' * length}\n---\n\n# Test\n",
                    encoding="utf-8",
                )

            with redirect_stdout(io.StringIO()):
                result = audit_ai_tools.main([str(root), "--format", "json"])

            self.assertEqual(audit_ai_tools.DEFAULT_IMPLICIT_DESCRIPTION_BUDGET, 7_000)
            self.assertEqual(result, 1)

    def test_repository_skills_stay_within_implicit_budget(self) -> None:
        if REPOSITORY_SKILLS is None:
            self.skipTest(
                "repository skills tree is unavailable outside the khanelinix checkout"
            )

        summary = audit_ai_tools.audit_root(REPOSITORY_SKILLS)["summary"]
        total = summary["implicit_description_characters"]
        budget = summary["implicit_description_budget"]

        self.assertFalse(
            summary["implicit_description_budget_exceeded"],
            f"implicit descriptions total {total} characters against a "
            f"{budget} character budget, an overflow of {total - budget}; "
            "shorten implicit descriptions or make a skill explicit-only",
        )

    def test_invalid_invocation_policy_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            skill = write_skill(root, "policy-skill", "Small body.")
            agents = skill / "agents"
            agents.mkdir()
            (agents / "openai.yaml").write_text(
                "interface:\n"
                '  display_name: "Policy Skill"\n'
                '  short_description: "Useful policy validation fixture"\n'
                '  default_prompt: "Use $policy-skill for this fixture."\n'
                "policy:\n"
                "  allow_implicit_invocation: sometimes\n",
                encoding="utf-8",
            )

            report = audit_ai_tools.audit_root(root)

            self.assertEqual(report["summary"]["errors"], 1)
            self.assertEqual(report["findings"][0]["code"], "invalid_openai_metadata")

    def test_dependency_basename_substrings_do_not_hide_uninvoked_scripts(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            skill = write_skill(
                root,
                "collision-skill",
                "Run `python3 scripts/run.py`.",
            )
            scripts = skill / "scripts"
            scripts.mkdir()
            (scripts / "run.py").write_text(
                "# helper.py.bak is not a dependency\n", encoding="utf-8"
            )
            (scripts / "helper.py").write_text("VALUE = 1\n", encoding="utf-8")

            report = audit_ai_tools.audit_root(root)
            uninvoked = [
                finding
                for finding in report["findings"]
                if finding["code"] == "script_uninvoked"
            ]

            self.assertEqual(len(uninvoked), 1)
            self.assertTrue(uninvoked[0]["path"].endswith("scripts/helper.py"))

    def test_openai_metadata_schema_and_assets_are_validated(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            skill = write_skill(root, "metadata-skill", "Small body.")
            agents = skill / "agents"
            agents.mkdir()
            (agents / "openai.yaml").write_text(
                "interface:\n"
                '  display_name: "Metadata Skill"\n'
                '  short_description: "Useful metadata validation fixture"\n'
                '  icon_small: "./assets/missing.svg"\n'
                '  default_prompt: "Use this fixture."\n',
                encoding="utf-8",
            )

            report = audit_ai_tools.audit_root(root)
            codes = {finding["code"] for finding in report["findings"]}

            self.assertIn("invalid_openai_metadata", codes)
            self.assertIn("missing_openai_asset", codes)

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

    def test_variant_references_within_one_skill_do_not_warn_as_duplicates(
        self,
    ) -> None:
        duplicate = (
            "This deliberately long paragraph describes shared variant behavior while the "
            "root playbook routes only one provider-specific reference for each request."
        )
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            skill = write_skill(
                root,
                "variant-skill",
                "Choose [Python](references/python.md) or "
                "[Node](references/node.md), then read only that variant.",
            )
            references = skill / "references"
            references.mkdir()
            (references / "python.md").write_text(duplicate, encoding="utf-8")
            (references / "node.md").write_text(duplicate, encoding="utf-8")

            report = audit_ai_tools.audit_root(root, minimum_duplicate_characters=80)

            self.assertNotIn(
                "duplicate_block",
                {finding["code"] for finding in report["findings"]},
            )

    def test_directly_coloaded_references_still_warn_as_duplicates(self) -> None:
        duplicate = (
            "This deliberately long paragraph repeats guidance in two references that "
            "directly load one another during the same skill workflow and waste context."
        )
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            skill = write_skill(
                root,
                "coloaded-skill",
                "Read [first](references/first.md).",
            )
            references = skill / "references"
            references.mkdir()
            (references / "first.md").write_text(
                duplicate + "\n\nRead [second](second.md).\n",
                encoding="utf-8",
            )
            (references / "second.md").write_text(duplicate, encoding="utf-8")

            report = audit_ai_tools.audit_root(root, minimum_duplicate_characters=80)

            self.assertIn(
                "duplicate_block",
                {finding["code"] for finding in report["findings"]},
            )

    def test_json_and_markdown_outputs_are_stable(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write_skill(root, "clean-skill", "Small body.")
            report = audit_ai_tools.audit_root(root)

            encoded = json.dumps(report, sort_keys=True)
            markdown = audit_ai_tools.render_markdown(report)

            self.assertEqual(json.loads(encoded)["summary"]["skills"], 1)
            self.assertIn("# AI Tools Audit", markdown)
            self.assertIn("Implicit description budget:", markdown)
            self.assertIn("No findings.", markdown)


if __name__ == "__main__":
    unittest.main()
