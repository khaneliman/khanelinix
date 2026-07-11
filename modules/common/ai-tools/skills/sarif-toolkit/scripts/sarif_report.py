#!/usr/bin/env python3
"""Produce bounded SARIF reports and deterministic result partitions."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import tempfile
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Sequence

GENERATED_BY = "sarif-toolkit"
MISSING_RULE = "<no-rule>"
MISSING_PATH = "<no-path>"
MISSING_SEVERITY = "none"
SEVERITY_ORDER = {"error": 0, "warning": 1, "note": 2, "none": 3}
DEFAULT_MAX_TOOLS = 20
DEFAULT_MAX_SEVERITIES = 20
DEFAULT_MAX_SPLIT_FILES = 50
DEFAULT_MAX_VALUE_CHARS = 240


class SarifError(ValueError):
    """Raised when input or requested output is invalid."""


@dataclass(frozen=True)
class ResultRecord:
    run_index: int
    result_index: int
    result: dict[str, Any]
    rule_id: str
    severity: str
    path: str
    line: int | None
    message: str


def require_mapping(value: Any, context: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise SarifError(f"{context} must be a JSON object")
    return value


def require_list(value: Any, context: str) -> list[Any]:
    if not isinstance(value, list):
        raise SarifError(f"{context} must be a JSON array")
    return value


def load_sarif(path: Path) -> dict[str, Any]:
    try:
        with path.open("r", encoding="utf-8") as handle:
            document = json.load(handle)
    except json.JSONDecodeError as error:
        raise SarifError(
            f"invalid JSON at line {error.lineno}, column {error.colno}"
        ) from error
    document = require_mapping(document, "SARIF document")
    runs = require_list(document.get("runs", []), "runs")
    for run_index, run in enumerate(runs):
        run = require_mapping(run, f"runs[{run_index}]")
        require_list(run.get("results", []), f"runs[{run_index}].results")
        require_list(run.get("artifacts", []), f"runs[{run_index}].artifacts")
    return document


def driver_for(run: dict[str, Any]) -> dict[str, Any]:
    tool = run.get("tool", {})
    if not isinstance(tool, dict):
        return {}
    driver = tool.get("driver", {})
    return driver if isinstance(driver, dict) else {}


def rule_levels(run: dict[str, Any]) -> dict[str, str]:
    levels: dict[str, str] = {}
    rules = driver_for(run).get("rules", [])
    if not isinstance(rules, list):
        return levels
    for rule in rules:
        if not isinstance(rule, dict) or not isinstance(rule.get("id"), str):
            continue
        configuration = rule.get("defaultConfiguration", {})
        if isinstance(configuration, dict) and isinstance(
            configuration.get("level"), str
        ):
            levels[rule["id"]] = configuration["level"]
    return levels


def rule_ids(run: dict[str, Any]) -> list[str]:
    rules = driver_for(run).get("rules", [])
    if not isinstance(rules, list):
        return []
    return [
        rule["id"]
        if isinstance(rule, dict) and isinstance(rule.get("id"), str)
        else MISSING_RULE
        for rule in rules
    ]


def artifact_uris(run: dict[str, Any]) -> list[str]:
    uris: list[str] = []
    for artifact in run.get("artifacts", []):
        location = artifact.get("location", {}) if isinstance(artifact, dict) else {}
        uri = location.get("uri") if isinstance(location, dict) else None
        uris.append(uri if isinstance(uri, str) and uri else MISSING_PATH)
    return uris


def message_text(result: dict[str, Any]) -> str:
    message = result.get("message", {})
    if isinstance(message, str):
        return message
    if not isinstance(message, dict):
        return ""
    for key in ("text", "markdown", "id"):
        value = message.get(key)
        if isinstance(value, str):
            return value
    return ""


def first_location(
    result: dict[str, Any], artifacts: list[str]
) -> tuple[str, int | None]:
    locations = result.get("locations", [])
    if not isinstance(locations, list):
        return MISSING_PATH, None
    for location in locations:
        if not isinstance(location, dict):
            continue
        physical = location.get("physicalLocation", {})
        if not isinstance(physical, dict):
            continue
        artifact = physical.get("artifactLocation", {})
        region = physical.get("region", {})
        path = artifact.get("uri") if isinstance(artifact, dict) else None
        artifact_index = artifact.get("index") if isinstance(artifact, dict) else None
        if (
            (not isinstance(path, str) or not path)
            and isinstance(artifact_index, int)
            and 0 <= artifact_index < len(artifacts)
        ):
            path = artifacts[artifact_index]
        line = region.get("startLine") if isinstance(region, dict) else None
        if isinstance(path, str) and path:
            return path, line if isinstance(line, int) else None

    logical_locations = result.get("logicalLocations", [])
    if isinstance(logical_locations, list):
        for location in logical_locations:
            if not isinstance(location, dict):
                continue
            logical_name = location.get("fullyQualifiedName") or location.get("name")
            if isinstance(logical_name, str) and logical_name:
                return f"logical:{logical_name}", None
    return MISSING_PATH, None


def effective_severity(
    result: dict[str, Any], rule_id: str, defaults: dict[str, str]
) -> str:
    level = result.get("level")
    if isinstance(level, str) and level:
        return level.casefold()
    properties = result.get("properties", {})
    if isinstance(properties, dict):
        problem_severity = properties.get("problem.severity")
        if isinstance(problem_severity, str) and problem_severity:
            return problem_severity.casefold()
    return defaults.get(rule_id, MISSING_SEVERITY).casefold()


def result_records(document: dict[str, Any]) -> list[ResultRecord]:
    records: list[ResultRecord] = []
    for run_index, run_value in enumerate(document.get("runs", [])):
        run = require_mapping(run_value, f"runs[{run_index}]")
        defaults = rule_levels(run)
        indexed_rule_ids = rule_ids(run)
        artifacts = artifact_uris(run)
        for result_index, result_value in enumerate(run.get("results", [])):
            result = require_mapping(
                result_value, f"runs[{run_index}].results[{result_index}]"
            )
            rule_id = result.get("ruleId")
            if not isinstance(rule_id, str) or not rule_id:
                rule_index = result.get("ruleIndex")
                rule_id = (
                    indexed_rule_ids[rule_index]
                    if isinstance(rule_index, int)
                    and 0 <= rule_index < len(indexed_rule_ids)
                    else MISSING_RULE
                )
            path, line = first_location(result, artifacts)
            records.append(
                ResultRecord(
                    run_index=run_index,
                    result_index=result_index,
                    result=result,
                    rule_id=rule_id,
                    severity=effective_severity(result, rule_id, defaults),
                    path=path,
                    line=line,
                    message=message_text(result),
                )
            )
    return records


def sorted_counts(
    values: Iterable[str], limit: int | None = None
) -> list[dict[str, Any]]:
    entries = sorted(
        Counter(values).items(),
        key=lambda item: (-item[1], item[0].casefold(), item[0]),
    )
    if limit is not None:
        entries = entries[:limit]
    return [{"value": value, "count": count} for value, count in entries]


def clipped(value: str, limit: int = DEFAULT_MAX_VALUE_CHARS) -> str:
    normalized = re.sub(r"\s+", " ", value).strip()
    if limit == 0 or len(normalized) <= limit:
        return normalized
    if limit == 1:
        return "…"
    return normalized[: limit - 1].rstrip() + "…"


def bounded_values(values: Sequence[Any], maximum: int) -> tuple[list[Any], int]:
    selected = list(values if maximum == 0 else values[:maximum])
    return selected, len(values) - len(selected)


def tool_summary(
    run_index: int, run: dict[str, Any], maximum_value_chars: int
) -> dict[str, Any]:
    driver = driver_for(run)
    summary: dict[str, Any] = {
        "run": run_index,
        "name": clipped(
            driver.get("name") if isinstance(driver.get("name"), str) else "<unknown>",
            maximum_value_chars,
        ),
    }
    for key in ("version", "semanticVersion", "informationUri"):
        if isinstance(driver.get(key), str):
            summary[key] = clipped(driver[key], maximum_value_chars)
    return summary


def summarize(
    document: dict[str, Any],
    *,
    top: int = 10,
    representatives: int = 5,
    maximum_tools: int = DEFAULT_MAX_TOOLS,
    maximum_severities: int = DEFAULT_MAX_SEVERITIES,
    maximum_value_chars: int = DEFAULT_MAX_VALUE_CHARS,
) -> dict[str, Any]:
    if (
        top < 1
        or min(
            representatives,
            maximum_tools,
            maximum_severities,
            maximum_value_chars,
        )
        < 0
    ):
        raise SarifError("summary limits are invalid")
    runs = [require_mapping(run, "run") for run in document.get("runs", [])]
    records = result_records(document)
    representative_records = sorted(
        records,
        key=lambda record: (
            SEVERITY_ORDER.get(record.severity, 4),
            record.run_index,
            record.result_index,
        ),
    )[:representatives]

    all_tools = [
        tool_summary(index, run, maximum_value_chars) for index, run in enumerate(runs)
    ]
    tools, tools_omitted = bounded_values(all_tools, maximum_tools)
    all_rules = sorted_counts(record.rule_id for record in records)
    selected_rules = all_rules[:top]
    all_severities = sorted_counts(record.severity for record in records)
    selected_severities, severities_omitted = bounded_values(
        all_severities, maximum_severities
    )
    all_paths = sorted_counts(record.path for record in records)
    selected_paths = all_paths[:top]
    schema = document.get("$schema")
    version = document.get("version")

    report: dict[str, Any] = {
        "schema": clipped(schema, maximum_value_chars)
        if isinstance(schema, str)
        else None,
        "version": clipped(version, maximum_value_chars)
        if isinstance(version, str)
        else None,
        "runs": len(runs),
        "tools": tools,
        "tools_total": len(all_tools),
        "tools_omitted": tools_omitted,
        "tools_truncated": tools_omitted > 0,
        "results": len(records),
        "artifacts": sum(len(run.get("artifacts", [])) for run in runs),
        "top_rules": [
            {
                "rule_id": clipped(entry["value"], maximum_value_chars),
                "count": entry["count"],
            }
            for entry in selected_rules
        ],
        "top_rules_total": len(all_rules),
        "top_rules_omitted": len(all_rules) - len(selected_rules),
        "top_rules_truncated": len(selected_rules) < len(all_rules),
        "severities": [
            {
                "level": clipped(entry["value"], maximum_value_chars),
                "count": entry["count"],
            }
            for entry in selected_severities
        ],
        "severities_total": len(all_severities),
        "severities_omitted": severities_omitted,
        "severities_truncated": severities_omitted > 0,
        "affected_paths": [
            {
                "path": clipped(entry["value"], maximum_value_chars),
                "count": entry["count"],
            }
            for entry in selected_paths
        ],
        "affected_paths_total": len(all_paths),
        "affected_paths_omitted": len(all_paths) - len(selected_paths),
        "affected_paths_truncated": len(selected_paths) < len(all_paths),
        "representative_results": [],
    }
    for record in representative_records:
        representative: dict[str, Any] = {
            "run": record.run_index,
            "index": record.result_index,
            "rule_id": clipped(record.rule_id, maximum_value_chars),
            "level": clipped(record.severity, maximum_value_chars),
            "path": clipped(record.path, maximum_value_chars),
            "message": clipped(record.message, maximum_value_chars),
        }
        if record.line is not None:
            representative["line"] = record.line
        report["representative_results"].append(representative)
    return report


def partition_records(
    records: list[ResultRecord], strategy: str, chunks: int | None = None
) -> list[tuple[str, list[ResultRecord]]]:
    if strategy == "balanced":
        if chunks is None or chunks < 1:
            raise SarifError(
                "--chunks must be a positive integer for balanced splitting"
            )
        if not records:
            return []
        buckets: list[list[ResultRecord]] = [
            [] for _ in range(min(chunks, len(records)))
        ]
        for index, record in enumerate(records):
            buckets[index % len(buckets)].append(record)
        return [
            (f"balanced-{index:04d}", bucket)
            for index, bucket in enumerate(buckets, start=1)
        ]

    if chunks is not None:
        raise SarifError("--chunks applies only to balanced splitting")
    field = {
        "rule": "rule_id",
        "path": "path",
        "severity": "severity",
    }.get(strategy)
    if field is None:
        raise SarifError(f"unsupported split strategy: {strategy}")

    grouped: dict[str, list[ResultRecord]] = defaultdict(list)
    for record in records:
        grouped[str(getattr(record, field))].append(record)
    return [
        (key, grouped[key])
        for key in sorted(grouped, key=lambda value: (value.casefold(), value))
    ]


def stable_filename(index: int, strategy: str, key: str) -> str:
    if strategy == "balanced":
        return f"{index:04d}-balanced.sarif"
    slug = re.sub(r"[^a-z0-9]+", "-", key.casefold()).strip("-")[:48] or "unknown"
    digest = hashlib.sha256(key.encode("utf-8")).hexdigest()[:8]
    return f"{index:04d}-{slug}-{digest}.sarif"


def document_for_records(
    document: dict[str, Any], records: list[ResultRecord]
) -> dict[str, Any]:
    selected: dict[int, set[int]] = defaultdict(set)
    for record in records:
        selected[record.run_index].add(record.result_index)

    output = dict(document)
    output_runs: list[dict[str, Any]] = []
    for run_index, run_value in enumerate(document.get("runs", [])):
        if run_index not in selected:
            continue
        run = require_mapping(run_value, f"runs[{run_index}]")
        output_run = dict(run)
        output_run["results"] = [
            result
            for result_index, result in enumerate(run.get("results", []))
            if result_index in selected[run_index]
        ]
        output_runs.append(output_run)
    output["runs"] = output_runs
    return output


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def atomic_json_write(path: Path, value: dict[str, Any]) -> None:
    temporary: str | None = None
    try:
        with tempfile.NamedTemporaryFile(
            "w",
            encoding="utf-8",
            dir=path.parent,
            prefix=f".{path.name}.",
            delete=False,
        ) as handle:
            temporary = handle.name
            json.dump(value, handle, indent=2, sort_keys=True, ensure_ascii=False)
            handle.write("\n")
        os.replace(temporary, path)
        temporary = None
    finally:
        if temporary is not None:
            Path(temporary).unlink(missing_ok=True)


def previous_outputs(output_dir: Path) -> tuple[bool, set[str]]:
    manifest_path = output_dir / "manifest.json"
    if not manifest_path.is_file():
        return False, set()
    try:
        manifest = json.loads(read_text(manifest_path))
    except (json.JSONDecodeError, OSError):
        return False, set()
    if not isinstance(manifest, dict) or manifest.get("generated_by") != GENERATED_BY:
        return False, set()
    files = manifest.get("files", [])
    if not isinstance(files, list):
        return True, set()
    names: set[str] = set()
    for item in files:
        if not isinstance(item, dict) or not isinstance(item.get("path"), str):
            continue
        name = item["path"]
        if Path(name).name == name:
            names.add(name)
    return True, names


def prepare_output_directory(
    output_dir: Path, planned_names: set[str], force: bool
) -> None:
    if output_dir.exists() and not output_dir.is_dir():
        raise SarifError(f"output path is not a directory: {output_dir}")
    if output_dir.is_dir() and any(output_dir.iterdir()) and not force:
        raise SarifError(
            f"output directory is not empty; pass --force to overwrite: {output_dir}"
        )
    output_dir.mkdir(parents=True, exist_ok=True)
    if not force:
        return

    owns_manifest, owned_names = previous_outputs(output_dir)
    manifest_path = output_dir / "manifest.json"
    if manifest_path.exists() and not owns_manifest:
        raise SarifError("refusing to replace manifest.json not owned by sarif-toolkit")

    for name in planned_names:
        candidate = output_dir / name
        if (candidate.exists() or candidate.is_symlink()) and name not in owned_names:
            raise SarifError(f"refusing to replace unowned output file: {name}")

    for name in sorted(owned_names):
        candidate = output_dir / name
        if candidate.exists() and not (candidate.is_file() or candidate.is_symlink()):
            raise SarifError(f"refusing to remove non-file generated output: {name}")

    for name in sorted(owned_names):
        candidate = output_dir / name
        if candidate.is_file() or candidate.is_symlink():
            candidate.unlink()


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def write_split(
    source: Path,
    document: dict[str, Any],
    *,
    strategy: str,
    chunks: int | None,
    output_dir: Path,
    force: bool = False,
    maximum_report_files: int = DEFAULT_MAX_SPLIT_FILES,
    maximum_value_chars: int = DEFAULT_MAX_VALUE_CHARS,
) -> dict[str, Any]:
    if maximum_report_files < 0 or maximum_value_chars < 0:
        raise SarifError("split report limits cannot be negative")
    records = result_records(document)
    groups = partition_records(records, strategy, chunks)
    planned = [
        (stable_filename(index, strategy, key), key, group)
        for index, (key, group) in enumerate(groups, start=1)
    ]
    prepare_output_directory(output_dir, {item[0] for item in planned}, force)

    manifest_files: list[dict[str, Any]] = []
    for filename, key, group in planned:
        run_counts = Counter(record.run_index for record in group)
        atomic_json_write(output_dir / filename, document_for_records(document, group))
        manifest_files.append(
            {
                "path": filename,
                "group": key,
                "results": len(group),
                "runs": {str(run): count for run, count in sorted(run_counts.items())},
            }
        )

    manifest: dict[str, Any] = {
        "generated_by": GENERATED_BY,
        "source": source.name,
        "source_sha256": sha256_file(source),
        "strategy": strategy,
        "results": len(records),
        "files": manifest_files,
    }
    if strategy == "balanced":
        manifest["requested_chunks"] = chunks
    atomic_json_write(output_dir / "manifest.json", manifest)
    selected_files, files_omitted = bounded_values(manifest_files, maximum_report_files)
    report_files = [
        {
            "group": clipped(str(item["group"]), maximum_value_chars),
            "path": clipped(str(item["path"]), maximum_value_chars),
            "results": item["results"],
            "runs_total": len(item["runs"]),
        }
        for item in selected_files
    ]
    return {
        "strategy": strategy,
        "output_dir": str(output_dir),
        "files": report_files,
        "files_total": len(manifest_files),
        "files_omitted": files_omitted,
        "files_truncated": files_omitted > 0,
        "manifest": "manifest.json",
    }


def markdown_cell(value: object) -> str:
    return str(value).replace("|", "\\|").replace("\n", " ")


def render_markdown(report: dict[str, Any]) -> str:
    lines = [
        "# SARIF Report",
        "",
        f"- Schema: `{report.get('schema') or '<unspecified>'}`",
        f"- Version: `{report.get('version') or '<unspecified>'}`",
        f"- Runs: {report['runs']}",
        f"- Results: {report['results']}",
        f"- Artifacts: {report['artifacts']}",
        "",
        "## Tools",
        "",
        "| Run | Tool | Version |",
        "| ---: | --- | --- |",
    ]
    for tool in report["tools"]:
        version = tool.get("semanticVersion") or tool.get("version") or ""
        lines.append(
            f"| {tool['run']} | {markdown_cell(tool['name'])} | {markdown_cell(version)} |"
        )
    if report["tools_omitted"]:
        lines.append(f"\n{report['tools_omitted']} tool(s) omitted.")

    for heading, key, label in (
        ("Top rules", "top_rules", "rule_id"),
        ("Severities", "severities", "level"),
        ("Affected paths", "affected_paths", "path"),
    ):
        lines.extend(["", f"## {heading}", "", "| Value | Count |", "| --- | ---: |"])
        for entry in report[key]:
            lines.append(f"| {markdown_cell(entry[label])} | {entry['count']} |")
        omitted_key = {
            "top_rules": "top_rules_omitted",
            "severities": "severities_omitted",
            "affected_paths": "affected_paths_omitted",
        }[key]
        if report[omitted_key]:
            lines.append(f"\n{report[omitted_key]} value(s) omitted.")

    lines.extend(
        [
            "",
            "## Representative results",
            "",
            "| Rule | Level | Location | Message |",
            "| --- | --- | --- | --- |",
        ]
    )
    for result in report["representative_results"]:
        location = result["path"]
        if "line" in result:
            location += f":{result['line']}"
        lines.append(
            "| "
            + " | ".join(
                markdown_cell(value)
                for value in (
                    result["rule_id"],
                    result["level"],
                    location,
                    result["message"],
                )
            )
            + " |"
        )

    if "split" in report:
        split = report["split"]
        lines.extend(
            [
                "",
                "## Split output",
                "",
                f"- Strategy: `{split['strategy']}`",
                f"- Directory: `{split['output_dir']}`",
                f"- Files: {len(split['files'])}/{split['files_total']} shown",
                f"- Files omitted: {split['files_omitted']}",
                f"- Manifest: `{split['manifest']}`",
            ]
        )
    return "\n".join(lines) + "\n"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Summarize SARIF and optionally write deterministic result chunks."
    )
    parser.add_argument("sarif_file", type=Path)
    parser.add_argument("--format", choices=("json", "markdown"), default="markdown")
    parser.add_argument(
        "--top", type=int, default=10, help="maximum rules and paths to report"
    )
    parser.add_argument(
        "--representatives", type=int, default=5, help="maximum representative results"
    )
    parser.add_argument(
        "--max-tools",
        type=int,
        default=DEFAULT_MAX_TOOLS,
        help="maximum tools to report; 0 means unlimited",
    )
    parser.add_argument(
        "--max-severities",
        type=int,
        default=DEFAULT_MAX_SEVERITIES,
        help="maximum severity values to report; 0 means unlimited",
    )
    parser.add_argument(
        "--max-value-chars",
        type=int,
        default=DEFAULT_MAX_VALUE_CHARS,
        help="maximum characters per reported scalar; 0 means unlimited",
    )
    parser.add_argument(
        "--max-split-files",
        type=int,
        default=DEFAULT_MAX_SPLIT_FILES,
        help="maximum split files listed in stdout; manifest stays complete",
    )
    parser.add_argument("--split", choices=("rule", "path", "severity", "balanced"))
    parser.add_argument("--chunks", type=int)
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--force", action="store_true")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        if (
            args.top < 1
            or min(
                args.representatives,
                args.max_tools,
                args.max_severities,
                args.max_value_chars,
                args.max_split_files,
            )
            < 0
        ):
            raise SarifError(
                "--top must be positive and report limits cannot be negative"
            )
        if args.output_dir is not None and args.split is None:
            raise SarifError("--output-dir requires --split")
        if args.force and args.split is None:
            raise SarifError("--force requires --split")
        document = load_sarif(args.sarif_file)
        report = summarize(
            document,
            top=args.top,
            representatives=args.representatives,
            maximum_tools=args.max_tools,
            maximum_severities=args.max_severities,
            maximum_value_chars=args.max_value_chars,
        )
        if args.split is not None:
            output_dir = args.output_dir or args.sarif_file.with_name(
                f"{args.sarif_file.stem}-{args.split}-split"
            )
            report["split"] = write_split(
                args.sarif_file,
                document,
                strategy=args.split,
                chunks=args.chunks,
                output_dir=output_dir,
                force=args.force,
                maximum_report_files=args.max_split_files,
                maximum_value_chars=args.max_value_chars,
            )
        elif args.chunks is not None:
            raise SarifError("--chunks requires --split balanced")

        if args.format == "json":
            json.dump(report, sys.stdout, indent=2, sort_keys=True, ensure_ascii=False)
            sys.stdout.write("\n")
        else:
            sys.stdout.write(render_markdown(report))
        return 0
    except (OSError, SarifError) as error:
        print(f"sarif-report: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
