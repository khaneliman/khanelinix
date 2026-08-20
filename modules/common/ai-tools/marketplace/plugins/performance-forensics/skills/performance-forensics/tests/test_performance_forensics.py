"""Contract tests for the canonical performance-forensics skill package."""

from __future__ import annotations

import hashlib
import re
import unittest
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[1]
SKILL_MD = SKILL_ROOT / "SKILL.md"
REFERENCES = SKILL_ROOT / "references"
LICENSE = SKILL_ROOT / "LICENSE"
OPENAI_METADATA = SKILL_ROOT / "agents" / "openai.yaml"

LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
SUPPORTED_FRONTMATTER_FIELDS = {"description", "license", "metadata", "name"}
MAX_DESCRIPTION_CHARACTERS = 512
MAX_PLAYBOOK_LINES = 100


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def split_frontmatter(content: str) -> tuple[dict[str, str], str]:
    lines = content.splitlines()
    if not lines or lines[0].strip() != "---":
        raise AssertionError("SKILL.md must open with a frontmatter fence")
    end = next(
        index for index, line in enumerate(lines[1:], start=1) if line.strip() == "---"
    )
    fields: dict[str, str] = {}
    for line in lines[1:end]:
        if not line.strip():
            continue
        key, separator, value = line.partition(":")
        if not separator:
            raise AssertionError(f"unparsable frontmatter line: {line}")
        fields[key.strip()] = value.strip()
    return fields, "\n".join(lines[end + 1 :])


def markdown_targets(path: Path) -> list[str]:
    return [
        target.split("#", 1)[0].strip()
        for target in LINK_RE.findall(read(path))
        if not target.startswith(("http://", "https://", "mailto:"))
    ]


class PerformanceForensicsFrontmatterContract(unittest.TestCase):
    def setUp(self) -> None:
        self.fields, self.body = split_frontmatter(read(SKILL_MD))

    def test_name_is_performance_forensics(self) -> None:
        self.assertEqual(self.fields.get("name"), "performance-forensics")

    def test_only_supported_fields_are_declared(self) -> None:
        self.assertTrue(set(self.fields).issubset(SUPPORTED_FRONTMATTER_FIELDS))

    def test_description_stays_within_budget(self) -> None:
        description = self.fields.get("description", "")
        self.assertTrue(description)
        self.assertLessEqual(len(description), MAX_DESCRIPTION_CHARACTERS)

    def test_description_names_triggers_and_scope(self) -> None:
        description = self.fields["description"].lower()
        for trigger in (
            "latency",
            "cpu",
            "throughput",
            "traces",
            "hillclimbing",
            "memory-profiler",
        ):
            self.assertIn(trigger, description)

    def test_playbook_stays_under_line_budget(self) -> None:
        self.assertLess(len(read(SKILL_MD).splitlines()), MAX_PLAYBOOK_LINES)


class PerformanceForensicsPlaybookContract(unittest.TestCase):
    def setUp(self) -> None:
        _, self.body = split_frontmatter(read(SKILL_MD))

    def test_all_referenced_files_exist(self) -> None:
        for md_path in [SKILL_MD, *REFERENCES.glob("*.md")]:
            for target in markdown_targets(md_path):
                if not target:
                    continue
                target_path = (md_path.parent / target).resolve()
                self.assertTrue(
                    target_path.exists(),
                    f"broken link from {md_path} to {target}",
                )

    def test_declares_read_only_diagnosis_default(self) -> None:
        lowered = " ".join(self.body.lower().split())
        self.assertIn("read-only by default", lowered)
        self.assertIn("do not mutate production code during diagnosis", lowered)

    def test_defers_memory_leaks_to_memory_profiler(self) -> None:
        lowered = self.body.lower()
        self.assertIn("memory-profiler", lowered)
        self.assertIn("memory leaks", lowered)
        self.assertIn("heap fragmentation", lowered)

    def test_declares_measurement_loop_requirements(self) -> None:
        lowered = self.body.lower()
        self.assertIn("realistic workload", lowered)
        self.assertIn("baseline", lowered)
        self.assertIn("single hypothesis", lowered)
        self.assertIn("isolated change", lowered)
        self.assertIn("post-fix", lowered)
        self.assertIn("inconclusive", lowered)

    def test_reporting_contract_fields(self) -> None:
        lowered = self.body.lower()
        self.assertIn("baseline artifact", lowered)
        self.assertIn("post-fix measurement number and artifact path", lowered)
        self.assertIn("net delta", lowered)
        self.assertIn("inconclusive", lowered)


class PerformanceForensicsReferencesContract(unittest.TestCase):
    def test_perf_issue_eight_strategy_families(self) -> None:
        content = read(REFERENCES / "perf-issue.md").lower()
        for family in (
            "elimination",
            "divide and conquer",
            "caching",
            "indirection",
            "batching",
            "redundancy",
            "lazy evaluation",
            "scheduling",
        ):
            self.assertIn(family, content)

    def test_hillclimb_rules_and_discipline(self) -> None:
        content = read(REFERENCES / "hillclimb.md").lower()
        self.assertIn("freeze the harness", content)
        self.assertIn("one change per iteration", content)
        self.assertIn("keep or restore", content)
        self.assertIn("stop predicate", content)
        self.assertIn("handle plateaus", content)

    def test_runtime_forensics_live_diagnostics(self) -> None:
        content = read(REFERENCES / "runtime-forensics.md").lower()
        self.assertIn("read-only by default", content)
        self.assertIn("cpu profile", content)
        self.assertIn("thread dump", content)
        self.assertIn("prove the mechanism", content)
        self.assertIn("source file", content)

    def test_trace_forensics_offline_analysis(self) -> None:
        content = read(REFERENCES / "trace-forensics.md").lower()
        self.assertIn(".cpuprofile", content)
        self.assertIn("spindump", content)
        self.assertIn("sqlite", content)
        self.assertIn("call tree", content)
        self.assertIn("paired capture", content)
        self.assertIn("inconclusive", content)


class PerformanceForensicsLicenseContract(unittest.TestCase):
    def test_pstack_license_matches(self) -> None:
        self.assertEqual(
            hashlib.sha256(LICENSE.read_bytes()).hexdigest(),
            "bc957ca6bee02792566a1a028d105e02e247c6e77cf057061674273da77b200e",
        )


class PerformanceForensicsOpenAIMetadataContract(unittest.TestCase):
    def setUp(self) -> None:
        content = read(OPENAI_METADATA)
        self.values: dict[str, str] = {}
        for line in content.splitlines():
            match = re.match(r'^\s{2}([a-z_]+):\s*"(.*)"\s*$', line)
            if match:
                self.values[match.group(1)] = match.group(2)

    def test_interface_mapping_exists(self) -> None:
        self.assertEqual(
            set(self.values),
            {"default_prompt", "display_name", "short_description"},
        )

    def test_short_description_budget(self) -> None:
        self.assertTrue(25 <= len(self.values["short_description"]) <= 64)

    def test_default_prompt_invokes_skill(self) -> None:
        self.assertIn("$performance-forensics", self.values["default_prompt"])


if __name__ == "__main__":
    unittest.main()
