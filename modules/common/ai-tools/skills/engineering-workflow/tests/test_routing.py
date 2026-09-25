"""Contract tests for the engineering-workflow skill package."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[1]
AI_TOOLS_ROOT = SKILL_ROOT.parents[1]
SKILL_MD = SKILL_ROOT / "SKILL.md"
REFERENCES = SKILL_ROOT / "references"
LICENSE = SKILL_ROOT / "LICENSE"
OPENAI_METADATA = SKILL_ROOT / "agents" / "openai.yaml"
BASE_MD = AI_TOOLS_ROOT / "base.md"
MULTI_PROVIDER_ROOT = SKILL_ROOT.parent / "multi-provider-sdlc"
SWARM_ROOT = SKILL_ROOT.parent / "swarm"
CATALOG = AI_TOOLS_ROOT / "marketplace" / "catalog.json"
GENERAL_AGENTS = AI_TOOLS_ROOT / "agents" / "general"
SHARED_WORKER_CORE = AI_TOOLS_ROOT / "agents" / "shared" / "worker-core.md"
REVIEW_CONTRACT = (
    SKILL_ROOT.parent / "engineering-principles" / "references" / "premise-review.md"
)

LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
SUPPORTED_FRONTMATTER_FIELDS = {"description", "license", "metadata", "name"}
MAX_DESCRIPTION_CHARACTERS = 512
MAX_PLAYBOOK_LINES = 100
PROGRAM_SCALE_PREDICATE = (
    "Program-scale means any large, cross-cutting, or unattended run, including "
    "multiple independent cutovers, repositories, systems, or teams."
)


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def normalized(path: Path) -> str:
    return " ".join(read(path).split())


def compact(content: str) -> str:
    return " ".join(content.split())


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


class FrontmatterContract(unittest.TestCase):
    def setUp(self) -> None:
        self.fields, self.body = split_frontmatter(read(SKILL_MD))

    def test_name_is_engineering_workflow(self) -> None:
        self.assertEqual(self.fields.get("name"), "engineering-workflow")

    def test_only_supported_fields_are_declared(self) -> None:
        self.assertTrue(set(self.fields).issubset(SUPPORTED_FRONTMATTER_FIELDS))

    def test_description_stays_within_budget(self) -> None:
        description = self.fields.get("description", "")
        self.assertTrue(description)
        self.assertLessEqual(len(description), MAX_DESCRIPTION_CHARACTERS)



    def test_playbook_stays_under_line_budget(self) -> None:
        self.assertLess(len(read(SKILL_MD).splitlines()), MAX_PLAYBOOK_LINES)


class PlaybookContract(unittest.TestCase):
    def setUp(self) -> None:
        _, self.body = split_frontmatter(read(SKILL_MD))








    def test_declares_external_write_fences(self) -> None:
        lowered = self.body.lower()
        for fence in ("commit", "push", "merge", "publish", "deploy", "pull request"):
            self.assertIn(fence, lowered)

    def test_local_commit_authority_does_not_grant_remote_writes(self) -> None:
        authority = self.body.split("## Scope and Authority", maxsplit=1)[1].split(
            "## Completion", maxsplit=1
        )[0]
        self.assertIn("local-commit authority from the current request or standing user policy", authority)
        self.assertIn("implies no authority", authority)
        for capability in ("push", "merge", "publish", "deploy", "pull request"):
            self.assertIn(capability, authority)

    def test_parent_retains_final_authority(self) -> None:
        lowered = self.body.lower()
        self.assertIn("final judgment", lowered)
        self.assertIn("architecture acceptance", lowered)



class ReferenceReachability(unittest.TestCase):
    def test_required_references_exist(self) -> None:
        for name in (
            "task-shapes.md",
            "delegation.md",
            "gates.md",
            "modernization.md",
        ):
            self.assertTrue((REFERENCES / name).is_file(), name)

    def test_every_local_link_resolves(self) -> None:
        documents = [SKILL_MD, *sorted(REFERENCES.glob("*.md"))]
        for document in documents:
            for target in markdown_targets(document):
                resolved = (document.parent / target).resolve()
                self.assertTrue(resolved.exists(), f"{document.name} -> {target}")

    def test_playbook_links_each_reference(self) -> None:
        targets = set(markdown_targets(SKILL_MD))
        for name in ("task-shapes.md", "delegation.md", "gates.md"):
            self.assertIn(f"references/{name}", targets)


class GatesContract(unittest.TestCase):
    def setUp(self) -> None:
        self.text = read(REFERENCES / "gates.md").lower()

    def test_declares_risk_levels(self) -> None:
        for level in ("trivial", "normal", "high"):
            self.assertIn(level, self.text)

    def test_focused_verification_is_the_minimum(self) -> None:
        self.assertRegex(self.text, r"focused verification is the minimum")


    def test_correction_is_not_limited_to_one_pass(self) -> None:
        self.assertNotIn("one correction", self.text)
        self.assertNotIn("one re-review", self.text)

    def test_evidence_gate_rejects_unearned_claims(self) -> None:
        section = self.text.split("## evidence gate", maxsplit=1)[1]
        for phrase in ("actually ran", "actually happened", "verification gaps"):
            self.assertIn(phrase, section)

    def test_routes_missing_and_performance_surfaces(self) -> None:
        self.assertIn("`verification-harness`", self.text)
        self.assertIn("`performance-forensics`", self.text)


class RepositoryRoutingContract(unittest.TestCase):
    def setUp(self) -> None:
        if not BASE_MD.is_file() or not MULTI_PROVIDER_ROOT.is_dir():
            self.skipTest("repository integration sources are not installed")


    def test_base_routes_concrete_provider_work_to_overlay(self) -> None:
        text = normalized(BASE_MD)
        self.assertIn("`multi-provider-sdlc` select concrete models", text)
        self.assertIn("Use `multi-provider-sdlc` when provider diversity", text)




    def test_multi_provider_root_rejects_lifecycle_ownership(self) -> None:
        text = normalized(MULTI_PROVIDER_ROOT / "SKILL.md")
        self.assertIn("Caller owns lifecycle and final judgment", text)
        self.assertIn("Selection grants no new authority", text)

    def test_multi_provider_owns_only_concrete_route_selection(self) -> None:
        fields, body = split_frontmatter(read(MULTI_PROVIDER_ROOT / "SKILL.md"))
        body = " ".join(body.split())
        self.assertNotIn("delegated", fields["description"].lower())
        self.assertIn("scripts/route-model.py", body)
        self.assertIn("Do not read routing tables", body)

    def test_multi_provider_phases_return_without_advancing(self) -> None:
        references = MULTI_PROVIDER_ROOT / "references"
        implementation = normalized(references / "implementation.md")
        validation = normalized(references / "validation.md")
        self.assertIn("Do not start validation or review phases", implementation)
        self.assertIn("Do not correct source or advance to review", validation)

    def test_swarm_is_explicit_and_not_a_lifecycle_owner(self) -> None:
        if not SWARM_ROOT.is_dir():
            self.skipTest("host-only swarm skill is not installed")
        fields, body = split_frontmatter(read(SWARM_ROOT / "SKILL.md"))
        description = fields["description"].lower()
        self.assertIn("explicit", description)
        self.assertIn("caller", body.lower())
        self.assertIn("final judgment", body.lower())


class RepositoryWorkerLaneContract(unittest.TestCase):
    def setUp(self) -> None:
        if not GENERAL_AGENTS.is_dir():
            self.skipTest("repository agent prompts are not installed")

    def test_shared_worker_core_owns_child_boundaries(self) -> None:
        text = normalized(SHARED_WORKER_CORE)

        for expected in (
            "one child worker",
            "parent-owned workflow",
            "verified context",
            "Missing write permission means read-only",
            "sibling agents",
            "assigned write set",
            "skill or tool lane",
            "invoke a lifecycle skill",
            "spawn workers",
            "Never overwrite another actor's changes",
            "evidence packet",
        ):
            self.assertIn(expected, text)

    def test_role_prompts_keep_bounded_role_contracts(self) -> None:
        role_markers = {
            "checker.md": "focused validation",
            "debugger.md": "Diagnose supplied failure",
            "fact-finder.md": "parent-stated question",
            "implementer.md": "parent-scoped change",
            "mechanic.md": "mechanical one-file edit",
            "model-worker.md": "model and provider pinned",
            "probe-runner.md": "non-destructive reproduction",
            "reviewer.md": "Review one supplied plan",
            "test-runner.md": "validation suites",
        }
        for name, marker in role_markers.items():
            text = normalized(GENERAL_AGENTS / name)
            self.assertIn(marker, text, name)
            self.assertNotIn("Never invoke lifecycle skills", text, name)

    def test_reviewer_prompt_defers_to_the_review_contract(self) -> None:
        text = normalized(GENERAL_AGENTS / "reviewer.md").lower()
        self.assertIn("premise-review", text)
        self.assertIn("return `blocked`", text)

    def test_review_contract_requires_implementation_ready_findings(self) -> None:
        text = normalized(REVIEW_CONTRACT).lower()
        for requirement in (
            "**evidence:**",
            "revalidate every finding against the current target state",
            "current pr head when reviewing a pull request",
            "trigger or input",
            "current behavior",
            "expected behavior",
            "applicable code shape",
            "exact condition, type, or module assignment",
            "precedence",
            "compatibility",
            "focused regression test that fails before",
            "one defect per finding",
            "what breaks",
            "replacement code shape",
            "proof test",
            "do not restate the diff",
            "abstract repair verbs without an exact operation",
            "owns the protocol or behavior being consumed",
            "pinned commit and exact lines",
            "unresolved choice and viable alternatives",
        ):
            self.assertIn(requirement, text)


class MarketplaceCompositionContract(unittest.TestCase):
    def setUp(self) -> None:
        if not CATALOG.is_file():
            self.skipTest("marketplace catalog is not installed")
        catalog = json.loads(read(CATALOG))
        self.members = set(catalog["bundles"]["workflow-core"]["plugins"])

    def test_workflow_bundle_contains_direct_routes(self) -> None:
        required = {
            "engineering-workflow",
            "git-toolkit",
            "github-toolkit",
            "software-engineering",
            "research",
            "requirements-interview",
            "tdd",
            "verification-harness",
            "diagnosing-bugs",
        }
        self.assertTrue(required.issubset(self.members))

    def test_host_only_swarm_is_excluded(self) -> None:
        catalog = json.loads(read(CATALOG))
        self.assertIn("swarm", catalog["excluded"])
        self.assertNotIn("swarm", self.members)


class DelegationContract(unittest.TestCase):
    def setUp(self) -> None:
        self.text = read(REFERENCES / "delegation.md").lower()

    def test_packet_fields_are_declared(self) -> None:
        for field in (
            "task",
            "paths",
            "constraints",
            "write policy",
            "exit criteria",
        ):
            self.assertIn(field, self.text)
        self.assertRegex(self.text, r"skill or tool lane")

    def test_single_write_owner_per_batch(self) -> None:
        self.assertIn("one write owner per batch", self.text)

    def test_semantic_fact_finder_is_named(self) -> None:
        self.assertIn("fact-finder", self.text)

    def test_provider_routing_requires_concrete_route_need(self) -> None:
        self.assertRegex(self.text, r"multi-provider-sdlc.*provider diversity")
        self.assertIn("named-model intent", self.text)

    def test_swarm_routing_requires_explicit_request(self) -> None:
        self.assertRegex(self.text, r"swarm.*only when the user explicitly requests")

    def test_workers_never_own_final_judgment(self) -> None:
        self.assertRegex(
            self.text,
            r"workers never own architecture, final judgment, or external delivery",
        )

    def test_unavailable_workers_do_not_fabricate_evidence(self) -> None:
        self.assertIn("never claim delegated evidence that did not run", self.text)


class TaskShapesContract(unittest.TestCase):
    def setUp(self) -> None:
        self.content = read(REFERENCES / "task-shapes.md")

    def test_declares_six_shapes(self) -> None:
        headings = re.findall(r"^##\s+(.+)$", self.content, re.MULTILINE)
        shapes = [heading.strip() for heading in headings if heading != "Attribution"]
        self.assertEqual(
            shapes,
            [
                "Bug Fix",
                "Feature",
                "Refactor",
                "Modernization",
                "Prototype",
                "Evaluation",
            ],
        )

    def test_investigation_is_a_phase_not_a_shape(self) -> None:
        lowered = self.content.lower()
        self.assertIn("investigation is a phase", lowered)
        self.assertIn("`how`", lowered)
        self.assertIn("`why`", lowered)

    def test_shapes_route_optional_leaf_methods(self) -> None:
        for skill in ("research", "tdd", "verification-harness", "diagnosing-bugs"):
            self.assertIn(f"`{skill}`", self.content)

    def test_modernization_routes_by_lifecycle_size(self) -> None:
        modernization = self.content.split("## Modernization", maxsplit=1)[1].split(
            "## Prototype", maxsplit=1
        )[0]
        text = compact(modernization)
        self.assertIn("[modernization.md](modernization.md)", modernization)
        self.assertIn(PROGRAM_SCALE_PREDICATE, text)
        self.assertRegex(
            text,
            r"Route program-scale modernization to `figure-it-out` before writes[.]",
        )

    def test_attributes_upstream_license(self) -> None:
        self.assertIn("pstack", self.content.lower())
        self.assertIn("../LICENSE", self.content)


class ModernizationContract(unittest.TestCase):
    def setUp(self) -> None:
        self.content = read(REFERENCES / "modernization.md")
        self.text = self.content.lower()

    def test_freezes_compatibility_before_translation(self) -> None:
        freeze = self.content.split("## Freeze the Compatibility Contract", maxsplit=1)[
            1
        ].split("## Shape the Migration", maxsplit=1)[0]
        text = " ".join(freeze.lower().split())
        self.assertIn("observable contract as a compatibility matrix", text)
        self.assertIn("capture the baseline on the legacy implementation", text)

    def test_owner_predicate_matches_task_shape(self) -> None:
        owner = self.content.split("## Owner Boundary", maxsplit=1)[1].split(
            "## Freeze the Compatibility Contract", maxsplit=1
        )[0]
        owner_text = compact(owner)
        self.assertIn(PROGRAM_SCALE_PREDICATE, owner_text)
        self.assertIn(
            "Route program-scale modernization to `figure-it-out` before writes.",
            owner_text,
        )
        self.assertIn(
            "cutover, and rollback execution as separate authority",
            owner_text,
        )
        self.assertIn(
            "A code or commit grant does not authorize an external cutover.",
            owner_text,
        )

    def test_separates_mechanical_and_behavior_changes(self) -> None:
        shape = self.content.split("## Shape the Migration", maxsplit=1)[1].split(
            "## Prove and Cut Over", maxsplit=1
        )[0]
        text = compact(shape).lower()
        self.assertIn("expand-migrate-contract", text)
        self.assertLess(
            text.index("mechanical translation"),
            text.index("deliberate behavior change"),
        )
        self.assertIn(
            "keep mechanical translation and behavior change in separate slices", text
        )
        self.assertIn(
            "separate compatibility-matrix entries, checks, and reviewer verdicts",
            text,
        )
        self.assertIn("removal condition", text)

    def test_requires_parity_cutover_and_rollback_evidence(self) -> None:
        proof = self.content.split("## Prove and Cut Over", maxsplit=1)[1].split(
            "## Completion", maxsplit=1
        )[0]
        text = compact(proof).lower()
        self.assertIn("old and new paths against identical fixtures", text)
        self.assertIn("do not prove semantic parity", text)
        self.assertIn("make data and activation operations idempotent and resumable", text)
        self.assertIn("run each applicable operation twice", text)
        self.assertIn("prove the second run converges without another effect", text)
        self.assertRegex(text, r"before an authorized cutover, prove rollback")

    def test_finishes_without_dual_maintenance(self) -> None:
        completion = self.content.split("## Completion", maxsplit=1)[1]
        text = completion.lower()
        self.assertIn("sole supported path", text)
        self.assertIn("deleted", text)
        self.assertIn("remaining legacy references", text)

    def test_orders_cutover_stabilization_and_legacy_deletion(self) -> None:
        shape = self.content.split("## Shape the Migration", maxsplit=1)[1]
        text = compact(shape).lower()
        for term in (
            "cutover, post-cutover stabilization, and legacy deletion",
            "separate green ordered slices",
            "stabilization evidence passes",
            "legacy path",
        ):
            self.assertIn(term, text)
        ordered = text.split("1. verification scaffold", maxsplit=1)[1]
        self.assertLess(ordered.index("authorized cutover"), ordered.index("post-cutover stabilization"))
        self.assertLess(ordered.index("post-cutover stabilization"), ordered.index("legacy deletion"))


class LicenseContract(unittest.TestCase):
    def setUp(self) -> None:
        self.lines = read(LICENSE).splitlines()

    def test_is_mit_with_upstream_copyright(self) -> None:
        self.assertEqual(self.lines[0].strip(), "MIT License")
        self.assertEqual(self.lines[2].strip(), "Copyright (c) 2026 Lauren Tan")

    def test_retains_standard_mit_clauses(self) -> None:
        text = "\n".join(self.lines)
        self.assertIn("Permission is hereby granted, free of charge", text)
        self.assertIn('THE SOFTWARE IS PROVIDED "AS IS"', text)
        self.assertIn("shall be included in all", text)


class OpenAIMetadataContract(unittest.TestCase):
    def setUp(self) -> None:
        self.content = read(OPENAI_METADATA)
        self.values: dict[str, str] = {}
        for line in self.content.splitlines():
            match = re.match(r"^\s{2}([a-z_]+):\s*\"(.*)\"\s*$", line)
            if match:
                self.values[match.group(1)] = match.group(2)

    def test_declares_interface_mapping(self) -> None:
        top_level = re.findall(r"^([A-Za-z0-9_-]+):", self.content, re.MULTILINE)
        self.assertEqual(top_level, ["interface"])

    def test_required_interface_fields_exist(self) -> None:
        self.assertEqual(
            set(self.values),
            {"default_prompt", "display_name", "short_description"},
        )

    def test_short_description_length_is_in_range(self) -> None:
        self.assertTrue(25 <= len(self.values["short_description"]) <= 64)

    def test_default_prompt_mentions_the_skill(self) -> None:
        self.assertIn("$engineering-workflow", self.values["default_prompt"])

    def test_declares_no_mcp_dependencies(self) -> None:
        self.assertNotIn("mcp", self.content.lower())


if __name__ == "__main__":
    unittest.main()
