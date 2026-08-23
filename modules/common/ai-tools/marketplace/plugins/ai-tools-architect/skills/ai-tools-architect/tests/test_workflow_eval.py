from __future__ import annotations

import hashlib
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "workflow_eval.py"
SPEC = importlib.util.spec_from_file_location("workflow_eval", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
workflow_eval = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(workflow_eval)


def corpus() -> dict[str, object]:
    return {
        "schema_version": 1,
        "suite_id": "routing-baseline",
        "frozen_at": "2026-08-23",
        "source_revision": "0123456789abcdef",
        "cases": [
            {
                "id": "routine-bug-fix",
                "prompt": "Find and fix the failing parser regression.",
                "tags": ["owner-positive", "bug-fix"],
                "expected": {
                    "selection": {
                        "owner": "engineering-workflow",
                        "methods": ["diagnosing-bugs"],
                        "overlays": [],
                    },
                    "must_not_select": ["program-orchestration"],
                },
            },
            {
                "id": "architecture-answer",
                "prompt": "Evaluate this repository architecture without edits.",
                "tags": ["owner-positive", "answer-only"],
                "expected": {
                    "selection": {
                        "owner": "software-engineering",
                        "methods": [],
                        "overlays": [],
                    },
                    "must_not_select": ["engineering-workflow"],
                },
            },
        ],
    }


def write_json(path: Path, payload: object) -> None:
    path.write_text(json.dumps(payload), encoding="utf-8")


def result_record(
    run_id: str,
    blind_id: str,
    candidate: str,
    trial: int,
    observed: dict[str, object],
) -> dict[str, object]:
    return {
        "schema_version": 1,
        "run_id": run_id,
        "blind_id": blind_id,
        "candidate_id": candidate,
        "environment_id": "environment-1",
        "trial": trial,
        "observed": observed,
        "evidence": {
            "transcript_path": f"transcripts/{candidate}-{blind_id}-{trial}.jsonl",
            "opened_resources": ["AGENTS.md"],
            "latency_ms": 100 + trial,
            "input_tokens": 1000,
            "output_tokens": 200,
            "cost_usd": None,
            "task_passed": True,
            "degradation": None,
        },
    }


class WorkflowEvaluationTests(unittest.TestCase):
    def test_prepare_blinds_routes_and_is_deterministic(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "corpus.json"
            write_json(source, corpus())

            first = workflow_eval.prepare(source, root / "first", "seed", False)
            second = workflow_eval.prepare(source, root / "second", "seed", False)

            first_tasks = (root / "first/tasks.jsonl").read_text()
            second_tasks = (root / "second/tasks.jsonl").read_text()
            self.assertEqual(first_tasks, second_tasks)
            self.assertNotIn("engineering-workflow", first_tasks)
            self.assertNotIn("routine-bug-fix", first_tasks)
            self.assertEqual(first["tasks_sha256"], second["tasks_sha256"])
            answer_key = json.loads((root / "first/answer-key.json").read_text())
            self.assertEqual(len(answer_key["cases"]), 2)
            self.assertEqual(answer_key["run_id"], first["run_id"])

    def test_prepare_refuses_overwrite_without_force(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "corpus.json"
            output = root / "run"
            write_json(source, corpus())
            workflow_eval.prepare(source, output, "seed", False)

            with self.assertRaisesRegex(
                workflow_eval.EvaluationError, "refusing to overwrite"
            ):
                workflow_eval.prepare(source, output, "seed", False)

            workflow_eval.prepare(source, output, "seed", True)

    def test_corpus_rejects_selected_forbidden_route(self) -> None:
        payload = corpus()
        payload["cases"][0]["expected"]["must_not_select"] = ["engineering-workflow"]

        with self.assertRaisesRegex(
            workflow_eval.EvaluationError, "selects and forbids"
        ):
            workflow_eval.validate_corpus(payload)

    def test_score_checks_trials_and_reports_route_metrics(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "corpus.json"
            run = root / "run"
            results = root / "results.jsonl"
            write_json(source, corpus())
            workflow_eval.prepare(source, run, "seed", False)
            answer_key = json.loads((run / "answer-key.json").read_text())

            records = []
            for case in answer_key["cases"]:
                expected = case["expected"]["selection"]
                for trial in range(1, 4):
                    records.append(
                        result_record(
                            answer_key["run_id"],
                            case["blind_id"],
                            "candidate-a",
                            trial,
                            expected,
                        )
                    )
                    wrong = dict(expected)
                    if case["case_id"] == "routine-bug-fix":
                        wrong = {"owner": None, "methods": [], "overlays": []}
                    records.append(
                        result_record(
                            answer_key["run_id"],
                            case["blind_id"],
                            "candidate-b",
                            trial,
                            wrong,
                        )
                    )
            results.write_text(
                "".join(json.dumps(record) + "\n" for record in records),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                workflow_eval.EvaluationError, "candidate-c/.+ has 0 trials"
            ):
                workflow_eval.score(
                    run / "manifest.json",
                    run / "answer-key.json",
                    results,
                    3,
                    ["candidate-a", "candidate-b", "candidate-c"],
                )

            summary = workflow_eval.score(
                run / "manifest.json",
                run / "answer-key.json",
                results,
                3,
                ["candidate-a", "candidate-b"],
            )

            candidates = {item["candidate_id"]: item for item in summary["candidates"]}
            self.assertEqual(candidates["candidate-a"]["route_exact"], 6)
            self.assertEqual(candidates["candidate-b"]["route_exact"], 3)
            self.assertEqual(candidates["candidate-a"]["task_passes"], 6)
            self.assertEqual(candidates["candidate-a"]["route_exact_rate"], 1.0)
            self.assertEqual(summary["environment_id"], "environment-1")

            records[1]["evidence"]["cost_usd"] = 0.01
            results.write_text(
                "".join(json.dumps(record) + "\n" for record in records),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                workflow_eval.EvaluationError, "measurement availability differs"
            ):
                workflow_eval.score(
                    run / "manifest.json",
                    run / "answer-key.json",
                    results,
                    3,
                    ["candidate-a", "candidate-b"],
                )

    def test_score_rejects_environment_drift(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "corpus.json"
            run = root / "run"
            results = root / "results.jsonl"
            write_json(source, corpus())
            workflow_eval.prepare(source, run, "seed", False)
            answer_key = json.loads((run / "answer-key.json").read_text())
            records = []
            for case in answer_key["cases"]:
                for trial in range(1, 4):
                    record = result_record(
                        answer_key["run_id"],
                        case["blind_id"],
                        "candidate-a",
                        trial,
                        case["expected"]["selection"],
                    )
                    if trial == 3:
                        record["environment_id"] = "environment-2"
                    records.append(record)
            results.write_text(
                "".join(json.dumps(record) + "\n" for record in records),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(
                workflow_eval.EvaluationError, "one environment_id"
            ):
                workflow_eval.score(
                    run / "manifest.json",
                    run / "answer-key.json",
                    results,
                    3,
                    ["candidate-a"],
                )

    def test_score_rejects_answer_key_tampering(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "corpus.json"
            run = root / "run"
            results = root / "results.jsonl"
            write_json(source, corpus())
            workflow_eval.prepare(source, run, "seed", False)
            answer_key_path = run / "answer-key.json"
            answer_key = json.loads(answer_key_path.read_text())
            answer_key["cases"][0]["expected"]["selection"]["owner"] = None
            write_json(answer_key_path, answer_key)
            results.write_text("{}\n", encoding="utf-8")

            with self.assertRaisesRegex(
                workflow_eval.EvaluationError, "hash does not match manifest"
            ):
                workflow_eval.score(
                    run / "manifest.json",
                    answer_key_path,
                    results,
                    1,
                    ["candidate-a"],
                )

    def test_score_rejects_tampered_tasks_before_result_scoring(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "corpus.json"
            run = root / "run"
            results = root / "results.jsonl"
            write_json(source, corpus())
            workflow_eval.prepare(source, run, "seed", False)
            tasks_path = run / "tasks.jsonl"
            tasks_path.write_text(
                tasks_path.read_text().replace("Find and fix", "Tamper and fix"),
                encoding="utf-8",
            )
            results.write_text("not-json\n", encoding="utf-8")

            with self.assertRaisesRegex(
                workflow_eval.EvaluationError, "tasks hash does not match manifest"
            ):
                workflow_eval.score(
                    run / "manifest.json",
                    run / "answer-key.json",
                    results,
                    1,
                    ["candidate-a"],
                )

    def test_score_strictly_validates_task_records(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "corpus.json"
            run = root / "run"
            results = root / "results.jsonl"
            write_json(source, corpus())
            workflow_eval.prepare(source, run, "seed", False)
            tasks_path = run / "tasks.jsonl"
            tasks = [json.loads(line) for line in tasks_path.read_text().splitlines()]
            del tasks[0]["prompt"]
            tasks_text = "".join(
                json.dumps(task, sort_keys=True) + "\n" for task in tasks
            )
            tasks_path.write_text(tasks_text, encoding="utf-8")
            manifest_path = run / "manifest.json"
            manifest = json.loads(manifest_path.read_text())
            manifest["tasks_sha256"] = hashlib.sha256(tasks_text.encode()).hexdigest()
            write_json(manifest_path, manifest)
            results.write_text("not-json\n", encoding="utf-8")

            with self.assertRaisesRegex(
                workflow_eval.EvaluationError, "missing prompt"
            ):
                workflow_eval.score(
                    manifest_path,
                    run / "answer-key.json",
                    results,
                    1,
                    ["candidate-a"],
                )

    def test_score_rejects_stale_run_and_unequal_trials(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "corpus.json"
            run = root / "run"
            results = root / "results.jsonl"
            write_json(source, corpus())
            workflow_eval.prepare(source, run, "seed", False)
            answer_key = json.loads((run / "answer-key.json").read_text())
            records = []
            for case in answer_key["cases"]:
                for trial in range(1, 4):
                    records.append(
                        result_record(
                            answer_key["run_id"],
                            case["blind_id"],
                            "candidate-a",
                            trial,
                            case["expected"]["selection"],
                        )
                    )

            stale = dict(records[0])
            stale["run_id"] = "run-stale"
            results.write_text(json.dumps(stale) + "\n", encoding="utf-8")
            with self.assertRaisesRegex(
                workflow_eval.EvaluationError, "do not match answer key run_id"
            ):
                workflow_eval.score(
                    run / "manifest.json",
                    run / "answer-key.json",
                    results,
                    1,
                    ["candidate-a"],
                )

            records.append(
                result_record(
                    answer_key["run_id"],
                    answer_key["cases"][0]["blind_id"],
                    "candidate-a",
                    4,
                    answer_key["cases"][0]["expected"]["selection"],
                )
            )
            results.write_text(
                "".join(json.dumps(record) + "\n" for record in records),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                workflow_eval.EvaluationError, "trial set differs"
            ):
                workflow_eval.score(
                    run / "manifest.json",
                    run / "answer-key.json",
                    results,
                    3,
                    ["candidate-a"],
                )

    def test_score_allows_missing_latency_and_rejects_non_finite_numbers(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "corpus.json"
            run = root / "run"
            results = root / "results.jsonl"
            write_json(source, corpus())
            workflow_eval.prepare(source, run, "seed", False)
            answer_key = json.loads((run / "answer-key.json").read_text())
            records = []
            for case in answer_key["cases"]:
                for trial in range(1, 4):
                    record = result_record(
                        answer_key["run_id"],
                        case["blind_id"],
                        "candidate-a",
                        trial,
                        case["expected"]["selection"],
                    )
                    record["evidence"]["latency_ms"] = None
                    records.append(record)
            results.write_text(
                "".join(json.dumps(record) + "\n" for record in records),
                encoding="utf-8",
            )

            summary = workflow_eval.score(
                run / "manifest.json",
                run / "answer-key.json",
                results,
                3,
                ["candidate-a"],
            )

            candidate = summary["candidates"][0]
            self.assertIsNone(candidate["median_latency_ms"])
            self.assertEqual(candidate["latency_records"], 0)

            for record in records:
                record["evidence"]["latency_ms"] = 1e308
            results.write_text(
                "".join(json.dumps(record) + "\n" for record in records),
                encoding="utf-8",
            )
            summary = workflow_eval.score(
                run / "manifest.json",
                run / "answer-key.json",
                results,
                3,
                ["candidate-a"],
            )
            self.assertEqual(summary["candidates"][0]["median_latency_ms"], 1e308)

            for record in records:
                record["evidence"]["cost_usd"] = 1e308
            results.write_text(
                "".join(json.dumps(record) + "\n" for record in records),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                workflow_eval.EvaluationError, "cost aggregate overflowed"
            ):
                workflow_eval.score(
                    run / "manifest.json",
                    run / "answer-key.json",
                    results,
                    3,
                    ["candidate-a"],
                )

            results.write_text('{"latency_ms": NaN}\n', encoding="utf-8")
            with self.assertRaisesRegex(
                workflow_eval.EvaluationError, "non-standard JSON constant"
            ):
                workflow_eval.read_jsonl(results)


if __name__ == "__main__":
    unittest.main()
