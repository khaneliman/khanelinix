"""Maintain a validated, recoverable program-control journal."""

from __future__ import annotations

import argparse
import copy
import errno
import hashlib
import io
import json
import os
import re
import secrets
import socket
import stat
import subprocess
import sys
import time
from contextlib import AbstractContextManager
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath
from types import TracebackType
from typing import Any, NoReturn, Self

SCHEMA_VERSION = 1
ZERO_HASH = "0" * 64
MAX_ARRAY_ITEMS = 256
MAX_ACTIVE_BYTES = 4 * 1024
MAX_LOCK_OWNER_BYTES = 4 * 1024
MAX_EVENT_BYTES = 256 * 1024
MAX_JOURNAL_BYTES = 16 * 1024 * 1024
MAX_JOURNAL_EVENTS = 16 * 1024
MAX_SNAPSHOT_BYTES = 8 * 1024 * 1024
LOCK_ATTEMPTS = 5
LOCK_BACKOFF_SECONDS = 0.125
LOCK_CONTENTION_MESSAGE = (
    "program state lock is held by another writer; retry the command, "
    "then inspect the lock with recover-plan when it persists"
)
PROGRAM_ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{0,63}$")
IDENTIFIER_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._:@/-]{0,127}$")
COMMIT_RE = re.compile(r"^(?:[0-9a-f]{40}|[0-9a-f]{64})$")
DIGEST_RE = re.compile(r"^[0-9a-f]{64}$")
UTC_RE = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?Z$")
CONTROL_RE = re.compile(r"[\x00-\x1f\x7f]")
TEMP_NAME_RE = re.compile(r"^\..+\.tmp\.[A-Za-z0-9]+$")

CAPABILITIES = {
    "workspace-read",
    "workspace-write",
    "local-commit",
    "git-push",
    "github-write",
    "pull-request",
    "merge",
    "publish",
    "release",
    "deploy",
    "cutover",
}
VERDICTS = {"VERIFIED", "NOT_VERIFIED", "INCONCLUSIVE"}
LEASE_OUTCOMES = {"released", "blocked"}
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
ENVELOPE_FIELDS = {
    "schema_version",
    "program_id",
    "sequence",
    "event_id",
    "event_type",
    "recorded_at",
    "actor",
    "payload",
    "previous_hash",
    "event_hash",
}
PAYLOAD_SPECS: dict[str, tuple[dict[str, str], dict[str, str]]] = {
    "program_initialized": (
        {"goal": "text", "base_commit": "commit"},
        {},
    ),
    "unit_added": (
        {
            "unit_id": "identifier",
            "outcome": "text",
            "owner": "identifier",
            "dependencies": "identifier_array",
            "resource_scopes": "scope_array",
            "required_capabilities": "required_capability_array",
            "predicate": "text",
            "rollback": "text",
        },
        {},
    ),
    "unit_readied": ({"unit_id": "identifier"}, {}),
    "unit_blocked": (
        {
            "unit_id": "identifier",
            "reason": "text",
            "evidence_ref": "reference",
        },
        {},
    ),
    "unit_unblocked": (
        {"unit_id": "identifier", "reason": "text"},
        {},
    ),
    "unit_cancelled": (
        {
            "unit_id": "identifier",
            "reason": "text",
            "evidence_ref": "reference",
        },
        {},
    ),
    "grant_recorded": (
        {
            "grant_id": "identifier",
            "capability": "capability",
            "scope": "scope",
            "issuer": "identifier",
            "evidence_ref": "reference",
        },
        {"expires_at": "utc"},
    ),
    "grant_revoked": (
        {"grant_id": "identifier", "reason": "text"},
        {},
    ),
    "lease_acquired": (
        {
            "lease_id": "identifier",
            "unit_id": "identifier",
            "holder": "identifier",
            "resource_scopes": "scope_array",
            "grant_ids": "identifier_array",
            "base_commit": "commit",
            "expires_at": "utc",
        },
        {},
    ),
    "lease_renewed": (
        {
            "lease_id": "identifier",
            "expires_at": "utc",
            "evidence_ref": "reference",
        },
        {},
    ),
    "lease_reconciled": (
        {
            "lease_id": "identifier",
            "outcome": "lease_outcome",
            "reason": "text",
            "evidence_ref": "reference",
        },
        {},
    ),
    "occurrence_receipt_recorded": (
        {
            "receipt_id": "identifier",
            "unit_id": "identifier",
            "lease_id": "identifier",
            "base_commit": "commit",
            "content_digest": "digest",
            "evidence_verdict": "verdict",
            "artifact_ref": "reference",
            "commit_sha": "commit",
            "parent_sha": "commit",
            "committed_digest": "digest",
            "digest_match": "boolean",
        },
        {},
    ),
    "handoff_receipt_recorded": (
        {
            "receipt_id": "identifier",
            "unit_id": "identifier",
            "lease_id": "identifier",
            "base_commit": "commit",
            "content_digest": "digest",
            "evidence_verdict": "verdict",
            "artifact_ref": "reference",
        },
        {},
    ),
    "receipt_invalidated": (
        {
            "receipt_id": "identifier",
            "reason": "text",
            "evidence_ref": "reference",
        },
        {},
    ),
    "unit_landed": (
        {"unit_id": "identifier", "receipt_id": "identifier"},
        {},
    ),
    "unit_reopened": (
        {
            "unit_id": "identifier",
            "receipt_id": "identifier",
            "reason": "text",
            "evidence_ref": "reference",
        },
        {},
    ),
    "program_paused": ({"reason": "text"}, {}),
    "program_resumed": ({"reason": "text"}, {}),
    "program_completed": ({"evidence_ref": "reference"}, {}),
    "program_aborted": (
        {"reason": "text", "evidence_ref": "reference"},
        {},
    ),
}

PAUSED_EVENTS = {
    "grant_revoked",
    "lease_renewed",
    "lease_reconciled",
    "occurrence_receipt_recorded",
    "handoff_receipt_recorded",
    "receipt_invalidated",
    "unit_landed",
    "program_resumed",
    "program_aborted",
}


class ProgramError(ValueError):
    """Report a deterministic program-state failure."""


@dataclass(frozen=True)
class LoadedProgram:
    root: Path
    program_id: str
    program_dir: Path
    events: list[dict[str, Any]]
    state: dict[str, Any]

    @property
    def journal_path(self) -> Path:
        return self.program_dir / "journal.jsonl"

    @property
    def snapshot_path(self) -> Path:
        return self.program_dir / "snapshot.json"


def fail(message: str) -> NoReturn:
    raise ProgramError(message)


def canonical_json(value: Any) -> bytes:
    try:
        encoded = json.dumps(
            value,
            ensure_ascii=False,
            allow_nan=False,
            sort_keys=True,
            separators=(",", ":"),
        )
    except (TypeError, ValueError) as error:
        raise ProgramError(f"value is not canonical JSON: {error}") from error
    return encoded.encode("utf-8")


def strict_json_loads(data: bytes | str, label: str) -> Any:
    def reject_duplicate_keys(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
        result: dict[str, Any] = {}
        for key, value in pairs:
            if key in result:
                fail(f"{label} contains duplicate key: {key}")
            result[key] = value
        return result

    def reject_constant(value: str) -> NoReturn:
        fail(f"{label} contains non-finite number: {value}")

    try:
        return json.loads(
            data,
            object_pairs_hook=reject_duplicate_keys,
            parse_constant=reject_constant,
        )
    except ProgramError:
        raise
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ProgramError(f"{label} is invalid JSON: {error}") from error


def event_digest(event: dict[str, Any]) -> str:
    unsigned = {key: value for key, value in event.items() if key != "event_hash"}
    return hashlib.sha256(canonical_json(unsigned)).hexdigest()


def require_string(value: Any, label: str, *, maximum: int = 2048) -> str:
    if not isinstance(value, str) or not value or len(value) > maximum:
        fail(f"{label} must be a non-empty string of at most {maximum} characters")
    if value != value.strip() or CONTROL_RE.search(value):
        fail(f"{label} must be one canonical line without outer whitespace")
    return value


def require_program_id(value: Any, label: str = "program_id") -> str:
    if not isinstance(value, str) or PROGRAM_ID_RE.fullmatch(value) is None:
        fail(f"{label} is not a portable program identifier")
    return value


def require_identifier(value: Any, label: str) -> str:
    if not isinstance(value, str) or IDENTIFIER_RE.fullmatch(value) is None:
        fail(f"{label} is not a valid identifier")
    return value


def require_commit(value: Any, label: str) -> str:
    if not isinstance(value, str) or COMMIT_RE.fullmatch(value) is None:
        fail(f"{label} must be a full lower-case Git object ID")
    return value


def require_digest(value: Any, label: str) -> str:
    if not isinstance(value, str) or DIGEST_RE.fullmatch(value) is None:
        fail(f"{label} must be a lower-case SHA-256 digest")
    return value


def require_utc(value: Any, label: str) -> str:
    if not isinstance(value, str) or UTC_RE.fullmatch(value) is None:
        fail(f"{label} must be an RFC 3339 UTC timestamp ending in Z")
    try:
        parsed = datetime.fromisoformat(value[:-1] + "+00:00")
    except ValueError as error:
        raise ProgramError(f"{label} is not a valid UTC timestamp") from error
    if parsed.utcoffset() is None or parsed.utcoffset().total_seconds() != 0:
        fail(f"{label} must use UTC")
    return value


def parse_utc(value: str) -> datetime:
    require_utc(value, "timestamp")
    return datetime.fromisoformat(value[:-1] + "+00:00")


def utc_now() -> str:
    return (
        datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")
    )


def require_scope(value: Any, label: str) -> str:
    scope = require_string(value, label, maximum=512)
    if (
        scope.startswith("/")
        or scope.endswith("/")
        or "\\" in scope
        or "//" in scope
        or any(part in {"", ".", ".."} for part in scope.split("/"))
    ):
        fail(f"{label} must be a canonical relative hierarchical scope")
    return scope


def require_v1_string(value: Any, label: str, *, maximum: int = 2048) -> str:
    if not isinstance(value, str) or not value or len(value) > maximum:
        fail(f"{label} must be a non-empty string of at most {maximum} characters")
    if CONTROL_RE.search(value):
        fail(f"{label} must not contain control characters")
    return value


def require_v1_scope(value: Any, label: str) -> str:
    return require_v1_string(value, label, maximum=512)


def require_sorted_strings(
    value: Any,
    label: str,
    item_validator: Any,
    *,
    allow_empty: bool = True,
    maximum_items: int | None = MAX_ARRAY_ITEMS,
) -> list[str]:
    if (
        not isinstance(value, list)
        or (maximum_items is not None and len(value) > maximum_items)
        or (not allow_empty and not value)
    ):
        fail(f"{label} must be a{' non-empty' if not allow_empty else ''} array")
    items = [
        item_validator(item, f"{label}[{index}]") for index, item in enumerate(value)
    ]
    if items != sorted(items) or len(items) != len(set(items)):
        fail(f"{label} must be duplicate-free and lexically sorted")
    return items


def require_capabilities(
    value: Any,
    label: str,
    *,
    scope_validator: Any = require_scope,
    maximum_items: int | None = MAX_ARRAY_ITEMS,
) -> list[dict[str, str]]:
    if not isinstance(value, list) or (
        maximum_items is not None and len(value) > maximum_items
    ):
        maximum = (
            f" with at most {maximum_items} items" if maximum_items is not None else ""
        )
        fail(f"{label} must be an array{maximum}")
    result: list[dict[str, str]] = []
    for index, item in enumerate(value):
        item_label = f"{label}[{index}]"
        if not isinstance(item, dict) or set(item) != {"capability", "scope"}:
            fail(f"{item_label} must contain only capability and scope")
        capability = item["capability"]
        if not isinstance(capability, str) or capability not in CAPABILITIES:
            fail(f"{item_label}.capability is unknown")
        result.append(
            {
                "capability": capability,
                "scope": scope_validator(item["scope"], f"{item_label}.scope"),
            }
        )
    keys = [(item["capability"], item["scope"]) for item in result]
    if keys != sorted(keys) or len(keys) != len(set(keys)):
        fail(f"{label} must be duplicate-free and sorted by capability and scope")
    return result


def validate_field(
    kind: str,
    value: Any,
    label: str,
    *,
    producer_profile: bool = True,
) -> None:
    string_validator = require_string if producer_profile else require_v1_string
    scope_validator = require_scope if producer_profile else require_v1_scope
    maximum_items = MAX_ARRAY_ITEMS if producer_profile else None
    if kind == "text" or kind == "reference":
        string_validator(value, label)
    elif kind == "identifier":
        require_identifier(value, label)
    elif kind == "commit":
        require_commit(value, label)
    elif kind == "digest":
        require_digest(value, label)
    elif kind == "utc":
        require_utc(value, label)
    elif kind == "scope":
        scope_validator(value, label)
    elif kind == "capability":
        if not isinstance(value, str) or value not in CAPABILITIES:
            fail(f"{label} is an unknown capability")
    elif kind == "verdict":
        if not isinstance(value, str) or value not in VERDICTS:
            fail(f"{label} is an unknown evidence verdict")
    elif kind == "lease_outcome":
        if not isinstance(value, str) or value not in LEASE_OUTCOMES:
            fail(f"{label} is an unknown lease reconciliation outcome")
    elif kind == "boolean":
        if type(value) is not bool:
            fail(f"{label} must be a boolean")
    elif kind == "identifier_array":
        require_sorted_strings(
            value,
            label,
            require_identifier,
            maximum_items=maximum_items,
        )
    elif kind == "scope_array":
        require_sorted_strings(
            value,
            label,
            scope_validator,
            allow_empty=False,
            maximum_items=maximum_items,
        )
    elif kind == "required_capability_array":
        require_capabilities(
            value,
            label,
            scope_validator=scope_validator,
            maximum_items=maximum_items,
        )
    else:
        fail(f"internal validator kind is unknown: {kind}")


def validate_payload(
    event_type: str,
    payload: Any,
    *,
    producer_profile: bool = True,
) -> dict[str, Any]:
    if not isinstance(payload, dict):
        fail(f"{event_type}.payload must be an object")
    required, optional = PAYLOAD_SPECS[event_type]
    fields = set(payload)
    missing = sorted(set(required) - fields)
    unknown = sorted(fields - set(required) - set(optional))
    if missing:
        fail(f"{event_type}.payload is missing fields: {', '.join(missing)}")
    if unknown:
        fail(f"{event_type}.payload has unknown fields: {', '.join(unknown)}")
    for field, kind in required.items():
        validate_field(
            kind,
            payload[field],
            f"{event_type}.payload.{field}",
            producer_profile=producer_profile,
        )
    for field, kind in optional.items():
        if field in payload:
            validate_field(
                kind,
                payload[field],
                f"{event_type}.payload.{field}",
                producer_profile=producer_profile,
            )
    return payload


def validate_event_shape(
    event: Any,
    *,
    producer_profile: bool = True,
) -> dict[str, Any]:
    if not isinstance(event, dict) or set(event) != ENVELOPE_FIELDS:
        fail("event envelope has missing or unknown fields")
    if (
        type(event["schema_version"]) is not int
        or event["schema_version"] != SCHEMA_VERSION
    ):
        fail(f"unsupported schema version: {event['schema_version']!r}")
    require_program_id(event["program_id"])
    sequence = event["sequence"]
    if type(sequence) is not int or sequence < 1:
        fail("event sequence must be a positive integer")
    require_identifier(event["event_id"], "event_id")
    event_type = event["event_type"]
    if not isinstance(event_type, str) or event_type not in EVENT_TYPES:
        fail(f"unknown event type: {event_type!r}")
    require_utc(event["recorded_at"], "recorded_at")
    require_identifier(event["actor"], "actor")
    validate_payload(
        event_type,
        event["payload"],
        producer_profile=producer_profile,
    )
    require_digest(event["previous_hash"], "previous_hash")
    require_digest(event["event_hash"], "event_hash")
    expected = event_digest(event)
    if event["event_hash"] != expected:
        fail(f"event hash mismatch at sequence {sequence}")
    return event


def make_event(
    *,
    program_id: str,
    sequence: int,
    event_id: str,
    event_type: str,
    recorded_at: str,
    actor: str,
    payload: dict[str, Any],
    previous_hash: str,
) -> dict[str, Any]:
    event = {
        "schema_version": SCHEMA_VERSION,
        "program_id": program_id,
        "sequence": sequence,
        "event_id": event_id,
        "event_type": event_type,
        "recorded_at": recorded_at,
        "actor": actor,
        "payload": payload,
        "previous_hash": previous_hash,
        "event_hash": ZERO_HASH,
    }
    event["event_hash"] = event_digest(event)
    return validate_event_shape(event)


def initial_state(program_id: str) -> dict[str, Any]:
    return {
        "schema_version": SCHEMA_VERSION,
        "program_id": program_id,
        "sequence": 0,
        "head": ZERO_HASH,
        "goal": None,
        "base_commit": None,
        "status": None,
        "initialized_at": None,
        "last_event_at": None,
        "units": {},
        "grants": {},
        "leases": {},
        "receipts": {},
    }


def scope_covers(parent: str, child: str) -> bool:
    return parent == child or child.startswith(parent + "/")


def scopes_overlap(left: str, right: str) -> bool:
    return scope_covers(left, right) or scope_covers(right, left)


def grant_is_active(grant: dict[str, Any], at: str) -> bool:
    if grant["revoked_at"] is not None:
        return False
    expires_at = grant["expires_at"]
    return expires_at is None or parse_utc(expires_at) > parse_utc(at)


def receipt_is_valid(state: dict[str, Any], receipt_id: str | None) -> bool:
    if receipt_id is None:
        return False
    receipt = state["receipts"].get(receipt_id)
    return bool(receipt and receipt["valid"])


def dependency_is_landed(state: dict[str, Any], unit_id: str) -> bool:
    unit = state["units"][unit_id]
    return unit["status"] == "landed" and receipt_is_valid(state, unit["receipt_id"])


def grant_covers_requirement(
    grant: dict[str, Any], requirement: dict[str, str], at: str
) -> bool:
    return (
        grant_is_active(grant, at)
        and grant["capability"] == requirement["capability"]
        and scope_covers(grant["scope"], requirement["scope"])
    )


def requirements_are_covered(
    state: dict[str, Any],
    unit: dict[str, Any],
    at: str,
    selected_grant_ids: list[str] | None = None,
) -> bool:
    grants = state["grants"]
    selected = (
        list(grants.values())
        if selected_grant_ids is None
        else [grants[grant_id] for grant_id in selected_grant_ids]
    )
    requirements = unit["required_capabilities"]
    if not all(
        any(grant_covers_requirement(grant, requirement, at) for grant in selected)
        for requirement in requirements
    ):
        return False
    if selected_grant_ids is not None:
        return all(
            any(
                grant_covers_requirement(grant, requirement, at)
                for requirement in requirements
            )
            for grant in selected
        )
    return True


def require_unit(state: dict[str, Any], unit_id: str) -> dict[str, Any]:
    unit = state["units"].get(unit_id)
    if unit is None:
        fail(f"unknown unit: {unit_id}")
    return unit


def require_grant(state: dict[str, Any], grant_id: str) -> dict[str, Any]:
    grant = state["grants"].get(grant_id)
    if grant is None:
        fail(f"unknown grant: {grant_id}")
    return grant


def require_lease(state: dict[str, Any], lease_id: str) -> dict[str, Any]:
    lease = state["leases"].get(lease_id)
    if lease is None:
        fail(f"unknown lease: {lease_id}")
    return lease


def require_receipt(state: dict[str, Any], receipt_id: str) -> dict[str, Any]:
    receipt = state["receipts"].get(receipt_id)
    if receipt is None:
        fail(f"unknown receipt: {receipt_id}")
    return receipt


def require_program_status(state: dict[str, Any], *allowed: str) -> None:
    if state["status"] not in allowed:
        fail(
            f"event requires program status {', '.join(allowed)}; "
            f"found {state['status']}"
        )


def active_lease_ids(state: dict[str, Any]) -> list[str]:
    return sorted(
        lease_id
        for lease_id, lease in state["leases"].items()
        if lease["status"] == "active"
    )


def apply_event(state: dict[str, Any], event: dict[str, Any]) -> None:
    event_type = event["event_type"]
    payload = event["payload"]
    recorded_at = event["recorded_at"]

    if state["last_event_at"] is not None and parse_utc(recorded_at) < parse_utc(
        state["last_event_at"]
    ):
        fail("event timestamps must be monotonic")

    if event_type == "program_initialized":
        if state["status"] is not None or event["sequence"] != 1:
            fail("program_initialized must be the first event")
        state.update(
            {
                "goal": payload["goal"],
                "base_commit": payload["base_commit"],
                "status": "active",
                "initialized_at": recorded_at,
            }
        )
        state["last_event_at"] = recorded_at
        return

    if state["status"] is None:
        fail("journal must start with program_initialized")
    if state["status"] in {"completed", "aborted"}:
        fail(f"terminal program rejects event: {event_type}")
    if state["status"] == "paused" and event_type not in PAUSED_EVENTS:
        fail(f"paused program rejects event: {event_type}")

    if event_type == "unit_added":
        require_program_status(state, "active")
        unit_id = payload["unit_id"]
        if unit_id in state["units"]:
            fail(f"duplicate unit: {unit_id}")
        unknown = [
            dependency
            for dependency in payload["dependencies"]
            if dependency not in state["units"]
        ]
        if unknown:
            fail(f"unit dependencies must already exist: {', '.join(unknown)}")
        if unit_id in payload["dependencies"]:
            fail("unit cannot depend on itself")
        state["units"][unit_id] = {
            "unit_id": unit_id,
            "outcome": payload["outcome"],
            "owner": payload["owner"],
            "dependencies": payload["dependencies"],
            "resource_scopes": payload["resource_scopes"],
            "required_capabilities": payload["required_capabilities"],
            "predicate": payload["predicate"],
            "rollback": payload["rollback"],
            "status": "planned",
            "active_lease_id": None,
            "receipt_id": None,
            "block": None,
            "cancellation": None,
        }

    elif event_type == "unit_readied":
        require_program_status(state, "active")
        unit = require_unit(state, payload["unit_id"])
        if unit["status"] != "planned":
            fail("only a planned unit can become ready")
        if not all(
            dependency_is_landed(state, dependency)
            for dependency in unit["dependencies"]
        ):
            fail("unit dependencies are not landed with valid receipts")
        if not requirements_are_covered(state, unit, recorded_at):
            fail("unit required capabilities lack active matching grants")
        unit["status"] = "ready"

    elif event_type == "unit_blocked":
        require_program_status(state, "active")
        unit = require_unit(state, payload["unit_id"])
        if unit["status"] not in {"planned", "ready"}:
            fail("only a planned or ready unit can be blocked directly")
        unit["status"] = "blocked"
        unit["block"] = {
            "reason": payload["reason"],
            "evidence_ref": payload["evidence_ref"],
            "recorded_at": recorded_at,
        }

    elif event_type == "unit_unblocked":
        require_program_status(state, "active")
        unit = require_unit(state, payload["unit_id"])
        if unit["status"] != "blocked" or unit["active_lease_id"] is not None:
            fail("only a blocked unit without an active lease can be unblocked")
        unit["status"] = "planned"
        unit["block"] = None

    elif event_type == "unit_cancelled":
        require_program_status(state, "active")
        unit = require_unit(state, payload["unit_id"])
        if unit["status"] not in {"planned", "ready", "blocked"}:
            fail("leased or landed unit cannot be cancelled")
        if unit["active_lease_id"] is not None:
            fail("unit with active lease cannot be cancelled")
        unit["status"] = "cancelled"
        unit["cancellation"] = {
            "reason": payload["reason"],
            "evidence_ref": payload["evidence_ref"],
            "recorded_at": recorded_at,
        }

    elif event_type == "grant_recorded":
        require_program_status(state, "active")
        grant_id = payload["grant_id"]
        if grant_id in state["grants"]:
            fail(f"duplicate grant: {grant_id}")
        expires_at = payload.get("expires_at")
        if expires_at is not None and parse_utc(expires_at) <= parse_utc(recorded_at):
            fail("grant expiry must be later than grant time")
        state["grants"][grant_id] = {
            "grant_id": grant_id,
            "capability": payload["capability"],
            "scope": payload["scope"],
            "issuer": payload["issuer"],
            "evidence_ref": payload["evidence_ref"],
            "granted_at": recorded_at,
            "expires_at": expires_at,
            "revoked_at": None,
            "revocation_reason": None,
        }

    elif event_type == "grant_revoked":
        require_program_status(state, "active", "paused")
        grant = require_grant(state, payload["grant_id"])
        if grant["revoked_at"] is not None:
            fail("grant is already revoked")
        grant["revoked_at"] = recorded_at
        grant["revocation_reason"] = payload["reason"]

    elif event_type == "lease_acquired":
        require_program_status(state, "active")
        lease_id = payload["lease_id"]
        if lease_id in state["leases"]:
            fail(f"duplicate lease: {lease_id}")
        unit = require_unit(state, payload["unit_id"])
        if unit["status"] != "ready" or unit["active_lease_id"] is not None:
            fail("lease acquisition requires an unleased ready unit")
        if not all(
            dependency_is_landed(state, dependency)
            for dependency in unit["dependencies"]
        ):
            fail("lease acquisition found invalidated dependency evidence")
        if payload["resource_scopes"] != unit["resource_scopes"]:
            fail("lease scopes must exactly match unit resource scopes")
        if parse_utc(payload["expires_at"]) <= parse_utc(recorded_at):
            fail("lease expiry must be later than acquisition time")
        for grant_id in payload["grant_ids"]:
            grant = require_grant(state, grant_id)
            if not grant_is_active(grant, recorded_at):
                fail(f"selected grant is inactive: {grant_id}")
        if not requirements_are_covered(state, unit, recorded_at, payload["grant_ids"]):
            fail("selected grants do not exactly support unit requirements")
        for lease in state["leases"].values():
            if lease["status"] != "active":
                continue
            if any(
                scopes_overlap(left, right)
                for left in payload["resource_scopes"]
                for right in lease["resource_scopes"]
            ):
                fail(f"lease scopes overlap active lease: {lease['lease_id']}")
        state["leases"][lease_id] = {
            "lease_id": lease_id,
            "unit_id": unit["unit_id"],
            "holder": payload["holder"],
            "resource_scopes": payload["resource_scopes"],
            "grant_ids": payload["grant_ids"],
            "base_commit": payload["base_commit"],
            "acquired_at": recorded_at,
            "expires_at": payload["expires_at"],
            "status": "active",
            "closed_at": None,
            "evidence_ref": None,
            "reason": None,
        }
        unit["status"] = "leased"
        unit["active_lease_id"] = lease_id

    elif event_type == "lease_renewed":
        require_program_status(state, "active", "paused")
        lease = require_lease(state, payload["lease_id"])
        if lease["status"] != "active":
            fail("only an active lease can be renewed")
        if parse_utc(payload["expires_at"]) <= parse_utc(lease["expires_at"]):
            fail("renewed expiry must be later than current expiry")
        if parse_utc(payload["expires_at"]) <= parse_utc(recorded_at):
            fail("renewed expiry must be later than renewal time")
        for grant_id in lease["grant_ids"]:
            if not grant_is_active(require_grant(state, grant_id), recorded_at):
                fail(f"lease cannot renew with inactive grant: {grant_id}")
        lease["expires_at"] = payload["expires_at"]
        lease["evidence_ref"] = payload["evidence_ref"]

    elif event_type == "lease_reconciled":
        require_program_status(state, "active", "paused")
        lease = require_lease(state, payload["lease_id"])
        if lease["status"] != "active":
            fail("only an active lease can be reconciled")
        unit = require_unit(state, lease["unit_id"])
        if unit["active_lease_id"] != lease["lease_id"] or unit["status"] != "leased":
            fail("lease and unit ownership disagree")
        lease["status"] = payload["outcome"]
        lease["closed_at"] = recorded_at
        lease["evidence_ref"] = payload["evidence_ref"]
        lease["reason"] = payload["reason"]
        unit["active_lease_id"] = None
        if payload["outcome"] == "released":
            unit["status"] = "ready"
        else:
            unit["status"] = "blocked"
            unit["block"] = {
                "reason": payload["reason"],
                "evidence_ref": payload["evidence_ref"],
                "recorded_at": recorded_at,
            }

    elif event_type in {
        "occurrence_receipt_recorded",
        "handoff_receipt_recorded",
    }:
        require_program_status(state, "active", "paused")
        receipt_id = payload["receipt_id"]
        if receipt_id in state["receipts"]:
            fail(f"duplicate receipt: {receipt_id}")
        unit = require_unit(state, payload["unit_id"])
        lease = require_lease(state, payload["lease_id"])
        if (
            unit["status"] != "leased"
            or unit["active_lease_id"] != lease["lease_id"]
            or lease["status"] != "active"
            or lease["unit_id"] != unit["unit_id"]
        ):
            fail("receipt unit and active lease do not agree")
        if payload["base_commit"] != lease["base_commit"]:
            fail("receipt base commit does not match lease base")
        if parse_utc(lease["expires_at"]) <= parse_utc(recorded_at):
            fail("receipt delivery requires a current lease")
        if not all(
            dependency_is_landed(state, dependency)
            for dependency in unit["dependencies"]
        ):
            fail("receipt delivery found invalidated dependency evidence")
        for grant_id in lease["grant_ids"]:
            if not grant_is_active(require_grant(state, grant_id), recorded_at):
                fail(f"receipt delivery found inactive grant: {grant_id}")
        if not requirements_are_covered(state, unit, recorded_at, lease["grant_ids"]):
            fail("receipt delivery lacks active matching grants")
        kind = "occurrence" if event_type.startswith("occurrence") else "handoff"
        requires_commit = any(
            requirement["capability"] == "local-commit"
            for requirement in unit["required_capabilities"]
        )
        if kind == "occurrence" and not requires_commit:
            fail("occurrence delivery requires recorded local-commit capability")
        if kind == "handoff" and requires_commit:
            fail("handoff delivery cannot satisfy a local-commit unit")
        receipt = {
            "receipt_id": receipt_id,
            "unit_id": unit["unit_id"],
            "lease_id": lease["lease_id"],
            "delivery_kind": kind,
            "base_commit": payload["base_commit"],
            "content_digest": payload["content_digest"],
            "evidence_verdict": payload["evidence_verdict"],
            "artifact_ref": payload["artifact_ref"],
            "recorded_at": recorded_at,
            "valid": True,
            "invalidated_at": None,
            "invalidation_reason": None,
            "invalidation_evidence_ref": None,
        }
        if kind == "occurrence":
            if payload["parent_sha"] != payload["base_commit"]:
                fail("occurrence parent must equal receipt base commit")
            receipt.update(
                {
                    "commit_sha": payload["commit_sha"],
                    "parent_sha": payload["parent_sha"],
                    "committed_digest": payload["committed_digest"],
                    "digest_match": payload["digest_match"],
                }
            )
        state["receipts"][receipt_id] = receipt

    elif event_type == "receipt_invalidated":
        require_program_status(state, "active", "paused")
        receipt = require_receipt(state, payload["receipt_id"])
        if not receipt["valid"]:
            fail("receipt is already invalidated")
        receipt["valid"] = False
        receipt["invalidated_at"] = recorded_at
        receipt["invalidation_reason"] = payload["reason"]
        receipt["invalidation_evidence_ref"] = payload["evidence_ref"]

    elif event_type == "unit_landed":
        require_program_status(state, "active", "paused")
        unit = require_unit(state, payload["unit_id"])
        receipt = require_receipt(state, payload["receipt_id"])
        if (
            unit["status"] != "leased"
            or unit["active_lease_id"] != receipt["lease_id"]
            or receipt["unit_id"] != unit["unit_id"]
            or not receipt["valid"]
            or receipt["evidence_verdict"] != "VERIFIED"
        ):
            fail("unit landing requires its valid VERIFIED active-lease receipt")
        if not all(
            dependency_is_landed(state, dependency)
            for dependency in unit["dependencies"]
        ):
            fail("unit landing found invalidated dependency evidence")
        if receipt["delivery_kind"] == "occurrence" and (
            not receipt["digest_match"]
            or receipt["content_digest"] != receipt["committed_digest"]
        ):
            fail("occurrence receipt digest equality is not verified")
        lease = require_lease(state, receipt["lease_id"])
        if lease["status"] != "active":
            fail("receipt lease is no longer active")
        if parse_utc(lease["expires_at"]) <= parse_utc(recorded_at):
            fail("unit landing requires a current lease")
        for grant_id in lease["grant_ids"]:
            if not grant_is_active(require_grant(state, grant_id), recorded_at):
                fail(f"unit landing found inactive grant: {grant_id}")
        if not requirements_are_covered(state, unit, recorded_at, lease["grant_ids"]):
            fail("unit landing lacks active matching grants")
        lease["status"] = "landed"
        lease["closed_at"] = recorded_at
        unit["status"] = "landed"
        unit["active_lease_id"] = None
        unit["receipt_id"] = receipt["receipt_id"]

    elif event_type == "unit_reopened":
        require_program_status(state, "active")
        unit = require_unit(state, payload["unit_id"])
        if unit["status"] != "landed" or unit["receipt_id"] != payload["receipt_id"]:
            fail("unit reopening must name its landed receipt")
        receipt = require_receipt(state, payload["receipt_id"])
        if receipt["valid"]:
            fail("receipt must be invalidated before unit reopening")
        active_dependents = sorted(
            candidate["unit_id"]
            for candidate in state["units"].values()
            if unit["unit_id"] in candidate["dependencies"]
            and candidate["status"] in {"ready", "leased", "landed"}
        )
        if active_dependents:
            fail("reopen dependent units first: " + ", ".join(active_dependents))
        unit["status"] = "planned"
        unit["receipt_id"] = None

    elif event_type == "program_paused":
        require_program_status(state, "active")
        state["status"] = "paused"

    elif event_type == "program_resumed":
        require_program_status(state, "paused")
        state["status"] = "active"

    elif event_type == "program_completed":
        require_program_status(state, "active")
        if len(state["units"]) < 2:
            fail("program completion requires at least two units")
        unresolved = sorted(
            unit["unit_id"]
            for unit in state["units"].values()
            if unit["status"] not in {"landed", "cancelled"}
            or (
                unit["status"] == "landed"
                and not receipt_is_valid(state, unit["receipt_id"])
            )
        )
        if unresolved:
            fail("program has unresolved units: " + ", ".join(unresolved))
        if active_lease_ids(state):
            fail("program cannot complete with active leases")
        state["status"] = "completed"

    elif event_type == "program_aborted":
        require_program_status(state, "active", "paused")
        if active_lease_ids(state):
            fail("reconcile active leases before program abort")
        state["status"] = "aborted"

    else:
        fail(f"event transition is not implemented: {event_type}")

    state["last_event_at"] = recorded_at


def replay(events: list[dict[str, Any]]) -> dict[str, Any]:
    if not events:
        fail("journal is empty")
    first = validate_event_shape(events[0], producer_profile=False)
    program_id = first["program_id"]
    state = initial_state(program_id)
    expected_previous = ZERO_HASH
    seen_event_ids: set[str] = set()
    for expected_sequence, event in enumerate(events, start=1):
        if expected_sequence > 1:
            validate_event_shape(event, producer_profile=False)
        if event["program_id"] != program_id:
            fail(f"program ID changed at sequence {expected_sequence}")
        if event["sequence"] != expected_sequence:
            fail(f"journal sequence gap at {expected_sequence}")
        if event["event_id"] in seen_event_ids:
            fail(f"duplicate event ID: {event['event_id']}")
        if event["previous_hash"] != expected_previous:
            fail(f"previous hash mismatch at sequence {expected_sequence}")
        apply_event(state, event)
        state["sequence"] = expected_sequence
        state["head"] = event["event_hash"]
        expected_previous = event["event_hash"]
        seen_event_ids.add(event["event_id"])
    return state


def journal_bytes(events: list[dict[str, Any]]) -> bytes:
    chunks: list[bytes] = []
    total_bytes = 0
    for line_number, event in enumerate(events, start=1):
        if line_number > MAX_JOURNAL_EVENTS:
            fail(f"journal exceeds {MAX_JOURNAL_EVENTS} events")
        row = canonical_json(event) + b"\n"
        if len(row) > MAX_EVENT_BYTES:
            fail(f"journal line {line_number} exceeds {MAX_EVENT_BYTES} bytes")
        total_bytes += len(row)
        if total_bytes > MAX_JOURNAL_BYTES:
            fail(f"journal exceeds {MAX_JOURNAL_BYTES} bytes")
        chunks.append(row)
    if not chunks:
        fail("journal must be non-empty and end with one newline")
    return b"".join(chunks)


def parse_journal_rows(rows: Any) -> list[dict[str, Any]]:
    events: list[dict[str, Any]] = []
    total_bytes = 0
    while True:
        raw_line = rows.readline(MAX_EVENT_BYTES + 1)
        if not raw_line:
            break
        line_number = len(events) + 1
        total_bytes += len(raw_line)
        if total_bytes > MAX_JOURNAL_BYTES:
            fail(f"journal exceeds {MAX_JOURNAL_BYTES} bytes")
        if len(raw_line) > MAX_EVENT_BYTES:
            fail(f"journal line {line_number} exceeds {MAX_EVENT_BYTES} bytes")
        if line_number > MAX_JOURNAL_EVENTS:
            fail(f"journal exceeds {MAX_JOURNAL_EVENTS} events")
        if not raw_line.endswith(b"\n") or raw_line in {b"\n", b"\r\n"}:
            fail(f"journal line {line_number} is empty or unterminated")
        encoded = raw_line[:-1]
        if encoded.endswith(b"\r"):
            fail(f"journal line {line_number} uses non-canonical line ending")
        event = strict_json_loads(encoded, f"journal line {line_number}")
        if canonical_json(event) != encoded:
            fail(f"journal line {line_number} is not canonical JSON")
        events.append(validate_event_shape(event, producer_profile=False))
    if not events:
        fail("journal must be non-empty and end with one newline")
    replay(events)
    return events


def parse_journal(data: bytes) -> list[dict[str, Any]]:
    if len(data) > MAX_JOURNAL_BYTES:
        fail(f"journal exceeds {MAX_JOURNAL_BYTES} bytes")
    return parse_journal_rows(io.BytesIO(data))


def resolve_root(root: str | Path) -> Path:
    try:
        resolved = Path(root).expanduser().resolve(strict=True)
    except OSError as error:
        raise ProgramError(f"repository root does not exist: {root}") from error
    if not resolved.is_dir():
        fail(f"repository root is not a directory: {resolved}")
    return resolved


def lstat_path(path: Path) -> os.stat_result | None:
    try:
        return path.lstat()
    except FileNotFoundError:
        return None
    except OSError as error:
        raise ProgramError(f"cannot inspect managed path {path}: {error}") from error


def ensure_directory(path: Path, *, create: bool) -> Path:
    metadata = lstat_path(path)
    if metadata is None:
        if not create:
            fail(f"managed directory does not exist: {path}")
        try:
            path.mkdir(mode=0o700)
        except OSError as error:
            raise ProgramError(
                f"cannot create managed directory {path}: {error}"
            ) from error
        metadata = lstat_path(path)
    if (
        metadata is None
        or stat.S_ISLNK(metadata.st_mode)
        or not stat.S_ISDIR(metadata.st_mode)
    ):
        fail(f"managed path must be a non-symlink directory: {path}")
    return path


def programs_root(root: Path, *, create: bool) -> Path:
    agent_dir = ensure_directory(root / ".agent", create=create)
    return ensure_directory(agent_dir / "programs", create=create)


def require_program_state_excluded(root: Path, program_id: str) -> None:
    require_program_id(program_id)
    tracked = subprocess.run(
        ["git", "-C", str(root), "ls-files", "--", ".agent/programs"],
        check=False,
        capture_output=True,
        text=True,
    )
    if tracked.returncode != 0:
        fail("repository root must support Git ignore checks")
    if tracked.stdout.strip():
        fail(".agent/programs must not contain tracked files")
    managed_paths = (
        ".agent/programs/",
        ".agent/programs/active.json",
        ".agent/programs/.state-lock/owner.json",
        f".agent/programs/{program_id}/journal.jsonl",
        f".agent/programs/{program_id}/snapshot.json",
    )
    for managed_path in managed_paths:
        ignored = subprocess.run(
            [
                "git",
                "-C",
                str(root),
                "check-ignore",
                "--no-index",
                "--quiet",
                "--",
                managed_path,
            ],
            check=False,
            capture_output=True,
            text=True,
        )
        if ignored.returncode == 1:
            fail(".agent/programs/ must be excluded from Git before program writes")
        if ignored.returncode != 0:
            fail("repository root must support Git ignore checks")


def program_directory(root: Path, program_id: str, *, create: bool = False) -> Path:
    require_program_id(program_id)
    directory = programs_root(root, create=create) / program_id
    metadata = lstat_path(directory)
    if metadata is None:
        if not create:
            fail(f"program directory does not exist: {program_id}")
        try:
            directory.mkdir(mode=0o700)
        except OSError as error:
            raise ProgramError(f"cannot create program directory: {error}") from error
        metadata = lstat_path(directory)
    if (
        metadata is None
        or stat.S_ISLNK(metadata.st_mode)
        or not stat.S_ISDIR(metadata.st_mode)
    ):
        fail(f"program path must be a non-symlink directory: {directory}")
    return directory


def open_regular_descriptor(
    path: Path, label: str, *, maximum_bytes: int | None = None
) -> int:
    metadata = lstat_path(path)
    if metadata is None:
        fail(f"{label} does not exist: {path}")
    if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISREG(metadata.st_mode):
        fail(f"{label} must be a non-symlink regular file: {path}")
    flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
    try:
        descriptor = os.open(path, flags)
    except OSError as error:
        raise ProgramError(f"cannot open {label} {path}: {error}") from error
    try:
        opened = os.fstat(descriptor)
    except OSError as error:
        os.close(descriptor)
        raise ProgramError(f"cannot inspect open {label} {path}: {error}") from error
    if not stat.S_ISREG(opened.st_mode) or (opened.st_dev, opened.st_ino) != (
        metadata.st_dev,
        metadata.st_ino,
    ):
        os.close(descriptor)
        fail(f"{label} changed while opening: {path}")
    if maximum_bytes is not None and opened.st_size > maximum_bytes:
        os.close(descriptor)
        fail(f"{label} exceeds {maximum_bytes} bytes")
    return descriptor


def validate_regular_file(
    path: Path, label: str, *, maximum_bytes: int | None = None
) -> None:
    descriptor = open_regular_descriptor(path, label, maximum_bytes=maximum_bytes)
    try:
        os.close(descriptor)
    except OSError as error:
        raise ProgramError(f"cannot close {label} {path}: {error}") from error


def read_regular_bytes(path: Path, label: str, *, maximum_bytes: int) -> bytes:
    descriptor = open_regular_descriptor(path, label, maximum_bytes=maximum_bytes)
    try:
        with os.fdopen(descriptor, "rb") as handle:
            data = handle.read(maximum_bytes + 1)
    except OSError as error:
        raise ProgramError(f"cannot read {label} {path}: {error}") from error
    if len(data) > maximum_bytes:
        fail(f"{label} exceeds {maximum_bytes} bytes")
    return data


def read_journal(path: Path) -> list[dict[str, Any]]:
    descriptor = open_regular_descriptor(
        path,
        "journal",
        maximum_bytes=MAX_JOURNAL_BYTES,
    )
    try:
        with os.fdopen(descriptor, "rb") as handle:
            return parse_journal_rows(handle)
    except OSError as error:
        raise ProgramError(f"cannot read journal {path}: {error}") from error


def open_directory_descriptor(path: Path, label: str) -> int:
    metadata = lstat_path(path)
    if metadata is None:
        fail(f"{label} does not exist: {path}")
    if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISDIR(metadata.st_mode):
        fail(f"{label} must be a non-symlink directory: {path}")
    flags = os.O_RDONLY | getattr(os, "O_DIRECTORY", 0) | getattr(os, "O_NOFOLLOW", 0)
    descriptor: int | None = None
    try:
        descriptor = os.open(path, flags)
        opened = os.fstat(descriptor)
    except OSError as error:
        if descriptor is not None:
            os.close(descriptor)
        raise ProgramError(f"cannot open {label} {path}: {error}") from error
    assert descriptor is not None
    if not stat.S_ISDIR(opened.st_mode) or (opened.st_dev, opened.st_ino) != (
        metadata.st_dev,
        metadata.st_ino,
    ):
        os.close(descriptor)
        fail(f"{label} changed while opening: {path}")
    return descriptor


def read_regular_at(
    directory_descriptor: int,
    name: str,
    label: str,
    *,
    maximum_bytes: int,
) -> bytes:
    try:
        metadata = os.stat(name, dir_fd=directory_descriptor, follow_symlinks=False)
    except FileNotFoundError:
        fail(f"{label} does not exist")
    except OSError as error:
        raise ProgramError(f"cannot inspect {label}: {error}") from error
    if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISREG(metadata.st_mode):
        fail(f"{label} must be a non-symlink regular file")
    if metadata.st_size > maximum_bytes:
        fail(f"{label} exceeds {maximum_bytes} bytes")
    flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
    descriptor: int | None = None
    try:
        descriptor = os.open(name, flags, dir_fd=directory_descriptor)
        opened = os.fstat(descriptor)
    except OSError as error:
        if descriptor is not None:
            os.close(descriptor)
        raise ProgramError(f"cannot open {label}: {error}") from error
    assert descriptor is not None
    if not stat.S_ISREG(opened.st_mode) or (opened.st_dev, opened.st_ino) != (
        metadata.st_dev,
        metadata.st_ino,
    ):
        os.close(descriptor)
        fail(f"{label} changed while opening")
    try:
        with os.fdopen(descriptor, "rb") as handle:
            data = handle.read(maximum_bytes + 1)
    except OSError as error:
        raise ProgramError(f"cannot read {label}: {error}") from error
    if len(data) > maximum_bytes:
        fail(f"{label} exceeds {maximum_bytes} bytes")
    return data


def open_state_lock(programs: Path) -> tuple[int, int, os.stat_result]:
    programs_descriptor = open_directory_descriptor(programs, "program state root")
    flags = os.O_RDONLY | getattr(os, "O_DIRECTORY", 0) | getattr(os, "O_NOFOLLOW", 0)
    lock_descriptor: int | None = None
    try:
        expected_lock = os.stat(
            ".state-lock",
            dir_fd=programs_descriptor,
            follow_symlinks=False,
        )
        if stat.S_ISLNK(expected_lock.st_mode) or not stat.S_ISDIR(
            expected_lock.st_mode
        ):
            fail("state lock must be a non-symlink directory")
        lock_descriptor = os.open(
            ".state-lock",
            flags,
            dir_fd=programs_descriptor,
        )
        lock_metadata = os.fstat(lock_descriptor)
    except ProgramError:
        os.close(programs_descriptor)
        raise
    except OSError as error:
        if lock_descriptor is not None:
            os.close(lock_descriptor)
        os.close(programs_descriptor)
        raise ProgramError(f"cannot open state lock: {error}") from error
    assert lock_descriptor is not None
    if not stat.S_ISDIR(lock_metadata.st_mode) or (
        lock_metadata.st_dev,
        lock_metadata.st_ino,
    ) != (expected_lock.st_dev, expected_lock.st_ino):
        os.close(lock_descriptor)
        os.close(programs_descriptor)
        fail("state lock must be a non-symlink directory")
    return programs_descriptor, lock_descriptor, lock_metadata


def read_lock_owner(lock_descriptor: int) -> dict[str, Any]:
    owner = strict_json_loads(
        read_regular_at(
            lock_descriptor,
            "owner.json",
            "state lock owner",
            maximum_bytes=MAX_LOCK_OWNER_BYTES,
        ),
        "state lock owner",
    )
    if not isinstance(owner, dict):
        fail("state lock owner must contain one JSON object")
    return owner


def remove_lock_directory(programs: Path, expected_token: str) -> None:
    programs_descriptor, lock_descriptor, opened_lock = open_state_lock(programs)
    quarantine = f".state-lock.quarantine.{secrets.token_hex(12)}"
    quarantined = False
    destructive_started = False
    try:
        owner = read_lock_owner(lock_descriptor)
        if owner.get("token") != expected_token:
            fail("observed lock token changed")
        os.rename(
            ".state-lock",
            quarantine,
            src_dir_fd=programs_descriptor,
            dst_dir_fd=programs_descriptor,
        )
        quarantined = True
        quarantined_lock = os.stat(
            quarantine,
            dir_fd=programs_descriptor,
            follow_symlinks=False,
        )
        if not stat.S_ISDIR(quarantined_lock.st_mode) or (
            quarantined_lock.st_dev,
            quarantined_lock.st_ino,
        ) != (opened_lock.st_dev, opened_lock.st_ino):
            fail("state lock changed before quarantine")
        owner = read_lock_owner(lock_descriptor)
        if owner.get("token") != expected_token:
            fail("observed lock token changed after quarantine")
        entries = sorted(os.listdir(lock_descriptor))
        if entries != ["owner.json"]:
            fail("state lock contains unexpected files")
        destructive_started = True
        os.unlink("owner.json", dir_fd=lock_descriptor)
        try:
            os.fsync(lock_descriptor)
        except OSError as error:
            if error.errno not in {errno.EINVAL, errno.ENOTSUP, errno.EBADF}:
                raise
        os.rmdir(quarantine, dir_fd=programs_descriptor)
        quarantined = False
        try:
            os.fsync(programs_descriptor)
        except OSError as error:
            if error.errno not in {errno.EINVAL, errno.ENOTSUP, errno.EBADF}:
                raise
    except ProgramError:
        raise
    except OSError as error:
        raise ProgramError(f"cannot remove selected state lock: {error}") from error
    finally:
        if quarantined and not destructive_started:
            try:
                os.stat(
                    ".state-lock",
                    dir_fd=programs_descriptor,
                    follow_symlinks=False,
                )
            except FileNotFoundError:
                try:
                    os.rename(
                        quarantine,
                        ".state-lock",
                        src_dir_fd=programs_descriptor,
                        dst_dir_fd=programs_descriptor,
                    )
                except OSError:
                    pass
            except OSError:
                pass
        os.close(lock_descriptor)
        os.close(programs_descriptor)


def fsync_directory(path: Path) -> None:
    if os.name == "nt":
        return
    flags = os.O_RDONLY | getattr(os, "O_DIRECTORY", 0)
    try:
        descriptor = os.open(path, flags)
        try:
            os.fsync(descriptor)
        finally:
            os.close(descriptor)
    except OSError as error:
        if error.errno not in {errno.EINVAL, errno.ENOTSUP, errno.EBADF}:
            raise ProgramError(f"cannot fsync directory {path}: {error}") from error


def atomic_write(path: Path, data: bytes) -> None:
    ensure_directory(path.parent, create=False)
    existing = lstat_path(path)
    if existing is not None and (
        stat.S_ISLNK(existing.st_mode) or not stat.S_ISREG(existing.st_mode)
    ):
        fail(f"atomic target must be a non-symlink regular file: {path}")
    temporary = path.parent / f".{path.name}.tmp.{secrets.token_hex(12)}"
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0)
    descriptor: int | None = None
    try:
        descriptor = os.open(temporary, flags, 0o600)
        with os.fdopen(descriptor, "wb") as handle:
            descriptor = None
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
        fsync_directory(path.parent)
    except OSError as error:
        raise ProgramError(f"atomic write failed for {path}: {error}") from error
    finally:
        if descriptor is not None:
            os.close(descriptor)
        try:
            temporary.unlink()
        except FileNotFoundError:
            pass


def read_json_file(
    path: Path, label: str, *, maximum_bytes: int = MAX_SNAPSHOT_BYTES
) -> dict[str, Any]:
    payload = strict_json_loads(
        read_regular_bytes(path, label, maximum_bytes=maximum_bytes),
        label,
    )
    if not isinstance(payload, dict):
        fail(f"{label} must contain one JSON object")
    return payload


def read_active(root: Path, *, required: bool) -> dict[str, Any] | None:
    path = programs_root(root, create=False) / "active.json"
    if lstat_path(path) is None:
        if required:
            fail("active program pointer does not exist")
        return None
    active = read_json_file(
        path,
        "active pointer",
        maximum_bytes=MAX_ACTIVE_BYTES,
    )
    if set(active) != {"schema_version", "program_id"}:
        fail("active pointer has missing or unknown fields")
    if (
        type(active["schema_version"]) is not int
        or active["schema_version"] != SCHEMA_VERSION
    ):
        fail("active pointer has unsupported schema version")
    require_program_id(active["program_id"], "active program_id")
    return active


def active_bytes(program_id: str) -> bytes:
    return (
        canonical_json({"schema_version": SCHEMA_VERSION, "program_id": program_id})
        + b"\n"
    )


def snapshot_bytes(state: dict[str, Any]) -> bytes:
    snapshot = canonical_json(state) + b"\n"
    if len(snapshot) > MAX_SNAPSHOT_BYTES:
        fail(f"snapshot exceeds {MAX_SNAPSHOT_BYTES} bytes")
    return snapshot


def read_snapshot_status(path: Path, state: dict[str, Any]) -> str:
    if lstat_path(path) is None:
        return "missing"
    try:
        data = read_regular_bytes(
            path,
            "snapshot",
            maximum_bytes=MAX_SNAPSHOT_BYTES,
        )
        snapshot = strict_json_loads(data, "snapshot")
        if not isinstance(snapshot, dict):
            return "invalid"
        if data != canonical_json(snapshot) + b"\n":
            return "invalid"
    except ProgramError:
        return "invalid"
    return "current" if snapshot == state else "stale"


def load_program(root: str | Path, program_id: str | None = None) -> LoadedProgram:
    resolved = resolve_root(root)
    if program_id is None:
        active = read_active(resolved, required=True)
        assert active is not None
        program_id = active["program_id"]
    require_program_id(program_id)
    directory = program_directory(resolved, program_id)
    events = read_journal(directory / "journal.jsonl")
    state = replay(events)
    if state["program_id"] != program_id:
        fail("journal program ID does not match selected directory")
    return LoadedProgram(resolved, program_id, directory, events, state)


def current_git_head(root: Path) -> str:
    result = subprocess.run(
        ["git", "-C", str(root), "rev-parse", "HEAD"],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        fail("repository root must have a readable Git HEAD")
    return require_commit(result.stdout.strip(), "Git HEAD")


def verify_occurrence(root: Path, payload: dict[str, Any]) -> None:
    commit = payload["commit_sha"]
    result = subprocess.run(
        ["git", "-C", str(root), "rev-parse", f"{commit}^"],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        fail(f"occurrence commit has no readable parent: {commit}")
    parent = require_commit(result.stdout.strip(), "occurrence Git parent")
    if parent != payload["parent_sha"]:
        fail("occurrence parent does not match repository history")
    if current_git_head(root) != commit:
        fail("occurrence commit must be repository HEAD when recorded")


def find_event(loaded: LoadedProgram, event_id: str) -> dict[str, Any] | None:
    require_identifier(event_id, "event_id")
    return next(
        (event for event in loaded.events if event["event_id"] == event_id),
        None,
    )


def commit_resolves(root: Path, commit: str) -> bool:
    result = subprocess.run(
        [
            "git",
            "-C",
            str(root),
            "rev-parse",
            "--verify",
            "--quiet",
            f"{commit}^{{commit}}",
        ],
        check=False,
        capture_output=True,
        text=True,
    )
    return result.returncode == 0


def commit_is_ancestor(root: Path, commit: str, descendant: str) -> bool:
    result = subprocess.run(
        ["git", "-C", str(root), "merge-base", "--is-ancestor", commit, descendant],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode not in {0, 1}:
        fail("repository root must support Git ancestry checks")
    return result.returncode == 0


def verify_landing_head(
    root: Path, state: dict[str, Any], payload: dict[str, Any]
) -> None:
    receipt = state["receipts"].get(payload["receipt_id"])
    if receipt is None or receipt["unit_id"] != payload["unit_id"]:
        return
    if receipt["delivery_kind"] != "occurrence":
        return
    commit = receipt["commit_sha"]
    if not commit_resolves(root, commit):
        fail(f"occurrence commit no longer resolves: {commit}")
    # A later unit can commit before this unit lands. Reachability, not HEAD
    # equality, proves the recorded commit still belongs to current history.
    if not commit_is_ancestor(root, commit, "HEAD"):
        fail(
            "occurrence commit must remain reachable from repository HEAD "
            "when unit lands"
        )


class StateLock(AbstractContextManager["StateLock"]):
    def __init__(self, root: Path, program_id: str):
        require_program_state_excluded(root, program_id)
        self.programs = programs_root(root, create=True)
        self.path = self.programs / ".state-lock"
        self.owner = self.path / "owner.json"
        self.token = secrets.token_hex(16)

    def __enter__(self) -> Self:
        # Another writer usually holds the lock for a short time. Retry with a
        # deterministic backoff before reporting contention.
        for attempt in range(LOCK_ATTEMPTS):
            try:
                self.path.mkdir(mode=0o700)
                break
            except FileExistsError as error:
                if attempt + 1 == LOCK_ATTEMPTS:
                    raise ProgramError(LOCK_CONTENTION_MESSAGE) from error
                time.sleep(LOCK_BACKOFF_SECONDS * 2**attempt)
            except OSError as error:
                raise ProgramError(
                    f"cannot create program state lock: {error}"
                ) from error
        payload = {
            "token": self.token,
            "pid": os.getpid(),
            "host": socket.gethostname(),
            "created_at": utc_now(),
        }
        try:
            atomic_write(self.owner, canonical_json(payload) + b"\n")
        except Exception:
            try:
                self.path.rmdir()
            except OSError:
                pass
            raise
        return self

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: TracebackType | None,
    ) -> bool:
        cleanup_error: ProgramError | None = None
        try:
            remove_lock_directory(self.programs, self.token)
        except ProgramError as error:
            cleanup_error = error
        if cleanup_error is not None and exc_type is None:
            raise cleanup_error
        return False


def require_active(root: Path, program_id: str) -> None:
    active = read_active(root, required=True)
    assert active is not None
    if active["program_id"] != program_id:
        fail(f"active program is {active['program_id']}; expected {program_id}")


def write_program(
    events: list[dict[str, Any]], loaded: LoadedProgram
) -> dict[str, Any]:
    state = replay(events)
    journal = journal_bytes(events)
    snapshot = snapshot_bytes(state)
    atomic_write(loaded.journal_path, journal)
    atomic_write(loaded.snapshot_path, snapshot)
    return state


def init_program(
    root: str | Path,
    *,
    program_id: str,
    goal: str,
    base_commit: str,
    actor: str,
    event_id: str,
    recorded_at: str | None = None,
) -> dict[str, Any]:
    resolved = resolve_root(root)
    require_program_id(program_id)
    require_string(goal, "goal")
    require_commit(base_commit, "base_commit")
    require_identifier(actor, "actor")
    require_identifier(event_id, "event_id")
    if current_git_head(resolved) != base_commit:
        fail("initial base commit does not match repository HEAD")
    at = recorded_at or utc_now()
    require_utc(at, "recorded_at")
    with StateLock(resolved, program_id):
        active = read_active(resolved, required=False)
        if active is not None:
            previous = load_program(resolved, active["program_id"])
            if previous.state["status"] not in {"completed", "aborted"}:
                fail(f"active program is not terminal: {active['program_id']}")
        directory = programs_root(resolved, create=True) / program_id
        if lstat_path(directory) is not None:
            fail(f"program directory already exists: {program_id}")
        directory = program_directory(resolved, program_id, create=True)
        event = make_event(
            program_id=program_id,
            sequence=1,
            event_id=event_id,
            event_type="program_initialized",
            recorded_at=at,
            actor=actor,
            payload={"goal": goal, "base_commit": base_commit},
            previous_hash=ZERO_HASH,
        )
        loaded = LoadedProgram(
            resolved,
            program_id,
            directory,
            [],
            initial_state(program_id),
        )
        state = write_program([event], loaded)
        atomic_write(
            programs_root(resolved, create=True) / "active.json",
            active_bytes(program_id),
        )
        return state


def record_event(
    root: str | Path,
    *,
    program_id: str,
    expected_head: str,
    event_type: str,
    actor: str,
    event_id: str,
    payload: dict[str, Any],
    recorded_at: str | None = None,
) -> dict[str, Any]:
    resolved = resolve_root(root)
    require_program_id(program_id)
    require_digest(expected_head, "expected_head")
    require_identifier(actor, "actor")
    require_identifier(event_id, "event_id")
    if event_type not in EVENT_TYPES or event_type == "program_initialized":
        fail(f"record cannot append event type: {event_type}")
    at = recorded_at or utc_now()
    require_utc(at, "recorded_at")
    with StateLock(resolved, program_id):
        require_active(resolved, program_id)
        loaded = load_program(resolved, program_id)
        existing = find_event(loaded, event_id)
        if existing is not None:
            fail(
                f"event ID already recorded at sequence {existing['sequence']} "
                f"with hash {existing['event_hash']}"
            )
        if loaded.state["head"] != expected_head:
            fail(f"expected head {expected_head} does not match {loaded.state['head']}")
        validate_payload(event_type, payload)
        if (
            event_type == "lease_acquired"
            and current_git_head(resolved) != payload["base_commit"]
        ):
            fail("lease base commit does not match repository HEAD")
        if event_type == "occurrence_receipt_recorded":
            verify_occurrence(resolved, payload)
        if event_type == "unit_landed":
            verify_landing_head(resolved, loaded.state, payload)
        event = make_event(
            program_id=program_id,
            sequence=loaded.state["sequence"] + 1,
            event_id=event_id,
            event_type=event_type,
            recorded_at=at,
            actor=actor,
            payload=payload,
            previous_hash=loaded.state["head"],
        )
        return write_program(loaded.events + [event], loaded)


def state_view(loaded: LoadedProgram, at: str | None = None) -> dict[str, Any]:
    now = at or utc_now()
    require_utc(now, "status time")
    state = copy.deepcopy(loaded.state)
    state["snapshot_status"] = read_snapshot_status(loaded.snapshot_path, loaded.state)
    state["expired_lease_ids"] = sorted(
        lease_id
        for lease_id, lease in state["leases"].items()
        if lease["status"] == "active"
        and parse_utc(lease["expires_at"]) <= parse_utc(now)
    )
    state["dispatchable_unit_ids"] = sorted(
        unit_id
        for unit_id, unit in state["units"].items()
        if unit["status"] == "ready"
        and all(
            dependency_is_landed(state, dependency)
            for dependency in unit["dependencies"]
        )
        and requirements_are_covered(state, unit, now)
    )
    return state


def scan_lock(root: Path, at: str) -> dict[str, Any] | None:
    path = programs_root(root, create=False) / ".state-lock"
    metadata = lstat_path(path)
    if metadata is None:
        return None
    if stat.S_ISLNK(metadata.st_mode) or not stat.S_ISDIR(metadata.st_mode):
        fail("state lock must be a non-symlink directory")
    owner_path = path / "owner.json"
    if lstat_path(owner_path) is None:
        return {"status": "owner-missing", "path": ".state-lock"}
    owner = read_json_file(
        owner_path,
        "state lock owner",
        maximum_bytes=MAX_LOCK_OWNER_BYTES,
    )
    expected = {"token", "pid", "host", "created_at"}
    if set(owner) != expected:
        fail("state lock owner has missing or unknown fields")
    require_identifier(owner["token"], "lock token")
    if type(owner["pid"]) is not int or owner["pid"] < 1:
        fail("state lock PID must be a positive integer")
    require_string(owner["host"], "state lock host", maximum=255)
    require_utc(owner["created_at"], "state lock creation time")
    age = max(0, int((parse_utc(at) - parse_utc(owner["created_at"])).total_seconds()))
    return {"status": "present", **owner, "age_seconds": age}


def file_digest(path: Path) -> str:
    return hashlib.sha256(
        read_regular_bytes(
            path,
            "recovery file",
            maximum_bytes=MAX_JOURNAL_BYTES,
        )
    ).hexdigest()


def orphan_temporaries(root: Path, program_id: str | None) -> list[dict[str, str]]:
    base = programs_root(root, create=False)
    directories = [base]
    if program_id is not None:
        directories.append(program_directory(root, program_id))
    result: list[dict[str, str]] = []
    for directory in directories:
        for path in sorted(directory.iterdir(), key=lambda item: item.name):
            if TEMP_NAME_RE.fullmatch(path.name) is None:
                continue
            metadata = lstat_path(path)
            if (
                metadata is None
                or stat.S_ISLNK(metadata.st_mode)
                or not stat.S_ISREG(metadata.st_mode)
            ):
                continue
            result.append(
                {
                    "path": path.relative_to(base).as_posix(),
                    "digest": file_digest(path),
                }
            )
    return result


def recovery_plan(
    root: str | Path,
    *,
    program_id: str | None = None,
    observed_at: str | None = None,
) -> dict[str, Any]:
    resolved = resolve_root(root)
    at = observed_at or utc_now()
    require_utc(at, "observed_at")
    report: dict[str, Any] = {
        "schema_version": SCHEMA_VERSION,
        "observed_at": at,
        "lock": None,
        "active_pointer": None,
        "program_id": program_id,
        "journal_valid": None,
        "journal_error": None,
        "head": None,
        "snapshot_status": None,
        "expired_lease_ids": [],
        "orphan_temporaries": [],
        "actions": [],
    }
    try:
        report["lock"] = scan_lock(resolved, at)
    except ProgramError as error:
        report["lock"] = {"status": "invalid", "error": str(error)}
    try:
        active = read_active(resolved, required=False)
        report["active_pointer"] = active
    except ProgramError as error:
        active = None
        report["active_pointer"] = {"status": "invalid", "error": str(error)}
    selected = program_id or (active["program_id"] if active else None)
    report["program_id"] = selected
    if selected is not None:
        try:
            loaded = load_program(resolved, selected)
            report["journal_valid"] = True
            report["head"] = loaded.state["head"]
            report["snapshot_status"] = read_snapshot_status(
                loaded.snapshot_path, loaded.state
            )
            view = state_view(loaded, at)
            report["expired_lease_ids"] = view["expired_lease_ids"]
            if report["snapshot_status"] != "current":
                report["actions"].append({"action": "rebuild-snapshot"})
            if active is None or active.get("program_id") != selected:
                report["actions"].append({"action": "restore-active"})
        except ProgramError as error:
            report["journal_valid"] = False
            report["journal_error"] = str(error)
            report["actions"].append(
                {"action": "manual-journal-recovery", "reason": str(error)}
            )
    try:
        report["orphan_temporaries"] = orphan_temporaries(resolved, selected)
        report["actions"].extend(
            {"action": "remove-temp", **temporary}
            for temporary in report["orphan_temporaries"]
        )
    except ProgramError as error:
        report["actions"].append(
            {"action": "manual-path-recovery", "reason": str(error)}
        )
    if report["lock"] is not None:
        report["actions"].append(
            {
                "action": "inspect-lock",
                "require_external_writer_evidence": True,
            }
        )
    return report


def validate_recovery_head(
    root: Path, program_id: str, expected_head: str
) -> LoadedProgram:
    require_digest(expected_head, "expected_head")
    loaded = load_program(root, program_id)
    if loaded.state["head"] != expected_head:
        fail(f"expected head {expected_head} does not match {loaded.state['head']}")
    return loaded


def safe_temporary_path(root: Path, relative_path: str) -> Path:
    base = programs_root(root, create=False)
    pure = PurePosixPath(relative_path)
    if (
        pure.is_absolute()
        or not pure.parts
        or any(part in {"", ".", ".."} for part in pure.parts)
    ):
        fail("temporary path must be a canonical relative path")
    candidate = base.joinpath(*pure.parts)
    if TEMP_NAME_RE.fullmatch(candidate.name) is None:
        fail("recovery target is not a recognized temporary file")
    current = base
    for part in pure.parts[:-1]:
        current = ensure_directory(current / part, create=False)
    return candidate


def remove_stale_lock(
    root: Path,
    *,
    program_id: str,
    expected_head: str,
    lock_token: str,
    evidence_ref: str,
) -> dict[str, Any]:
    loaded = validate_recovery_head(root, program_id, expected_head)
    require_identifier(lock_token, "lock_token")
    require_string(evidence_ref, "evidence_ref")
    require_program_state_excluded(root, program_id)
    remove_lock_directory(programs_root(root, create=False), lock_token)
    return {
        "action": "remove-lock",
        "program_id": program_id,
        "head": loaded.state["head"],
        "evidence_ref": evidence_ref,
    }


def recovery_apply(
    root: str | Path,
    *,
    program_id: str,
    expected_head: str,
    action: str,
    relative_path: str | None = None,
    expected_file_digest: str | None = None,
    lock_token: str | None = None,
    evidence_ref: str | None = None,
) -> dict[str, Any]:
    resolved = resolve_root(root)
    require_program_id(program_id)
    if action == "remove-lock":
        if lock_token is None or evidence_ref is None:
            fail("remove-lock requires lock token and external evidence reference")
        return remove_stale_lock(
            resolved,
            program_id=program_id,
            expected_head=expected_head,
            lock_token=lock_token,
            evidence_ref=evidence_ref,
        )
    with StateLock(resolved, program_id):
        loaded = validate_recovery_head(resolved, program_id, expected_head)
        if action == "rebuild-snapshot":
            atomic_write(loaded.snapshot_path, snapshot_bytes(loaded.state))
        elif action == "restore-active":
            try:
                active = read_active(resolved, required=False)
            except ProgramError:
                active = None
            if active is not None and active["program_id"] != program_id:
                current = load_program(resolved, active["program_id"])
                if current.state["status"] not in {"completed", "aborted"}:
                    fail("cannot replace a nonterminal active program pointer")
            atomic_write(
                programs_root(resolved, create=False) / "active.json",
                active_bytes(program_id),
            )
        elif action == "remove-temp":
            if relative_path is None or expected_file_digest is None:
                fail("remove-temp requires path and file digest")
            require_digest(expected_file_digest, "file_digest")
            target = safe_temporary_path(resolved, relative_path)
            if file_digest(target) != expected_file_digest:
                fail("temporary file digest changed")
            try:
                target.unlink()
                fsync_directory(target.parent)
            except OSError as error:
                raise ProgramError(
                    f"cannot remove selected temporary file: {error}"
                ) from error
        else:
            fail(f"unknown recovery action: {action}")
        return {
            "action": action,
            "program_id": program_id,
            "head": loaded.state["head"],
        }


def load_payload(path: str) -> dict[str, Any]:
    if path == "-":
        data = sys.stdin.buffer.read(MAX_EVENT_BYTES + 1)
        if len(data) > MAX_EVENT_BYTES:
            fail(f"payload stdin exceeds {MAX_EVENT_BYTES} bytes")
        label = "payload stdin"
    else:
        payload_path = Path(path).expanduser()
        data = read_regular_bytes(
            payload_path,
            "payload file",
            maximum_bytes=MAX_EVENT_BYTES,
        )
        label = f"payload file {payload_path}"
    payload = strict_json_loads(data, label)
    if not isinstance(payload, dict):
        fail("event payload must be a JSON object")
    return payload


class JsonArgumentParser(argparse.ArgumentParser):
    def error(self, message: str) -> NoReturn:
        fail(f"argument error: {message}")


def build_parser() -> argparse.ArgumentParser:
    parser = JsonArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    initialize = subparsers.add_parser("init")
    initialize.add_argument("root")
    initialize.add_argument("--program-id", required=True)
    initialize.add_argument("--goal", required=True)
    initialize.add_argument("--base-commit", required=True)
    initialize.add_argument("--actor", required=True)
    initialize.add_argument("--event-id", required=True)

    status = subparsers.add_parser("status")
    status.add_argument("root")
    status.add_argument("--program-id")

    validate = subparsers.add_parser("validate")
    validate.add_argument("root")
    validate.add_argument("--program-id")
    validate.add_argument("--event-id")

    plan = subparsers.add_parser("recover-plan")
    plan.add_argument("root")
    plan.add_argument("--program-id")

    record = subparsers.add_parser("record")
    record.add_argument("root")
    record.add_argument("--program-id", required=True)
    record.add_argument("--expected-head", required=True)
    record.add_argument(
        "--event-type",
        required=True,
        choices=sorted(EVENT_TYPES - {"program_initialized"}),
    )
    record.add_argument("--actor", required=True)
    record.add_argument("--event-id", required=True)
    record.add_argument("--payload-file", required=True)

    recover = subparsers.add_parser("recover-apply")
    recover.add_argument("root")
    recover.add_argument("--program-id", required=True)
    recover.add_argument("--expected-head", required=True)
    recover.add_argument(
        "--action",
        required=True,
        choices=("rebuild-snapshot", "restore-active", "remove-temp", "remove-lock"),
    )
    recover.add_argument("--relative-path")
    recover.add_argument("--file-digest")
    recover.add_argument("--lock-token")
    recover.add_argument("--evidence-ref")
    return parser


def success(payload: dict[str, Any]) -> None:
    print(json.dumps({"ok": True, **payload}, sort_keys=True))


def main(argv: list[str] | None = None) -> int:
    try:
        args = build_parser().parse_args(argv)
        if args.command == "init":
            state = init_program(
                args.root,
                program_id=args.program_id,
                goal=args.goal,
                base_commit=args.base_commit,
                actor=args.actor,
                event_id=args.event_id,
            )
            success({"state": state})
        elif args.command == "status":
            loaded = load_program(args.root, args.program_id)
            success({"state": state_view(loaded)})
        elif args.command == "validate":
            loaded = load_program(args.root, args.program_id)
            event = (
                find_event(loaded, args.event_id) if args.event_id is not None else None
            )
            event_lookup = (
                {
                    "requested_event_id": args.event_id,
                    "found": event is not None,
                    "event": (
                        {
                            "event_id": event["event_id"],
                            "event_type": event["event_type"],
                            "sequence": event["sequence"],
                            "recorded_at": event["recorded_at"],
                            "event_hash": event["event_hash"],
                        }
                        if event is not None
                        else None
                    ),
                }
                if args.event_id is not None
                else None
            )
            success(
                {
                    "program_id": loaded.program_id,
                    "head": loaded.state["head"],
                    "sequence": loaded.state["sequence"],
                    "snapshot_status": read_snapshot_status(
                        loaded.snapshot_path, loaded.state
                    ),
                    "event_lookup": event_lookup,
                }
            )
        elif args.command == "record":
            state = record_event(
                args.root,
                program_id=args.program_id,
                expected_head=args.expected_head,
                event_type=args.event_type,
                actor=args.actor,
                event_id=args.event_id,
                payload=load_payload(args.payload_file),
            )
            success({"state": state})
        elif args.command == "recover-plan":
            success({"plan": recovery_plan(args.root, program_id=args.program_id)})
        elif args.command == "recover-apply":
            result = recovery_apply(
                args.root,
                program_id=args.program_id,
                expected_head=args.expected_head,
                action=args.action,
                relative_path=args.relative_path,
                expected_file_digest=args.file_digest,
                lock_token=args.lock_token,
                evidence_ref=args.evidence_ref,
            )
            success({"result": result})
        else:
            fail(f"unknown command: {args.command}")
        return 0
    except ProgramError as error:
        print(
            json.dumps({"ok": False, "error": str(error)}, sort_keys=True),
            file=sys.stderr,
        )
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
