from __future__ import annotations

import importlib.util
import re
import unittest
from pathlib import Path
from typing import Any

SKILL = Path(__file__).resolve().parents[1]
SCRIPT = SKILL / "scripts" / "workflow_eval.py"
CORPUS_RELATIVE = Path("eval/workflow-routing-baseline.json")
SKILLS_RELATIVE = Path("skills")
SPEC = importlib.util.spec_from_file_location("workflow_eval_baseline", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
workflow_eval = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(workflow_eval)

EXPLICIT_TARGETS = {
    "ai-tools-architect",
    "arena",
    "interrogate",
    "playwright-interactive",
    "recall",
    "reflect",
    "requirements-interview",
    "unslop",
}
REQUIRED_TAGS = {
    "owner-positive",
    "owner-negative",
    "method-positive",
    "method-negative",
    "overlay-positive",
    "overlay-negative",
    "explicit-positive",
    "explicit-negative",
    "provider-parity",
}
EXPLICIT_ROUTE_CATEGORIES = {
    "ai-tools-architect": "owner",
    "arena": "owner",
    "interrogate": "overlay",
    "playwright-interactive": "owner",
    "recall": "owner",
    "reflect": "owner",
    "requirements-interview": "owner",
    "unslop": "method",
}
EXPLICIT_CASE_CATEGORIES = {
    "explicit-ai-tools-architect": ("owner", "ai-tools-architect"),
    "explicit-arena": ("owner", "arena"),
    "explicit-interrogate": ("overlay", "interrogate"),
    "explicit-playwright-interactive": ("owner", "playwright-interactive"),
    "explicit-recall": ("owner", "recall"),
    "explicit-reflect": ("owner", "reflect"),
    "explicit-requirements-interview": ("owner", "requirements-interview"),
    "explicit-unslop": ("method", "unslop"),
}


def find_ai_tools_root() -> Path | None:
    """Return the repository ai-tools directory that owns corpus and skills."""
    for candidate in Path(__file__).resolve().parents:
        if candidate.name != "ai-tools" or candidate.parent.name != "common":
            continue
        if (candidate / CORPUS_RELATIVE).is_file() and (
            candidate / SKILLS_RELATIVE
        ).is_dir():
            return candidate
    return None


AI_TOOLS_ROOT = find_ai_tools_root()


def selected_routes(case: dict[str, object]) -> set[str]:
    selection = case["expected"]["selection"]
    return {
        route
        for route in [
            selection["owner"],
            *selection["methods"],
            *selection["overlays"],
        ]
        if route is not None
    }


def referenced_routes(case: dict[str, Any]) -> set[str]:
    return selected_routes(case) | set(case["expected"]["must_not_select"])


class WorkflowRoutingBaselineTests(unittest.TestCase):
    def load_baseline(self) -> tuple[Path, dict[str, Any]]:
        if AI_TOOLS_ROOT is None:
            self.skipTest(
                f"repository corpus {CORPUS_RELATIVE} and {SKILLS_RELATIVE} tree "
                "are unavailable outside the khanelinix checkout"
            )
        payload, _ = workflow_eval.read_json(AI_TOOLS_ROOT / CORPUS_RELATIVE)
        return AI_TOOLS_ROOT, workflow_eval.validate_corpus(payload)

    def test_baseline_corpus_shape_is_valid(self) -> None:
        _, baseline = self.load_baseline()

        self.assertEqual(baseline["suite_id"], "workflow-routing-baseline")
        self.assertRegex(baseline["source_revision"], re.compile(r"^[0-9a-f]{40}$"))
        self.assertTrue(
            all("provider-parity" in case["tags"] for case in baseline["cases"])
        )

    def test_baseline_routes_resolve_to_live_skills(self) -> None:
        ai_tools_root, baseline = self.load_baseline()
        skills_root = ai_tools_root / SKILLS_RELATIVE
        inventory = {
            entry.name
            for entry in skills_root.iterdir()
            if (entry / "SKILL.md").is_file()
        }

        self.assertIn("ai-tools-architect", inventory)
        for case in baseline["cases"]:
            for route in sorted(referenced_routes(case)):
                if route in inventory:
                    continue
                self.fail(
                    f"case {case['id']} references route {route}, "
                    f"but {skills_root}/{route}/SKILL.md does not exist"
                )

    def test_baseline_covers_route_categories_and_explicit_targets(self) -> None:
        _, baseline = self.load_baseline()
        tags = {tag for case in baseline["cases"] for tag in case["tags"]}
        explicit_selected = {
            route
            for case in baseline["cases"]
            if "explicit-positive" in case["tags"]
            for route in selected_routes(case)
        }
        explicit_forbidden = {
            route
            for case in baseline["cases"]
            if "explicit-negative" in case["tags"]
            for route in case["expected"]["must_not_select"]
        }

        self.assertTrue(REQUIRED_TAGS.issubset(tags))
        self.assertTrue(EXPLICIT_TARGETS.issubset(explicit_selected))
        self.assertTrue(EXPLICIT_TARGETS.issubset(explicit_forbidden))

        cases_by_id = {case["id"]: case for case in baseline["cases"]}
        selection_keys = {"owner": "owner", "method": "methods", "overlay": "overlays"}
        for case_id, (category, route) in EXPLICIT_CASE_CATEGORIES.items():
            selection = cases_by_id[case_id]["expected"]["selection"]
            selected = selection[selection_keys[category]]
            if category == "owner":
                selected = [selection["owner"]]
            self.assertIn(route, selected)

        for case in baseline["cases"]:
            if "explicit-positive" not in case["tags"]:
                continue
            selection = case["expected"]["selection"]
            for category, routes in (
                ("owner", [selection["owner"]]),
                ("method", selection["methods"]),
                ("overlay", selection["overlays"]),
            ):
                for route in routes:
                    if route in EXPLICIT_ROUTE_CATEGORIES:
                        self.assertEqual(EXPLICIT_ROUTE_CATEGORIES[route], category)


if __name__ == "__main__":
    unittest.main()
