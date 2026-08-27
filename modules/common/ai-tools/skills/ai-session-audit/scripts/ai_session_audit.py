#!/usr/bin/env python3
"""Audit scrubbed metrics from T3 canonical AI provider events."""

from __future__ import annotations

import argparse
import functools
import hashlib
import json
import re
import statistics
import sys
from collections import Counter
from collections.abc import Iterable, Sequence
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

SCHEMA_VERSION = 1
DEFAULT_SOURCE = Path.home() / ".t3" / "userdata" / "logs" / "provider"
CANON_LINE = re.compile(r"^\[[^\]\r\n]+\] CANON: (.*)$")
SKILL_PATH = re.compile(
    r"(?:^|[/\\])skills[/\\](?:\.system[/\\])?"
    r"([A-Za-z0-9][A-Za-z0-9._:-]*)[/\\]SKILL\.md"
)
SAFE_IDENTIFIER = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._:+/@\[\]-]{0,95}$")
ANSI_MODEL_SUFFIX = re.compile(r"(?:\[[0-9;]+m\])+$")
SKILL_NAME_LINE = re.compile(r"^name:\s*[\"']?([^\"'\r\n]+)[\"']?\s*$", re.MULTILINE)
SECRET_PREFIXES = ("AKIA", "ASIA", "AIza", "ghp_", "github_pat_", "sk-", "sk_", "xox")
KNOWN_TOOLS = {
    "Agent",
    "AskUserQuestion",
    "Bash",
    "Edit",
    "Glob",
    "Grep",
    "NotebookEdit",
    "Read",
    "Skill",
    "TaskOutput",
    "TaskStop",
    "TodoWrite",
    "WebFetch",
    "WebSearch",
    "Write",
    "closeAgent",
    "file_change",
    "image_view",
    "mcp_tool",
    "resumeAgent",
    "sendInput",
    "shell",
    "spawnAgent",
    "wait",
    "web_search",
}
BUILTIN_MODELS = {
    "default",
    "fable",
    "haiku",
    "opus",
    "sonnet",
}
BUILTIN_ROLES = {
    "checker",
    "debugger",
    "explorer",
    "fact-finder",
    "general-purpose",
    "implementer",
    "mechanic",
    "probe-runner",
    "reviewer",
    "test-runner",
    "worker",
}
KNOWN_EFFORTS = {"low", "medium", "high", "xhigh", "max"}
ALLOWED_PROVIDERS = {"claudeAgent", "codex"}
ALLOWED_EVENT_TYPES = {
    "account.rate-limits.updated",
    "config.warning",
    "hook.completed",
    "hook.started",
    "item.completed",
    "item.started",
    "runtime.warning",
    "session.configured",
    "session.exited",
    "session.started",
    "session.state.changed",
    "task.completed",
    "task.started",
    "task.updated",
    "thread.started",
    "thread.state.changed",
    "thread.token-usage.updated",
    "tool.denied",
    "turn.completed",
    "turn.diff.updated",
    "turn.plan.updated",
    "turn.started",
    "user-input.requested",
    "user-input.resolved",
}
ALLOWED_ITEM_TYPES = {
    "assistant_message",
    "collab_agent_tool_call",
    "command_execution",
    "context_compaction",
    "dynamic_tool_call",
    "file_change",
    "image_view",
    "mcp_tool_call",
    "reasoning",
    "user_message",
    "web_search",
}
ALLOWED_STATUSES = {
    "cancelled",
    "completed",
    "declined",
    "errored",
    "failed",
    "in_progress",
    "idle",
    "interrupted",
    "pending",
    "running",
    "stopped",
    "timed_out",
}
STATUS_ALIASES = {"inProgress": "in_progress"}


class AuditError(ValueError):
    """Raised when input or requested output is invalid."""


@dataclass
class ScanStats:
    files: int = 0
    lines: int = 0
    canonical_lines: int = 0
    malformed_events: int = 0
    duplicate_events: int = 0
    missing_event_ids: int = 0
    filtered_events: int = 0


def mapping(value: Any) -> dict[str, Any]:
    return value if isinstance(value, dict) else {}


def integer(value: Any) -> int | None:
    return value if isinstance(value, int) and not isinstance(value, bool) else None


def text(value: Any) -> str | None:
    return value if isinstance(value, str) and value else None


def safe_identifier(value: Any, field: str, scrubbed_fields: list[str]) -> str | None:
    if value is None:
        return None
    observed = text(value)
    if observed is None:
        scrubbed_fields.append(field)
        return None
    if SAFE_IDENTIFIER.fullmatch(observed) is None or observed.startswith(
        SECRET_PREFIXES
    ):
        scrubbed_fields.append(field)
        return None
    return observed


def pseudonym(value: str, category: str) -> str:
    digest = hashlib.sha256(value.encode("utf-8")).hexdigest()[:12]
    return f"other-{category}-{digest}"


def safe_taxonomy(
    value: Any,
    field: str,
    known: set[str],
    category: str,
    scrubbed_fields: list[str],
) -> str | None:
    if value is None:
        return None
    observed = text(value)
    if observed is None:
        scrubbed_fields.append(field)
        return None
    if observed in known:
        return observed
    scrubbed_fields.append(field)
    return pseudonym(observed, category)


@functools.lru_cache(maxsize=1)
def known_skill_names() -> frozenset[str]:
    roots = {
        Path(__file__).resolve().parents[2],
        Path.home() / ".config" / "codex" / "skills",
        Path.home() / ".config" / "codex" / "plugins" / "cache",
    }
    names: set[str] = set()
    for root in roots:
        if not root.is_dir():
            continue
        for path in root.rglob("SKILL.md"):
            try:
                header = path.read_text(encoding="utf-8", errors="replace")[:2048]
            except OSError:
                continue
            match = SKILL_NAME_LINE.search(header)
            if match is not None:
                names.add(match.group(1).strip())
    return frozenset(names)


@functools.lru_cache(maxsize=1)
def routing_catalogs() -> tuple[frozenset[str], frozenset[str]]:
    models = set(BUILTIN_MODELS)
    roles = set(BUILTIN_ROLES)
    path = (
        Path(__file__).resolve().parents[2]
        / "multi-provider-sdlc"
        / "references"
        / "model-routing.json"
    )
    try:
        routing = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return frozenset(models), frozenset(roles)
    for model_id, details in mapping(routing.get("models")).items():
        if isinstance(model_id, str):
            models.add(model_id)
        values = mapping(details)
        for field in ("upstream_model", "gateway_alias"):
            value = text(values.get(field))
            if value is not None:
                models.add(value)
    roles.update(
        value
        for value in mapping(routing.get("semantic_roles"))
        if isinstance(value, str)
    )
    roles.update(
        value for value in mapping(routing.get("models")) if isinstance(value, str)
    )
    return frozenset(models), frozenset(roles)


def opaque_identifier(value: Any, field: str, scrubbed_fields: list[str]) -> str | None:
    if value is None:
        return None
    observed = text(value)
    if observed is None:
        scrubbed_fields.append(field)
        return None
    digest = hashlib.sha256(observed.encode("utf-8")).hexdigest()[:16]
    return f"id-{digest}"


def safe_category(
    value: Any,
    field: str,
    allowed: set[str],
    scrubbed_fields: list[str],
) -> str | None:
    if value is None:
        return None
    observed = text(value)
    if observed is None:
        scrubbed_fields.append(field)
        return "unknown"
    if observed not in allowed:
        scrubbed_fields.append(field)
        return "unknown"
    return observed


def safe_model(value: Any, scrubbed_fields: list[str]) -> str | None:
    observed = text(value)
    if observed is None:
        if value is not None:
            scrubbed_fields.append("model")
        return None
    cleaned = ANSI_MODEL_SUFFIX.sub("", observed)
    models, _ = routing_catalogs()
    return safe_taxonomy(cleaned, "model", set(models), "model", scrubbed_fields)


def parse_time(value: str, option: str) -> datetime:
    candidate = value.strip()
    if not candidate:
        raise AuditError(f"{option} must not be empty")
    try:
        parsed = datetime.fromisoformat(candidate.replace("Z", "+00:00"))
    except ValueError as error:
        raise AuditError(f"{option} must be an ISO-8601 date or timestamp") from error
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def safe_timestamp(value: Any, scrubbed_fields: list[str]) -> str | None:
    if value is None:
        return None
    observed = text(value)
    if observed is None:
        scrubbed_fields.append("created_at")
        return None
    try:
        parsed = parse_time(observed, "createdAt")
    except AuditError:
        scrubbed_fields.append("created_at")
        return None
    return parsed.isoformat().replace("+00:00", "Z")


def event_time(event: dict[str, Any]) -> datetime | None:
    value = text(event.get("createdAt"))
    if value is None:
        return None
    try:
        return parse_time(value, "createdAt")
    except AuditError:
        return None


def source_files(sources: Sequence[str] | None) -> list[Path]:
    roots = (
        [Path(value).expanduser() for value in sources] if sources else [DEFAULT_SOURCE]
    )
    files: set[Path] = set()
    for root in roots:
        if root.is_file():
            files.add(root)
        elif root.is_dir():
            files.update(path for path in root.rglob("events.*.log*") if path.is_file())
        else:
            raise AuditError(f"source does not exist: {root}")
    if not files:
        joined = ", ".join(str(root) for root in roots)
        raise AuditError(f"no T3 provider event logs found under: {joined}")
    return sorted(files)


def canonical_events(
    files: Sequence[Path],
    stats: ScanStats,
    *,
    since: datetime | None,
    until: datetime | None,
    providers: set[str],
    thread_id: str | None,
    strict: bool,
) -> Iterable[dict[str, Any]]:
    seen: set[str] = set()
    stats.files = len(files)
    for path in files:
        with path.open("r", encoding="utf-8", errors="replace") as handle:
            for line_number, line in enumerate(handle, start=1):
                stats.lines += 1
                match = CANON_LINE.match(line)
                if match is None:
                    continue
                stats.canonical_lines += 1
                payload = match.group(1)
                try:
                    event = json.loads(payload)
                except json.JSONDecodeError as error:
                    stats.malformed_events += 1
                    if strict:
                        raise AuditError(
                            f"invalid canonical JSON in {path}:{line_number}: {error.msg}"
                        ) from error
                    continue
                if not isinstance(event, dict):
                    stats.malformed_events += 1
                    if strict:
                        raise AuditError(
                            f"canonical event in {path}:{line_number} is not an object"
                        )
                    continue
                event_id = text(event.get("eventId")) or text(event.get("id"))
                if event_id is None:
                    stats.missing_event_ids += 1
                    if strict:
                        raise AuditError(
                            f"canonical event in {path}:{line_number} has no event ID"
                        )
                    fingerprint = hashlib.sha256(
                        json.dumps(event, sort_keys=True, separators=(",", ":")).encode(
                            "utf-8"
                        )
                    ).hexdigest()
                    event_id = f"missing:{fingerprint}"
                if event_id in seen:
                    stats.duplicate_events += 1
                    continue
                seen.add(event_id)

                created = event_time(event)
                provider = text(event.get("provider"))
                event_thread = text(event.get("threadId"))
                if since is not None and (created is None or created < since):
                    stats.filtered_events += 1
                    continue
                if until is not None and (created is None or created >= until):
                    stats.filtered_events += 1
                    continue
                if providers and provider not in providers:
                    stats.filtered_events += 1
                    continue
                if thread_id is not None and event_thread != thread_id:
                    stats.filtered_events += 1
                    continue
                yield event


def token_value(
    usage: dict[str, Any], current: str, last: str | None = None
) -> int | None:
    if last is not None:
        observed = integer(usage.get(last))
        if observed is not None:
            return observed
    return integer(usage.get(current))


def tool_details(
    provider: str | None, payload: dict[str, Any]
) -> tuple[
    str | None,
    list[str],
    str | None,
    str | None,
    str | None,
    str | None,
    int | None,
    list[str],
]:
    item_type = text(payload.get("itemType"))
    data = mapping(payload.get("data"))
    tool_name: str | None = None
    skills: set[str] = set()
    detection: str | None = None
    role: str | None = None
    model: str | None = None
    effort: str | None = None
    duration_ms: int | None = None
    scrubbed_fields: list[str] = []
    _, roles = routing_catalogs()
    skills_catalog = set(known_skill_names())

    if provider == "claudeAgent":
        raw_tool = text(data.get("toolName"))
        tool_name = (
            "mcp_tool"
            if raw_tool is not None and raw_tool.startswith("mcp__")
            else safe_taxonomy(
                raw_tool, "tool_name", KNOWN_TOOLS, "tool", scrubbed_fields
            )
        )
        tool_input = mapping(data.get("input"))
        if tool_name == "Skill":
            skill = safe_taxonomy(
                tool_input.get("skill"),
                "skill_name",
                skills_catalog,
                "skill",
                scrubbed_fields,
            )
            if skill is not None:
                skills.add(skill)
                detection = "tool"
        if tool_name == "Agent":
            role = safe_taxonomy(
                tool_input.get("subagent_type"),
                "agent_role",
                set(roles),
                "role",
                scrubbed_fields,
            )
            model = safe_model(tool_input.get("model"), scrubbed_fields)
    elif provider == "codex":
        item = mapping(data.get("item"))
        duration_ms = integer(item.get("durationMs"))
        if item_type == "collab_agent_tool_call":
            tool_name = safe_taxonomy(
                item.get("tool"), "tool_name", KNOWN_TOOLS, "tool", scrubbed_fields
            )
            model = safe_model(item.get("model"), scrubbed_fields)
            effort = safe_category(
                item.get("reasoningEffort"),
                "reasoning_effort",
                KNOWN_EFFORTS,
                scrubbed_fields,
            )
        elif item_type == "command_execution":
            tool_name = "shell"
            command = text(item.get("command")) or ""
            for observed_skill in SKILL_PATH.findall(command):
                skill = safe_taxonomy(
                    observed_skill,
                    "skill_name",
                    skills_catalog,
                    "skill",
                    scrubbed_fields,
                )
                if skill is not None:
                    skills.add(skill)
            if skills:
                detection = "skill-path-reference"
        elif item_type == "file_change":
            tool_name = "file_change"
        elif item_type == "mcp_tool_call":
            tool_name = "mcp_tool"
        elif item_type in {"image_view", "web_search"}:
            tool_name = item_type

    return (
        tool_name,
        sorted(skills),
        detection,
        role,
        model,
        effort,
        duration_ms,
        sorted(set(scrubbed_fields)),
    )


def normalize(
    event: dict[str, Any], policy_revision: str | None = None
) -> dict[str, Any]:
    payload = mapping(event.get("payload"))
    raw_provider = text(event.get("provider"))
    raw_event_type = text(event.get("type"))
    raw_item_type = text(payload.get("itemType"))
    tool_name: str | None = None
    skills: list[str] = []
    skill_detection: str | None = None
    agent_role: str | None = None
    model: str | None = None
    effort: str | None = None
    duration_ms: int | None = None
    scrubbed_fields: list[str] = []

    if raw_event_type in {"item.started", "item.completed"}:
        (
            tool_name,
            skills,
            skill_detection,
            agent_role,
            model,
            effort,
            duration_ms,
            scrubbed_fields,
        ) = tool_details(raw_provider, payload)

    if raw_event_type == "session.configured":
        config = mapping(payload.get("config"))
        model = safe_model(config.get("model"), scrubbed_fields)
        effort = safe_category(
            config.get("effort"),
            "reasoning_effort",
            KNOWN_EFFORTS,
            scrubbed_fields,
        )
    elif raw_event_type in {"task.started", "task.completed"}:
        _, roles = routing_catalogs()
        agent_role = safe_taxonomy(
            payload.get("role"),
            "agent_role",
            set(roles),
            "role",
            scrubbed_fields,
        )
        model = safe_model(payload.get("model"), scrubbed_fields)
        effort = safe_category(
            payload.get("effort"),
            "reasoning_effort",
            KNOWN_EFFORTS,
            scrubbed_fields,
        )

    usage = mapping(payload.get("usage"))
    is_codex = raw_provider == "codex"
    input_tokens = token_value(
        usage, "inputTokens", "lastInputTokens" if is_codex else None
    )
    cached_input_tokens = token_value(
        usage, "cachedInputTokens", "lastCachedInputTokens" if is_codex else None
    )
    output_tokens = token_value(
        usage, "outputTokens", "lastOutputTokens" if is_codex else None
    )
    reasoning_output_tokens = token_value(
        usage,
        "reasoningOutputTokens",
        "lastReasoningOutputTokens" if is_codex else None,
    )

    provider = safe_category(
        raw_provider, "provider", ALLOWED_PROVIDERS, scrubbed_fields
    )
    event_type = safe_category(
        raw_event_type, "event_type", ALLOWED_EVENT_TYPES, scrubbed_fields
    )
    item_type = safe_category(
        raw_item_type, "item_type", ALLOWED_ITEM_TYPES, scrubbed_fields
    )
    raw_status = payload.get("status")
    observed_status = text(raw_status)
    normalized_status = (
        STATUS_ALIASES.get(observed_status, observed_status)
        if observed_status is not None
        else raw_status
    )
    status = safe_category(
        normalized_status, "status", ALLOWED_STATUSES, scrubbed_fields
    )

    return {
        "schema_version": SCHEMA_VERSION,
        "policy_revision": policy_revision,
        "source_event_id": opaque_identifier(
            event.get("eventId") or event.get("id"),
            "source_event_id",
            scrubbed_fields,
        ),
        "created_at": safe_timestamp(event.get("createdAt"), scrubbed_fields),
        "provider": provider,
        "thread_id": opaque_identifier(
            event.get("threadId"), "thread_id", scrubbed_fields
        ),
        "turn_id": opaque_identifier(event.get("turnId"), "turn_id", scrubbed_fields),
        "event_type": event_type,
        "item_type": item_type,
        "status": status,
        "duration_ms": duration_ms,
        "tool_name": tool_name,
        "skill_names": skills,
        "skill_detection": skill_detection,
        "task_id": opaque_identifier(payload.get("taskId"), "task_id", scrubbed_fields),
        "agent_role": agent_role,
        "model": model,
        "reasoning_effort": effort,
        "scrubbed_fields": sorted(set(scrubbed_fields)),
        "input_tokens": input_tokens,
        "cached_input_tokens": cached_input_tokens,
        "output_tokens": output_tokens,
        "reasoning_output_tokens": reasoning_output_tokens,
        "context_tokens": integer(usage.get("usedTokens")),
        "total_processed_tokens": integer(usage.get("totalProcessedTokens")),
    }


def chronological_key(event: dict[str, Any]) -> tuple[datetime, str, str]:
    created_at = text(event.get("created_at"))
    if created_at is None:
        created = datetime.min.replace(tzinfo=timezone.utc)
    else:
        try:
            created = parse_time(created_at, "created_at")
        except AuditError:
            created = datetime.min.replace(tzinfo=timezone.utc)
    return (
        created,
        text(event.get("source_event_id")) or "",
        text(event.get("event_type")) or "",
    )


def counter_rows(counter: Counter[str], key: str) -> list[dict[str, Any]]:
    return [{key: name, "count": count} for name, count in counter.most_common()]


def tuple_counter_rows(
    counter: Counter[tuple[str, ...]], keys: Sequence[str]
) -> list[dict[str, Any]]:
    return [
        {**dict(zip(keys, values, strict=True)), "count": count}
        for values, count in counter.most_common()
    ]


def finite_ratio(numerator: int, denominator: int) -> float | None:
    return round(numerator / denominator, 3) if denominator else None


def summarize(
    events: Sequence[dict[str, Any]],
    stats: ScanStats,
    *,
    sources: Sequence[Path],
    since: str | None,
    until: str | None,
    providers: Sequence[str],
    selected_thread: str | None,
    policy_revision: str | None,
    top: int,
) -> dict[str, Any]:
    tools: Counter[str] = Counter()
    tools_by_provider: Counter[tuple[str, ...]] = Counter()
    skills: Counter[str] = Counter()
    skill_detection: Counter[str] = Counter()
    skills_by_evidence: Counter[tuple[str, ...]] = Counter()
    roles: Counter[str] = Counter()
    roles_by_provider: Counter[tuple[str, ...]] = Counter()
    models: Counter[str] = Counter()
    models_by_provider: Counter[tuple[str, ...]] = Counter()
    session_models_by_provider: Counter[tuple[str, ...]] = Counter()
    delegation_models_by_provider: Counter[tuple[str, ...]] = Counter()
    efforts: Counter[str] = Counter()
    efforts_by_provider: Counter[tuple[str, ...]] = Counter()
    scrubbed_fields: Counter[str] = Counter()
    event_types: Counter[str] = Counter()
    item_types: Counter[str] = Counter()
    provider_counts: Counter[str] = Counter()
    turns: set[tuple[str, str]] = set()
    completed_turns: set[tuple[str, str]] = set()
    tasks_started: set[tuple[str, str, str]] = set()
    tasks_completed: set[tuple[str, str, str]] = set()
    session_models_seen: set[tuple[str, str, str]] = set()
    token_totals: Counter[str] = Counter()
    provider_token_totals: dict[str, Counter[str]] = {}
    latest_context: dict[tuple[str, str], tuple[datetime, int]] = {}
    threads: dict[str, dict[str, Any]] = {}

    for event in events:
        provider = event["provider"] or "unknown"
        thread_id = event["thread_id"] or "<no-thread>"
        event_type = event["event_type"] or "unknown"
        item_type = event["item_type"]
        created_at = event["created_at"] or ""
        created_time = parse_time(created_at, "created_at") if created_at else None
        provider_counts[provider] += 1
        event_types[event_type] += 1
        if item_type is not None:
            item_types[item_type] += 1

        thread = threads.setdefault(
            thread_id,
            {
                "thread_id": thread_id,
                "providers": set(),
                "models": set(),
                "turns": set(),
                "completed_turns": set(),
                "tasks_started": set(),
                "tasks_completed": set(),
                "tool_calls": 0,
                "skill_observations": 0,
                "delegation_calls": 0,
                "input_tokens": 0,
                "output_tokens": 0,
                "first_event": None,
                "last_event": None,
                "first_time": None,
                "last_time": None,
            },
        )
        thread["providers"].add(provider)
        if created_time is not None:
            if thread["first_time"] is None or created_time < thread["first_time"]:
                thread["first_event"] = created_at
                thread["first_time"] = created_time
            if thread["last_time"] is None or created_time > thread["last_time"]:
                thread["last_event"] = created_at
                thread["last_time"] = created_time

        turn_id = event["turn_id"]
        if turn_id is not None:
            coordinate = (thread_id, turn_id)
            turns.add(coordinate)
            thread["turns"].add(turn_id)
            if event_type == "turn.completed":
                completed_turns.add(coordinate)
                thread["completed_turns"].add(turn_id)

        task_id = event["task_id"]
        new_task_start = False
        if task_id is not None and event_type == "task.started":
            task_coordinate = (provider, thread_id, task_id)
            new_task_start = task_coordinate not in tasks_started
            tasks_started.add(task_coordinate)
            thread["tasks_started"].add(task_id)
        if task_id is not None and event_type == "task.completed":
            tasks_completed.add((provider, thread_id, task_id))
            thread["tasks_completed"].add(task_id)

        model = event["model"]
        if model is not None and new_task_start:
            models[model] += 1
            models_by_provider[(provider, model)] += 1
            thread["models"].add(model)
        effort = event["reasoning_effort"]
        if effort is not None and new_task_start:
            efforts[effort] += 1
            efforts_by_provider[(provider, effort)] += 1
        role = event["agent_role"]
        if role is not None and new_task_start:
            roles[role] += 1
            roles_by_provider[(provider, role)] += 1

        if model is not None and event_type == "session.configured":
            coordinate = (provider, thread_id, model)
            if coordinate not in session_models_seen:
                session_models_seen.add(coordinate)
                session_models_by_provider[(provider, model)] += 1
        if (
            model is not None
            and event_type == "item.completed"
            and event["tool_name"] in {"Agent", "spawnAgent"}
        ):
            delegation_models_by_provider[(provider, model)] += 1

        if event_type == "item.completed" and event["tool_name"] is not None:
            tool = event["tool_name"]
            tools[tool] += 1
            tools_by_provider[(provider, tool)] += 1
            thread["tool_calls"] += 1
            if tool in {"Agent", "spawnAgent"}:
                thread["delegation_calls"] += 1
        if event_type == "item.completed":
            for skill in event["skill_names"]:
                skills[skill] += 1
                thread["skill_observations"] += 1
                skills_by_evidence[
                    (provider, event["skill_detection"] or "unknown", skill)
                ] += 1
            if event["skill_detection"] is not None:
                skill_detection[event["skill_detection"]] += len(event["skill_names"])

        for field in event["scrubbed_fields"]:
            scrubbed_fields[field] += 1

        if event_type == "thread.token-usage.updated":
            provider_tokens = provider_token_totals.setdefault(provider, Counter())
            for field in (
                "input_tokens",
                "cached_input_tokens",
                "output_tokens",
                "reasoning_output_tokens",
            ):
                value = event[field]
                if value is not None:
                    token_totals[field] += value
                    provider_tokens[field] += value
            thread["input_tokens"] += event["input_tokens"] or 0
            thread["output_tokens"] += event["output_tokens"] or 0
            context = event["context_tokens"]
            if context is not None:
                context_key = (provider, thread_id)
                previous = latest_context.get(context_key)
                if created_time is not None and (
                    previous is None or created_time >= previous[0]
                ):
                    latest_context[context_key] = (created_time, context)

    session_rows: list[dict[str, Any]] = []
    turn_counts: list[int] = []
    for thread in threads.values():
        count = len(thread["turns"])
        turn_counts.append(count)
        first = thread["first_event"]
        last = thread["last_event"]
        duration_seconds: float | None = None
        if thread["first_time"] is not None and thread["last_time"] is not None:
            duration_seconds = round(
                (thread["last_time"] - thread["first_time"]).total_seconds(), 3
            )
        session_rows.append(
            {
                "thread_id": thread["thread_id"],
                "providers": sorted(thread["providers"]),
                "models": sorted(thread["models"]),
                "turns": count,
                "completed_turns": len(thread["completed_turns"]),
                "worker_tasks_started": len(thread["tasks_started"]),
                "worker_tasks_completed": len(thread["tasks_completed"]),
                "tool_calls": thread["tool_calls"],
                "skill_observations": thread["skill_observations"],
                "delegation_calls": thread["delegation_calls"],
                "input_tokens": thread["input_tokens"],
                "output_tokens": thread["output_tokens"],
                "duration_seconds": duration_seconds,
                "first_event": first,
                "last_event": last,
            }
        )
    session_rows.sort(key=lambda row: row["last_event"] or "", reverse=True)

    total_tokens = token_totals["input_tokens"] + token_totals["output_tokens"]
    tool_calls = sum(tools.values())
    tokens_by_provider = []
    for provider, values in sorted(provider_token_totals.items()):
        provider_context = sum(
            value
            for (context_provider, _), (_, value) in latest_context.items()
            if context_provider == provider
        )
        tokens_by_provider.append(
            {
                "provider": provider,
                "input_tokens": values["input_tokens"],
                "cached_input_tokens": values["cached_input_tokens"],
                "output_tokens": values["output_tokens"],
                "reasoning_output_tokens": values["reasoning_output_tokens"],
                "processed_tokens": values["input_tokens"] + values["output_tokens"],
                "latest_context_tokens": provider_context,
            }
        )
    report = {
        "schema_version": SCHEMA_VERSION,
        "generated_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "policy_revision": policy_revision,
        "filters": {
            "sources": [str(path) for path in sources],
            "since": since,
            "until": until,
            "providers": list(providers),
            "thread_id": (
                opaque_identifier(selected_thread, "thread_id", [])
                if selected_thread is not None
                else None
            ),
        },
        "scan": {
            "files": stats.files,
            "lines": stats.lines,
            "canonical_lines": stats.canonical_lines,
            "malformed_events": stats.malformed_events,
            "duplicate_events": stats.duplicate_events,
            "missing_event_ids": stats.missing_event_ids,
            "filtered_events": stats.filtered_events,
            "included_events": len(events),
        },
        "totals": {
            "threads": len(threads),
            "turns": len(turns),
            "completed_turns": len(completed_turns),
            "worker_tasks_started": len(tasks_started),
            "worker_tasks_completed": len(tasks_completed),
            "tool_calls": tool_calls,
            "skill_observations": sum(skills.values()),
            "delegation_calls": tools["Agent"] + tools["spawnAgent"],
        },
        "rates": {
            "completed_turn_rate": finite_ratio(len(completed_turns), len(turns)),
            "tool_calls_per_turn": finite_ratio(tool_calls, len(turns)),
            "processed_tokens_per_turn": finite_ratio(total_tokens, len(turns)),
            "turns_per_thread_mean": (
                round(statistics.mean(turn_counts), 3) if turn_counts else None
            ),
            "turns_per_thread_median": (
                round(statistics.median(turn_counts), 3) if turn_counts else None
            ),
        },
        "tokens": {
            "aggregate_scope": "mixed-provider",
            "input_tokens": token_totals["input_tokens"],
            "cached_input_tokens": token_totals["cached_input_tokens"],
            "output_tokens": token_totals["output_tokens"],
            "reasoning_output_tokens": token_totals["reasoning_output_tokens"],
            "processed_tokens": total_tokens,
            "latest_context_tokens": sum(value for _, value in latest_context.values()),
            "by_provider": tokens_by_provider,
        },
        "providers": counter_rows(provider_counts, "provider"),
        "tools": counter_rows(tools, "tool")[:top],
        "tools_by_provider": tuple_counter_rows(
            tools_by_provider, ("provider", "tool")
        )[:top],
        "skills": counter_rows(skills, "skill")[:top],
        "skill_detection": counter_rows(skill_detection, "method"),
        "skills_by_evidence": tuple_counter_rows(
            skills_by_evidence, ("provider", "method", "skill")
        )[:top],
        "worker_roles": counter_rows(roles, "role")[:top],
        "worker_roles_by_provider": tuple_counter_rows(
            roles_by_provider, ("provider", "role")
        )[:top],
        "models": counter_rows(models, "model")[:top],
        "models_by_provider": tuple_counter_rows(
            models_by_provider, ("provider", "model")
        )[:top],
        "session_models_by_provider": tuple_counter_rows(
            session_models_by_provider, ("provider", "model")
        )[:top],
        "delegation_models_by_provider": tuple_counter_rows(
            delegation_models_by_provider, ("provider", "model")
        )[:top],
        "reasoning_efforts": counter_rows(efforts, "effort")[:top],
        "reasoning_efforts_by_provider": tuple_counter_rows(
            efforts_by_provider, ("provider", "effort")
        )[:top],
        "scrubbed_fields": counter_rows(scrubbed_fields, "field"),
        "event_types": counter_rows(event_types, "event_type"),
        "item_types": counter_rows(item_types, "item_type"),
        "threads": session_rows[:top],
        "truncated": {
            "tools": max(0, len(tools) - top),
            "tools_by_provider": max(0, len(tools_by_provider) - top),
            "skills": max(0, len(skills) - top),
            "skills_by_evidence": max(0, len(skills_by_evidence) - top),
            "worker_roles": max(0, len(roles) - top),
            "worker_roles_by_provider": max(0, len(roles_by_provider) - top),
            "models": max(0, len(models) - top),
            "models_by_provider": max(0, len(models_by_provider) - top),
            "session_models_by_provider": max(0, len(session_models_by_provider) - top),
            "delegation_models_by_provider": max(
                0, len(delegation_models_by_provider) - top
            ),
            "reasoning_efforts": max(0, len(efforts) - top),
            "reasoning_efforts_by_provider": max(0, len(efforts_by_provider) - top),
            "threads": max(0, len(session_rows) - top),
        },
    }
    return report


def number(value: Any) -> str:
    if value is None:
        return "n/a"
    if isinstance(value, float):
        return f"{value:,.3f}".rstrip("0").rstrip(".")
    return f"{value:,}" if isinstance(value, int) else str(value)


def markdown_table(headers: Sequence[str], rows: Sequence[Sequence[Any]]) -> list[str]:
    if not rows:
        return ["None observed."]
    lines = [
        "| " + " | ".join(headers) + " |",
        "| " + " | ".join("---" for _ in headers) + " |",
    ]
    for row in rows:
        values = [str(value).replace("|", "\\|") for value in row]
        lines.append("| " + " | ".join(values) + " |")
    return lines


def render_markdown(report: dict[str, Any]) -> str:
    totals = report["totals"]
    rates = report["rates"]
    tokens = report["tokens"]
    scan = report["scan"]
    lines = [
        "# AI Session Audit",
        "",
        f"Policy revision: `{report['policy_revision'] or 'unlabeled'}`",
        "",
        "## Activity",
        "",
        f"- Threads: {number(totals['threads'])}",
        f"- Turns: {number(totals['turns'])} ({number(totals['completed_turns'])} completed)",
        f"- Worker tasks: {number(totals['worker_tasks_started'])} started, {number(totals['worker_tasks_completed'])} completed",
        f"- Tool calls: {number(totals['tool_calls'])}",
        f"- Skill observations: {number(totals['skill_observations'])}",
        f"- Delegation calls: {number(totals['delegation_calls'])}",
        f"- Mean turns per thread: {number(rates['turns_per_thread_mean'])}",
        f"- Tool calls per turn: {number(rates['tool_calls_per_turn'])}",
        "",
        "## Provider-reported tokens",
        "",
        *markdown_table(
            [
                "Provider",
                "Input",
                "Cached input",
                "Output",
                "Reasoning output",
                "Processed",
                "Latest context",
            ],
            [
                [
                    row["provider"],
                    number(row["input_tokens"]),
                    number(row["cached_input_tokens"]),
                    number(row["output_tokens"]),
                    number(row["reasoning_output_tokens"]),
                    number(row["processed_tokens"]),
                    number(row["latest_context_tokens"]),
                ]
                for row in tokens["by_provider"]
            ],
        ),
        "",
        (
            "Processed tokens are within-provider trend data, not billed usage. "
            "The JSON report also contains an explicitly mixed aggregate."
        ),
        "",
        "## Tools",
        "",
        *markdown_table(
            ["Provider", "Tool", "Calls"],
            [
                [row["provider"], row["tool"], number(row["count"])]
                for row in report["tools_by_provider"]
            ],
        ),
        "",
        "## Skills",
        "",
        *markdown_table(
            ["Provider", "Evidence", "Skill", "Observations"],
            [
                [
                    row["provider"],
                    row["method"],
                    row["skill"],
                    number(row["count"]),
                ]
                for row in report["skills_by_evidence"]
            ],
        ),
        "",
        "## Worker roles",
        "",
        *markdown_table(
            ["Provider", "Role", "Tasks"],
            [
                [row["provider"], row["role"], number(row["count"])]
                for row in report["worker_roles_by_provider"]
            ],
        ),
        "",
        "## Worker models and effort",
        "",
        *markdown_table(
            ["Provider", "Model", "Observations"],
            [
                [row["provider"], row["model"], number(row["count"])]
                for row in report["models_by_provider"]
            ],
        ),
        "",
        "## Session models",
        "",
        *markdown_table(
            ["Provider", "Model", "Threads"],
            [
                [row["provider"], row["model"], number(row["count"])]
                for row in report["session_models_by_provider"]
            ],
        ),
        "",
        "## Requested delegation models",
        "",
        *markdown_table(
            ["Provider", "Model", "Calls"],
            [
                [row["provider"], row["model"], number(row["count"])]
                for row in report["delegation_models_by_provider"]
            ],
        ),
        "",
        *markdown_table(
            ["Provider", "Reasoning effort", "Observations"],
            [
                [row["provider"], row["effort"], number(row["count"])]
                for row in report["reasoning_efforts_by_provider"]
            ],
        ),
        "",
        "## Recent threads",
        "",
        *markdown_table(
            [
                "Thread",
                "Provider",
                "Turns",
                "Tools",
                "Skills",
                "Workers",
                "Processed tokens",
            ],
            [
                [
                    row["thread_id"],
                    ", ".join(row["providers"]),
                    number(row["turns"]),
                    number(row["tool_calls"]),
                    number(row["skill_observations"]),
                    number(row["worker_tasks_started"]),
                    number(row["input_tokens"] + row["output_tokens"]),
                ]
                for row in report["threads"]
            ],
        ),
        "",
        "## Scan health",
        "",
        (
            f"Scanned {number(scan['files'])} files and {number(scan['lines'])} "
            f"lines. Included {number(scan['included_events'])} deduplicated "
            f"canonical events. Skipped {number(scan['malformed_events'])} "
            f"malformed and {number(scan['duplicate_events'])} duplicate events. "
            f"Observed {number(scan['missing_event_ids'])} events without IDs and "
            f"scrubbed {number(sum(row['count'] for row in report['scrubbed_fields']))} "
            f"unsafe categorical values."
        ),
    ]
    return "\n".join(lines) + "\n"


def write_result(
    content: str, output: str | None, force: bool, sources: Sequence[Path]
) -> None:
    if output is None:
        sys.stdout.write(content)
        return
    path = Path(output).expanduser()
    resolved_output = path.resolve(strict=False)
    for source in sources:
        if resolved_output == source.resolve(strict=False) or (
            path.exists() and path.samefile(source)
        ):
            raise AuditError(f"output aliases a source log: {path}")
    if path.exists() and not force:
        raise AuditError(f"output already exists; pass --force to replace it: {path}")
    if not path.parent.exists():
        raise AuditError(f"output parent does not exist: {path.parent}")
    path.write_text(content, encoding="utf-8")


def add_filters(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--source",
        action="append",
        help="T3 provider log file or directory; repeat to combine sources",
    )
    parser.add_argument("--since", help="inclusive ISO-8601 start time")
    parser.add_argument("--until", help="exclusive ISO-8601 end time")
    parser.add_argument(
        "--provider",
        action="append",
        choices=sorted(ALLOWED_PROVIDERS),
        default=[],
        help="provider name; repeatable",
    )
    parser.add_argument("--thread", help="one T3 thread ID")
    parser.add_argument(
        "--strict",
        action="store_true",
        help="fail on malformed canonical JSON or missing event IDs",
    )
    parser.add_argument("--output", help="write to this exact path instead of stdout")
    parser.add_argument(
        "--force", action="store_true", help="replace an existing output file"
    )
    parser.add_argument(
        "--policy-revision", help="known active AI-tools revision label"
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Audit scrubbed metrics from T3 canonical AI provider events."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)
    summary = subparsers.add_parser("summary", help="aggregate a bounded report")
    add_filters(summary)
    summary.add_argument("--format", choices=("markdown", "json"), default="markdown")
    summary.add_argument(
        "--top", type=int, default=20, help="maximum rows per ranked section"
    )
    events = subparsers.add_parser("events", help="export scrubbed normalized NDJSON")
    add_filters(events)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        if getattr(args, "top", 1) < 1:
            raise AuditError("--top must be positive")
        if args.policy_revision is not None:
            scrubbed_revision: list[str] = []
            revision = safe_identifier(
                args.policy_revision, "policy_revision", scrubbed_revision
            )
            if revision is None:
                raise AuditError("--policy-revision must be a bounded identifier")
            args.policy_revision = revision
        since_time = parse_time(args.since, "--since") if args.since else None
        until_time = parse_time(args.until, "--until") if args.until else None
        if (
            since_time is not None
            and until_time is not None
            and since_time >= until_time
        ):
            raise AuditError("--since must be earlier than --until")
        files = source_files(args.source)
        stats = ScanStats()
        normalized = [
            normalize(event, args.policy_revision)
            for event in canonical_events(
                files,
                stats,
                since=since_time,
                until=until_time,
                providers=set(args.provider),
                thread_id=args.thread,
                strict=args.strict,
            )
        ]
        normalized.sort(key=chronological_key)
        if args.command == "events":
            content = "".join(
                json.dumps(event, sort_keys=True, separators=(",", ":")) + "\n"
                for event in normalized
            )
        else:
            report = summarize(
                normalized,
                stats,
                sources=files,
                since=args.since,
                until=args.until,
                providers=args.provider,
                selected_thread=args.thread,
                policy_revision=args.policy_revision,
                top=args.top,
            )
            content = (
                json.dumps(report, indent=2, sort_keys=True) + "\n"
                if args.format == "json"
                else render_markdown(report)
            )
        write_result(content, args.output, args.force, files)
    except (AuditError, OSError) as error:
        parser.error(str(error))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
