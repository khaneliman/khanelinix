#!/usr/bin/env python3
"""Prepare and score blinded workflow-routing evaluations."""

from __future__ import annotations

import argparse
import hashlib
import hmac
import json
import math
import os
import re
import sys
import tempfile
from collections import defaultdict
from collections.abc import Sequence
from datetime import date
from pathlib import Path
from typing import Any

SCHEMA_VERSION = 1
NAME_RE = re.compile(r"^[a-z0-9][a-z0-9-]{0,63}$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
OUTPUT_FILES = ("tasks.jsonl", "answer-key.json", "manifest.json")


class EvaluationError(RuntimeError):
    """Raised when evaluation input cannot produce trustworthy output."""


def reject_json_constant(value: str) -> None:
    raise EvaluationError(f"non-standard JSON constant: {value}")


def read_json(path: Path) -> tuple[dict[str, Any], bytes]:
    try:
        raw = path.read_bytes()
        payload = json.loads(raw, parse_constant=reject_json_constant)
    except OSError as error:
        raise EvaluationError(f"could not read {path}: {error}") from error
    except json.JSONDecodeError as error:
        raise EvaluationError(f"invalid JSON in {path}: {error}") from error
    if not isinstance(payload, dict):
        raise EvaluationError(f"{path} must contain a JSON object")
    return payload, raw


def require_keys(value: dict[str, Any], expected: set[str], context: str) -> None:
    actual = set(value)
    if actual == expected:
        return
    missing = sorted(expected - actual)
    extra = sorted(actual - expected)
    details = []
    if missing:
        details.append(f"missing {', '.join(missing)}")
    if extra:
        details.append(f"unexpected {', '.join(extra)}")
    raise EvaluationError(f"{context}: {'; '.join(details)}")


def require_name(value: Any, context: str) -> str:
    if not isinstance(value, str) or not NAME_RE.fullmatch(value):
        raise EvaluationError(f"{context} must match {NAME_RE.pattern}")
    return value


def require_string(value: Any, context: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise EvaluationError(f"{context} must be a non-empty string")
    return value


def require_sha256(value: Any, context: str) -> str:
    if not isinstance(value, str) or not SHA256_RE.fullmatch(value):
        raise EvaluationError(f"{context} must be a lowercase SHA-256 digest")
    return value


def require_names(value: Any, context: str) -> list[str]:
    if not isinstance(value, list):
        raise EvaluationError(f"{context} must be a list")
    names = [require_name(item, f"{context} item") for item in value]
    if len(names) != len(set(names)):
        raise EvaluationError(f"{context} must not contain duplicates")
    return names


def validate_selection(value: Any, context: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise EvaluationError(f"{context} must be an object")
    require_keys(value, {"owner", "methods", "overlays"}, context)
    owner = value["owner"]
    if owner is not None:
        owner = require_name(owner, f"{context}.owner")
    methods = require_names(value["methods"], f"{context}.methods")
    overlays = require_names(value["overlays"], f"{context}.overlays")
    selected = ([owner] if owner else []) + methods + overlays
    if len(selected) != len(set(selected)):
        raise EvaluationError(f"{context} routes must be unique across categories")
    return {"owner": owner, "methods": methods, "overlays": overlays}


def validate_corpus(payload: dict[str, Any]) -> dict[str, Any]:
    require_keys(
        payload,
        {"schema_version", "suite_id", "frozen_at", "source_revision", "cases"},
        "corpus",
    )
    if (
        type(payload["schema_version"]) is not int
        or payload["schema_version"] != SCHEMA_VERSION
    ):
        raise EvaluationError(f"corpus.schema_version must be {SCHEMA_VERSION}")
    suite_id = require_name(payload["suite_id"], "corpus.suite_id")
    frozen_at = require_string(payload["frozen_at"], "corpus.frozen_at")
    try:
        date.fromisoformat(frozen_at)
    except ValueError as error:
        raise EvaluationError("corpus.frozen_at must use YYYY-MM-DD") from error
    source_revision = require_string(
        payload["source_revision"], "corpus.source_revision"
    )
    cases = payload["cases"]
    if not isinstance(cases, list) or not cases:
        raise EvaluationError("corpus.cases must be a non-empty list")

    normalized_cases = []
    case_ids: set[str] = set()
    for index, case in enumerate(cases):
        context = f"corpus.cases[{index}]"
        if not isinstance(case, dict):
            raise EvaluationError(f"{context} must be an object")
        require_keys(case, {"id", "prompt", "tags", "expected"}, context)
        case_id = require_name(case["id"], f"{context}.id")
        if case_id in case_ids:
            raise EvaluationError(f"duplicate case ID: {case_id}")
        case_ids.add(case_id)
        prompt = require_string(case["prompt"], f"{context}.prompt")
        tags = require_names(case["tags"], f"{context}.tags")
        if not tags:
            raise EvaluationError(f"{context}.tags must not be empty")
        expected = case["expected"]
        if not isinstance(expected, dict):
            raise EvaluationError(f"{context}.expected must be an object")
        require_keys(expected, {"selection", "must_not_select"}, f"{context}.expected")
        selection = validate_selection(
            expected["selection"], f"{context}.expected.selection"
        )
        must_not_select = require_names(
            expected["must_not_select"],
            f"{context}.expected.must_not_select",
        )
        selected = {
            item
            for item in [
                selection["owner"],
                *selection["methods"],
                *selection["overlays"],
            ]
            if item is not None
        }
        overlap = selected.intersection(must_not_select)
        if overlap:
            raise EvaluationError(
                f"{context} selects and forbids {', '.join(sorted(overlap))}"
            )
        normalized_cases.append(
            {
                "id": case_id,
                "prompt": prompt,
                "tags": tags,
                "expected": {
                    "selection": selection,
                    "must_not_select": must_not_select,
                },
            }
        )

    return {
        "schema_version": SCHEMA_VERSION,
        "suite_id": suite_id,
        "frozen_at": frozen_at,
        "source_revision": source_revision,
        "cases": normalized_cases,
    }


def blind_id(seed: str, run_id: str, suite_id: str, case_id: str) -> str:
    message = f"{run_id}\0{suite_id}\0{case_id}".encode()
    digest = hmac.new(seed.encode(), message, hashlib.sha256).hexdigest()
    return f"case-{digest[:16]}"


def json_text(payload: Any) -> str:
    try:
        return json.dumps(payload, indent=2, sort_keys=True, allow_nan=False) + "\n"
    except (ValueError, OverflowError) as error:
        raise EvaluationError(f"could not encode finite JSON: {error}") from error


def finite_sum(values: list[float], context: str) -> float:
    try:
        total = math.fsum(values)
    except OverflowError as error:
        raise EvaluationError(f"{context} aggregate overflowed") from error
    if not math.isfinite(total):
        raise EvaluationError(f"{context} aggregate is not finite")
    return total


def finite_median(values: list[float], context: str) -> float:
    ordered = sorted(values)
    midpoint = len(ordered) // 2
    if len(ordered) % 2:
        median = ordered[midpoint]
    else:
        lower = ordered[midpoint - 1]
        upper = ordered[midpoint]
        median = lower + (upper - lower) / 2
    if not math.isfinite(median):
        raise EvaluationError(f"{context} median is not finite")
    return median


def write_atomic(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(content)
        os.replace(temporary, path)
    except BaseException:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise


def prepare(corpus_path: Path, output: Path, seed: str, force: bool) -> dict[str, Any]:
    if not seed:
        raise EvaluationError("seed must not be empty")
    payload, raw = read_json(corpus_path)
    corpus = validate_corpus(payload)
    corpus_sha256 = hashlib.sha256(raw).hexdigest()
    seed_sha256 = hashlib.sha256(seed.encode()).hexdigest()
    run_digest = hashlib.sha256(
        f"{SCHEMA_VERSION}\0{corpus_sha256}\0{seed_sha256}".encode()
    ).hexdigest()
    run_id = f"run-{run_digest[:20]}"
    if output.exists() and not output.is_dir():
        raise EvaluationError(f"output is not a directory: {output}")
    existing = [name for name in OUTPUT_FILES if (output / name).exists()]
    if existing and not force:
        raise EvaluationError(
            "refusing to overwrite existing output: " + ", ".join(existing)
        )

    blinded = []
    ids: set[str] = set()
    for case in corpus["cases"]:
        opaque = blind_id(seed, run_id, corpus["suite_id"], case["id"])
        if opaque in ids:
            raise EvaluationError("blinded case ID collision")
        ids.add(opaque)
        blinded.append((opaque, case))
    blinded.sort(key=lambda item: item[0])

    tasks = [
        {
            "schema_version": SCHEMA_VERSION,
            "suite_id": corpus["suite_id"],
            "run_id": run_id,
            "blind_id": opaque,
            "prompt": case["prompt"],
        }
        for opaque, case in blinded
    ]
    answer_key = {
        "schema_version": SCHEMA_VERSION,
        "suite_id": corpus["suite_id"],
        "run_id": run_id,
        "cases": [
            {
                "blind_id": opaque,
                "case_id": case["id"],
                "tags": case["tags"],
                "expected": case["expected"],
            }
            for opaque, case in blinded
        ],
    }
    tasks_text = "".join(
        json.dumps(task, sort_keys=True, allow_nan=False) + "\n" for task in tasks
    )
    answer_text = json_text(answer_key)
    manifest = {
        "schema_version": SCHEMA_VERSION,
        "suite_id": corpus["suite_id"],
        "run_id": run_id,
        "frozen_at": corpus["frozen_at"],
        "source_revision": corpus["source_revision"],
        "corpus_sha256": corpus_sha256,
        "seed_sha256": seed_sha256,
        "tasks_sha256": hashlib.sha256(tasks_text.encode()).hexdigest(),
        "answer_key_sha256": hashlib.sha256(answer_text.encode()).hexdigest(),
        "task_count": len(tasks),
    }
    output.mkdir(parents=True, exist_ok=True)
    write_atomic(output / "tasks.jsonl", tasks_text)
    write_atomic(output / "answer-key.json", answer_text)
    write_atomic(output / "manifest.json", json_text(manifest))
    return manifest


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        raise EvaluationError(f"could not read {path}: {error}") from error
    records = []
    for number, line in enumerate(lines, start=1):
        if not line.strip():
            continue
        try:
            record = json.loads(line, parse_constant=reject_json_constant)
        except json.JSONDecodeError as error:
            raise EvaluationError(
                f"invalid JSON on {path}:{number}: {error}"
            ) from error
        if not isinstance(record, dict):
            raise EvaluationError(f"{path}:{number} must contain an object")
        records.append(record)
    if not records:
        raise EvaluationError(f"{path} contains no result records")
    return records


def read_tasks(
    path: Path,
    expected_sha256: str,
    suite_id: str,
    run_id: str,
    task_count: int,
    expected_blind_ids: set[str],
) -> None:
    try:
        raw = path.read_bytes()
    except OSError as error:
        raise EvaluationError(f"could not read {path}: {error}") from error
    if hashlib.sha256(raw).hexdigest() != expected_sha256:
        raise EvaluationError("tasks hash does not match manifest")
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as error:
        raise EvaluationError(f"invalid UTF-8 in {path}: {error}") from error

    task_ids: set[str] = set()
    lines = text.splitlines()
    for number, line in enumerate(lines, start=1):
        context = f"tasks[{number}]"
        if not line.strip():
            raise EvaluationError(f"{context} must contain a task object")
        try:
            task = json.loads(line, parse_constant=reject_json_constant)
        except json.JSONDecodeError as error:
            raise EvaluationError(
                f"invalid JSON on {path}:{number}: {error}"
            ) from error
        if not isinstance(task, dict):
            raise EvaluationError(f"{context} must contain an object")
        require_keys(
            task,
            {"schema_version", "suite_id", "run_id", "blind_id", "prompt"},
            context,
        )
        if (
            type(task["schema_version"]) is not int
            or task["schema_version"] != SCHEMA_VERSION
        ):
            raise EvaluationError(f"{context}.schema_version must be {SCHEMA_VERSION}")
        task_suite_id = require_name(task["suite_id"], f"{context}.suite_id")
        if task_suite_id != suite_id:
            raise EvaluationError(f"{context}.suite_id does not match manifest")
        task_run_id = require_string(task["run_id"], f"{context}.run_id")
        if task_run_id != run_id:
            raise EvaluationError(f"{context}.run_id does not match manifest")
        blind = require_string(task["blind_id"], f"{context}.blind_id")
        if blind in task_ids:
            raise EvaluationError(f"duplicate task blind ID: {blind}")
        task_ids.add(blind)
        require_string(task["prompt"], f"{context}.prompt")

    if len(task_ids) != task_count:
        raise EvaluationError("task count does not match manifest")
    if task_ids != expected_blind_ids:
        raise EvaluationError("task blind IDs do not match answer key")


def optional_count(value: Any, context: str) -> int | None:
    if value is None:
        return None
    if type(value) is not int or value < 0:
        raise EvaluationError(f"{context} must be a non-negative integer or null")
    return value


def optional_number(value: Any, context: str) -> float | None:
    if value is None:
        return None
    if (
        isinstance(value, bool)
        or not isinstance(value, (int, float))
        or not math.isfinite(value)
        or value < 0
    ):
        raise EvaluationError(f"{context} must be a non-negative number or null")
    return float(value)


def validate_result(record: dict[str, Any], context: str) -> dict[str, Any]:
    require_keys(
        record,
        {
            "schema_version",
            "run_id",
            "blind_id",
            "candidate_id",
            "environment_id",
            "trial",
            "observed",
            "evidence",
        },
        context,
    )
    if (
        type(record["schema_version"]) is not int
        or record["schema_version"] != SCHEMA_VERSION
    ):
        raise EvaluationError(f"{context}.schema_version must be {SCHEMA_VERSION}")
    run_id = require_string(record["run_id"], f"{context}.run_id")
    blind = require_string(record["blind_id"], f"{context}.blind_id")
    candidate = require_name(record["candidate_id"], f"{context}.candidate_id")
    environment = require_string(record["environment_id"], f"{context}.environment_id")
    trial = record["trial"]
    if type(trial) is not int or trial < 1:
        raise EvaluationError(f"{context}.trial must be a positive integer")
    observed = validate_selection(record["observed"], f"{context}.observed")
    evidence = record["evidence"]
    if not isinstance(evidence, dict):
        raise EvaluationError(f"{context}.evidence must be an object")
    require_keys(
        evidence,
        {
            "transcript_path",
            "opened_resources",
            "latency_ms",
            "input_tokens",
            "output_tokens",
            "cost_usd",
            "task_passed",
            "degradation",
        },
        f"{context}.evidence",
    )
    transcript = require_string(
        evidence["transcript_path"], f"{context}.evidence.transcript_path"
    )
    resources = evidence["opened_resources"]
    if not isinstance(resources, list) or any(
        not isinstance(item, str) or not item.strip() for item in resources
    ):
        raise EvaluationError(
            f"{context}.evidence.opened_resources must contain non-empty strings"
        )
    latency = optional_number(evidence["latency_ms"], f"{context}.evidence.latency_ms")
    task_passed = evidence["task_passed"]
    if task_passed is not None and not isinstance(task_passed, bool):
        raise EvaluationError(f"{context}.evidence.task_passed must be boolean or null")
    degradation = evidence["degradation"]
    if degradation is not None:
        degradation = require_string(degradation, f"{context}.evidence.degradation")
    return {
        "run_id": run_id,
        "blind_id": blind,
        "candidate_id": candidate,
        "environment_id": environment,
        "trial": trial,
        "observed": observed,
        "evidence": {
            "transcript_path": transcript,
            "opened_resources": resources,
            "latency_ms": latency,
            "input_tokens": optional_count(
                evidence["input_tokens"], f"{context}.evidence.input_tokens"
            ),
            "output_tokens": optional_count(
                evidence["output_tokens"], f"{context}.evidence.output_tokens"
            ),
            "cost_usd": optional_number(
                evidence["cost_usd"], f"{context}.evidence.cost_usd"
            ),
            "task_passed": task_passed,
            "degradation": degradation,
        },
    }


def score(
    manifest_path: Path,
    answer_key_path: Path,
    results_path: Path,
    minimum_trials: int,
    expected_candidates: Sequence[str],
) -> dict[str, Any]:
    if minimum_trials < 1:
        raise EvaluationError("minimum trials must be positive")
    candidates = [
        require_name(candidate, "candidate") for candidate in expected_candidates
    ]
    if not candidates:
        raise EvaluationError("at least one candidate is required")
    if len(candidates) != len(set(candidates)):
        raise EvaluationError("candidate IDs must not contain duplicates")
    candidates.sort()

    manifest, _ = read_json(manifest_path)
    require_keys(
        manifest,
        {
            "schema_version",
            "suite_id",
            "run_id",
            "frozen_at",
            "source_revision",
            "corpus_sha256",
            "seed_sha256",
            "tasks_sha256",
            "answer_key_sha256",
            "task_count",
        },
        "manifest",
    )
    if (
        type(manifest["schema_version"]) is not int
        or manifest["schema_version"] != SCHEMA_VERSION
    ):
        raise EvaluationError(f"manifest schema must be {SCHEMA_VERSION}")
    manifest_suite_id = require_name(manifest["suite_id"], "manifest suite_id")
    manifest_run_id = require_string(manifest["run_id"], "manifest run_id")
    require_string(manifest["frozen_at"], "manifest frozen_at")
    require_string(manifest["source_revision"], "manifest source_revision")
    corpus_sha256 = require_sha256(manifest["corpus_sha256"], "manifest corpus_sha256")
    seed_sha256 = require_sha256(manifest["seed_sha256"], "manifest seed_sha256")
    require_sha256(manifest["tasks_sha256"], "manifest tasks_sha256")
    answer_key_sha256 = require_sha256(
        manifest["answer_key_sha256"], "manifest answer_key_sha256"
    )
    if type(manifest["task_count"]) is not int or manifest["task_count"] < 1:
        raise EvaluationError("manifest task_count must be a positive integer")
    expected_run_digest = hashlib.sha256(
        f"{SCHEMA_VERSION}\0{corpus_sha256}\0{seed_sha256}".encode()
    ).hexdigest()
    if manifest_run_id != f"run-{expected_run_digest[:20]}":
        raise EvaluationError("manifest run_id does not match frozen inputs")

    answer_key, answer_key_raw = read_json(answer_key_path)
    if hashlib.sha256(answer_key_raw).hexdigest() != answer_key_sha256:
        raise EvaluationError("answer key hash does not match manifest")
    require_keys(
        answer_key,
        {"schema_version", "suite_id", "run_id", "cases"},
        "answer key",
    )
    if (
        type(answer_key["schema_version"]) is not int
        or answer_key["schema_version"] != SCHEMA_VERSION
    ):
        raise EvaluationError(f"answer key schema must be {SCHEMA_VERSION}")
    suite_id = require_name(answer_key["suite_id"], "answer key suite_id")
    run_id = require_string(answer_key["run_id"], "answer key run_id")
    if suite_id != manifest_suite_id or run_id != manifest_run_id:
        raise EvaluationError("answer key identity does not match manifest")
    cases = answer_key["cases"]
    if not isinstance(cases, list) or not cases:
        raise EvaluationError("answer key cases must be a non-empty list")
    if len(cases) != manifest["task_count"]:
        raise EvaluationError("answer key case count does not match manifest")
    expected_by_id = {}
    for index, case in enumerate(cases):
        context = f"answer key cases[{index}]"
        if not isinstance(case, dict):
            raise EvaluationError(f"{context} must be an object")
        require_keys(case, {"blind_id", "case_id", "tags", "expected"}, context)
        blind = require_string(case["blind_id"], f"{context}.blind_id")
        if blind in expected_by_id:
            raise EvaluationError(f"duplicate blinded case ID: {blind}")
        expected = case["expected"]
        if not isinstance(expected, dict):
            raise EvaluationError(f"{context}.expected must be an object")
        require_keys(expected, {"selection", "must_not_select"}, f"{context}.expected")
        expected_by_id[blind] = {
            "selection": validate_selection(
                expected["selection"], f"{context}.expected.selection"
            ),
            "must_not_select": require_names(
                expected["must_not_select"], f"{context}.expected.must_not_select"
            ),
        }

    read_tasks(
        manifest_path.parent / "tasks.jsonl",
        manifest["tasks_sha256"],
        manifest_suite_id,
        manifest_run_id,
        manifest["task_count"],
        set(expected_by_id),
    )

    records = [
        validate_result(record, f"results[{index}]")
        for index, record in enumerate(read_jsonl(results_path))
    ]
    stale_run_ids = sorted({record["run_id"] for record in records} - {run_id})
    if stale_run_ids:
        raise EvaluationError(
            "results do not match answer key run_id: " + ", ".join(stale_run_ids)
        )
    unknown = sorted({record["blind_id"] for record in records} - set(expected_by_id))
    if unknown:
        raise EvaluationError(
            "results contain unknown blinded IDs: " + ", ".join(unknown)
        )
    environment_ids = {record["environment_id"] for record in records}
    if len(environment_ids) != 1:
        raise EvaluationError("all result records must use one environment_id")
    undeclared_candidates = sorted(
        {record["candidate_id"] for record in records} - set(candidates)
    )
    if undeclared_candidates:
        raise EvaluationError(
            "results contain undeclared candidates: " + ", ".join(undeclared_candidates)
        )

    grouped: dict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    seen = set()
    for record in records:
        identity = (record["candidate_id"], record["blind_id"], record["trial"])
        if identity in seen:
            raise EvaluationError(f"duplicate result identity: {identity}")
        seen.add(identity)
        grouped[(record["candidate_id"], record["blind_id"])].append(record)

    common_trials: list[int] | None = None
    for candidate in candidates:
        for blind in expected_by_id:
            trials = sorted(
                record["trial"] for record in grouped.get((candidate, blind), [])
            )
            if len(trials) < minimum_trials:
                raise EvaluationError(
                    f"{candidate}/{blind} has {len(trials)} trials; "
                    f"requires {minimum_trials}"
                )
            if trials != list(range(1, max(trials) + 1)):
                raise EvaluationError(
                    f"{candidate}/{blind} trial numbers are not contiguous"
                )
            if common_trials is None:
                common_trials = trials
            elif trials != common_trials:
                raise EvaluationError(
                    f"{candidate}/{blind} trial set differs from other results"
                )

    assert common_trials is not None
    record_by_coordinate = {
        (record["candidate_id"], record["blind_id"], record["trial"]): record
        for record in records
    }
    metrics = (
        "latency_ms",
        "input_tokens",
        "output_tokens",
        "cost_usd",
        "task_passed",
    )
    for blind in expected_by_id:
        for trial in common_trials:
            baseline = record_by_coordinate[(candidates[0], blind, trial)]["evidence"]
            for candidate in candidates[1:]:
                evidence = record_by_coordinate[(candidate, blind, trial)]["evidence"]
                drift = [
                    metric
                    for metric in metrics
                    if (baseline[metric] is None) != (evidence[metric] is None)
                ]
                if drift:
                    raise EvaluationError(
                        f"measurement availability differs at {blind}/{trial}: "
                        + ", ".join(drift)
                    )

    summaries = []
    for candidate in candidates:
        candidate_records = [
            record for record in records if record["candidate_id"] == candidate
        ]
        owner_matches = 0
        method_matches = 0
        overlay_matches = 0
        route_matches = 0
        forbidden_violations = 0
        task_passes = 0
        task_judged = 0
        input_tokens = []
        output_tokens = []
        costs = []
        latencies = []
        degradations = 0
        for record in candidate_records:
            expected = expected_by_id[record["blind_id"]]
            observed = record["observed"]
            owner_ok = observed["owner"] == expected["selection"]["owner"]
            methods_ok = set(observed["methods"]) == set(
                expected["selection"]["methods"]
            )
            overlays_ok = set(observed["overlays"]) == set(
                expected["selection"]["overlays"]
            )
            owner_matches += owner_ok
            method_matches += methods_ok
            overlay_matches += overlays_ok
            route_matches += owner_ok and methods_ok and overlays_ok
            selected = {
                item
                for item in [
                    observed["owner"],
                    *observed["methods"],
                    *observed["overlays"],
                ]
                if item is not None
            }
            forbidden_violations += bool(
                selected.intersection(expected["must_not_select"])
            )
            evidence = record["evidence"]
            if evidence["task_passed"] is not None:
                task_judged += 1
                task_passes += evidence["task_passed"]
            if evidence["latency_ms"] is not None:
                latencies.append(evidence["latency_ms"])
            if evidence["input_tokens"] is not None:
                input_tokens.append(evidence["input_tokens"])
            if evidence["output_tokens"] is not None:
                output_tokens.append(evidence["output_tokens"])
            if evidence["cost_usd"] is not None:
                costs.append(evidence["cost_usd"])
            degradations += evidence["degradation"] is not None
        total_cost = finite_sum(costs, f"{candidate} cost") if costs else None
        summaries.append(
            {
                "candidate_id": candidate,
                "records": len(candidate_records),
                "route_exact": route_matches,
                "route_exact_rate": route_matches / len(candidate_records),
                "owner_exact": owner_matches,
                "owner_exact_rate": owner_matches / len(candidate_records),
                "methods_exact": method_matches,
                "methods_exact_rate": method_matches / len(candidate_records),
                "overlays_exact": overlay_matches,
                "overlays_exact_rate": overlay_matches / len(candidate_records),
                "forbidden_route_violations": forbidden_violations,
                "task_passes": task_passes,
                "task_judged": task_judged,
                "task_pass_rate": task_passes / task_judged if task_judged else None,
                "median_latency_ms": (
                    finite_median(latencies, f"{candidate} latency")
                    if latencies
                    else None
                ),
                "latency_records": len(latencies),
                "input_tokens": sum(input_tokens) if input_tokens else None,
                "input_token_records": len(input_tokens),
                "output_tokens": sum(output_tokens) if output_tokens else None,
                "output_token_records": len(output_tokens),
                "cost_usd": round(total_cost, 8) if total_cost is not None else None,
                "cost_records": len(costs),
                "mean_cost_usd": (
                    round(total_cost / len(costs), 8)
                    if total_cost is not None
                    else None
                ),
                "degraded_records": degradations,
            }
        )
    return {
        "schema_version": SCHEMA_VERSION,
        "suite_id": suite_id,
        "run_id": run_id,
        "environment_id": next(iter(environment_ids)),
        "minimum_trials": minimum_trials,
        "case_count": len(expected_by_id),
        "candidates": summaries,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)

    validate_parser = commands.add_parser("validate", help="validate a corpus")
    validate_parser.add_argument("corpus", type=Path)

    prepare_parser = commands.add_parser("prepare", help="prepare blinded artifacts")
    prepare_parser.add_argument("corpus", type=Path)
    prepare_parser.add_argument("--output", type=Path, required=True)
    prepare_parser.add_argument("--seed", required=True)
    prepare_parser.add_argument("--force", action="store_true")

    score_parser = commands.add_parser("score", help="score result records")
    score_parser.add_argument("manifest", type=Path)
    score_parser.add_argument("answer_key", type=Path)
    score_parser.add_argument("results", type=Path)
    score_parser.add_argument("--minimum-trials", type=int, default=3)
    score_parser.add_argument(
        "--candidate",
        dest="candidates",
        action="append",
        required=True,
        help="declared opaque candidate ID; repeat for every candidate",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.command == "validate":
            payload, raw = read_json(args.corpus)
            corpus = validate_corpus(payload)
            result = {
                "schema_version": SCHEMA_VERSION,
                "suite_id": corpus["suite_id"],
                "case_count": len(corpus["cases"]),
                "corpus_sha256": hashlib.sha256(raw).hexdigest(),
            }
        elif args.command == "prepare":
            result = prepare(args.corpus, args.output, args.seed, args.force)
        else:
            result = score(
                args.manifest,
                args.answer_key,
                args.results,
                args.minimum_trials,
                args.candidates,
            )
        rendered = json_text(result)
    except EvaluationError as error:
        print(f"workflow-eval: {error}", file=sys.stderr)
        return 2
    print(rendered, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
