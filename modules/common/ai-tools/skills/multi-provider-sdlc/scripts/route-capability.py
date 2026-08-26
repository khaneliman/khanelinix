#!/usr/bin/env python3
"""Track task-local provider capability circuits and select eligible routes."""

from __future__ import annotations

import argparse
import contextlib
import errno
import fcntl
import hashlib
import importlib.util
import json
import os
import re
import secrets
import stat
import sys
import tempfile
from collections.abc import Iterator, Sequence
from pathlib import Path
from typing import Any

SKILL_ROOT = Path(__file__).resolve().parents[1]
REGISTRY_PATH = SKILL_ROOT / "references" / "model-routing.json"
RENDERER_PATH = SKILL_ROOT / "scripts" / "render-model-routes.py"
STATE_SCHEMA_VERSION = 2
MAX_REGISTRY_BYTES = 256 * 1024
MAX_STATE_BYTES = 64 * 1024
MAX_TELEMETRY_BYTES = 64 * 1024
TASK_ID_RE = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]{0,79}\Z")
CLAIM_ID_RE = re.compile(r"[0-9a-f]{32}\Z")
CIRCUIT_STATES = {"unknown", "available", "open"}
MAX_ACTIVE_CLAIMS = 32
OUTCOMES = {
    "success",
    "quota-exhausted",
    "route-unavailable",
    "auth-failure",
    "connection-failure",
    "agent-type-unavailable",
    "agent-type-available",
    "dispatch-interrupted",
}
NON_CANDIDATE_OVERRIDE_REASONS = {
    "caller-capability-judgment",
    "explicit-model-request",
    "provider-diversity-seat",
}


class CapabilityError(ValueError):
    """Report invalid state, telemetry, or transitions without raw input."""


def load_renderer() -> Any:
    spec = importlib.util.spec_from_file_location("model_route_renderer", RENDERER_PATH)
    if spec is None or spec.loader is None:
        raise CapabilityError("cannot load model-routing validator")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def load_registry_context() -> tuple[dict[str, Any], str]:
    try:
        raw = read_regular_bytes(
            REGISTRY_PATH, "model-routing registry", MAX_REGISTRY_BYTES
        )
        registry = strict_json_loads(raw, "model-routing registry")
        if not isinstance(registry, dict):
            raise CapabilityError("model-routing registry must be an object")
        load_renderer().validate_registry(registry)
        return registry, hashlib.sha256(raw).hexdigest()
    except Exception as error:
        if isinstance(error, CapabilityError):
            raise
        raise CapabilityError(f"cannot load model-routing registry: {error}") from error


def load_registry() -> dict[str, Any]:
    return load_registry_context()[0]


def reject_constant(value: str) -> None:
    raise CapabilityError(f"JSON contains unsupported constant: {value}")


def strict_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    value: dict[str, Any] = {}
    for key, item in pairs:
        if key in value:
            raise CapabilityError(f"JSON contains duplicate key: {key}")
        value[key] = item
    return value


def strict_json_loads(raw: bytes, label: str) -> Any:
    try:
        return json.loads(
            raw,
            object_pairs_hook=strict_object,
            parse_constant=reject_constant,
        )
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise CapabilityError(f"{label} is not valid JSON") from error


def canonical_json(value: Any) -> bytes:
    return (
        json.dumps(
            value,
            ensure_ascii=True,
            allow_nan=False,
            separators=(",", ":"),
            sort_keys=True,
        )
        + "\n"
    ).encode()


def require_task_id(task_id: str) -> None:
    if not isinstance(task_id, str) or not TASK_ID_RE.fullmatch(task_id):
        raise CapabilityError(
            "task ID must use 1-80 letters, digits, dots, dashes, or underscores"
        )


def require_exact_keys(value: dict[str, Any], expected: set[str], label: str) -> None:
    if set(value) != expected:
        raise CapabilityError(f"{label} has unknown or missing fields")


def read_regular_bytes(path: Path, label: str, limit: int) -> bytes:
    flags = os.O_RDONLY | os.O_NONBLOCK | getattr(os, "O_NOFOLLOW", 0)
    try:
        descriptor = os.open(path, flags)
    except OSError as error:
        raise CapabilityError(
            f"cannot open {label} as a regular file: {error}"
        ) from error
    try:
        metadata = os.fstat(descriptor)
        if not stat.S_ISREG(metadata.st_mode):
            raise CapabilityError(f"{label} must be a regular file")
        if metadata.st_size > limit:
            raise CapabilityError(f"{label} exceeds {limit} bytes")
        raw = b""
        while len(raw) <= limit:
            chunk = os.read(descriptor, min(8192, limit + 1 - len(raw)))
            if not chunk:
                break
            raw += chunk
        if len(raw) > limit:
            raise CapabilityError(f"{label} exceeds {limit} bytes")
        return raw
    finally:
        os.close(descriptor)


def read_stream_bytes(stream: Any, label: str, limit: int) -> bytes:
    raw = stream.read(limit + 1)
    if len(raw) > limit:
        raise CapabilityError(f"{label} exceeds {limit} bytes")
    return raw


def state_path(value: Path) -> Path:
    path = value.expanduser()
    if not path.is_absolute():
        path = Path.cwd() / path
    if not path.parent.is_dir():
        raise CapabilityError("state parent directory must already exist")
    return path


@contextlib.contextmanager
def exclusive_state_lock(path: Path) -> Iterator[None]:
    lock_path = path.with_name(f"{path.name}.lock")
    flags = os.O_CREAT | os.O_RDWR | getattr(os, "O_NOFOLLOW", 0)
    try:
        descriptor = os.open(lock_path, flags, 0o600)
    except OSError as error:
        raise CapabilityError(
            f"cannot open state lock as a regular file: {error}"
        ) from error
    try:
        metadata = os.fstat(descriptor)
        if not stat.S_ISREG(metadata.st_mode):
            raise CapabilityError("state lock must be a regular file")
        fcntl.flock(descriptor, fcntl.LOCK_EX)
        yield
    finally:
        os.close(descriptor)


def write_state(path: Path, state: dict[str, Any]) -> None:
    descriptor, temporary_name = tempfile.mkstemp(
        dir=path.parent,
        prefix=f".{path.name}.",
        suffix=".tmp",
    )
    temporary_path = Path(temporary_name)
    try:
        os.fchmod(descriptor, 0o600)
        with os.fdopen(descriptor, "wb", closefd=True) as handle:
            handle.write(canonical_json(state))
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary_path, path)
        directory = os.open(path.parent, os.O_RDONLY)
        try:
            try:
                os.fsync(directory)
            except OSError as error:
                # Darwin can reject directory fsync after the file fsync succeeds.
                if error.errno not in {errno.EINVAL, errno.ENOTSUP}:
                    raise
        finally:
            os.close(directory)
    finally:
        if temporary_path.exists():
            temporary_path.unlink()


def new_state(task_id: str, registry: dict[str, Any], digest: str) -> dict[str, Any]:
    return {
        "schema_version": STATE_SCHEMA_VERSION,
        "registry_sha256": digest,
        "task_id": task_id,
        "revision": 0,
        "named_agents": "unknown",
        "providers": {
            subscription: "unknown" for subscription in registry["subscriptions"]
        },
        "pools": {
            subscription: {pool: "unknown" for pool in pools}
            for subscription, pools in registry["quota_pools"].items()
        },
        "routes": {model: "unknown" for model in registry["models"]},
        "claims": {},
    }


def model_scope_names(model_id: str, model: dict[str, Any]) -> set[str]:
    return {
        "named-agent-surface",
        f"provider:{model['subscription']}",
        f"pool:{model['subscription']}/{model['quota_pool']}",
        f"route:{model_id}",
    }


def validate_claims(value: Any, registry: dict[str, Any]) -> None:
    if not isinstance(value, dict) or len(value) > MAX_ACTIVE_CLAIMS:
        raise CapabilityError("claims must be a bounded object")
    occupied: set[str] = set()
    for claim_id, claim in value.items():
        if not isinstance(claim_id, str) or not CLAIM_ID_RE.fullmatch(claim_id):
            raise CapabilityError("claim ID has an invalid format")
        if not isinstance(claim, dict):
            raise CapabilityError("claim must be an object")
        require_exact_keys(
            claim,
            {
                "candidate_override",
                "model",
                "need",
                "plan_revision",
                "planned_candidates",
                "scopes",
            },
            f"claim {claim_id}",
        )
        model_id = claim["model"]
        need = claim["need"]
        plan_revision = claim["plan_revision"]
        planned_candidates = claim["planned_candidates"]
        candidate_override = claim["candidate_override"]
        scopes = claim["scopes"]
        if not isinstance(model_id, str) or model_id not in registry["models"]:
            raise CapabilityError("claim references an unknown model")
        routes = {route["need"]: route for route in registry["task_routes"]}
        if not isinstance(need, str) or need not in routes:
            raise CapabilityError("claim references an unknown task need")
        if type(plan_revision) is not int or plan_revision < 0:
            raise CapabilityError("claim plan revision must be a non-negative integer")
        route_models = [*routes[need]["preferred"], *routes[need]["fallbacks"]]
        if (
            not isinstance(planned_candidates, list)
            or any(not isinstance(candidate, str) for candidate in planned_candidates)
            or planned_candidates
            != [
                candidate
                for candidate in route_models
                if candidate in planned_candidates
            ]
        ):
            raise CapabilityError("claim has an invalid planned candidate set")
        if candidate_override is None:
            if model_id not in planned_candidates:
                raise CapabilityError("claim model is not a planned candidate")
        else:
            if not isinstance(candidate_override, dict):
                raise CapabilityError("claim has an invalid candidate override")
            require_exact_keys(
                candidate_override,
                {"marker", "reason"},
                "claim candidate override",
            )
            if (
                candidate_override["marker"] != "non-candidate"
                or not isinstance(candidate_override["reason"], str)
                or candidate_override["reason"] not in NON_CANDIDATE_OVERRIDE_REASONS
                or model_id in planned_candidates
            ):
                raise CapabilityError("claim has an invalid candidate override")
        if (
            not isinstance(scopes, list)
            or not scopes
            or any(not isinstance(scope, str) for scope in scopes)
            or scopes != sorted(set(scopes))
            or f"route:{model_id}" not in scopes
            or not set(scopes).issubset(
                model_scope_names(model_id, registry["models"][model_id])
            )
        ):
            raise CapabilityError("claim has invalid reserved scopes")
        if occupied.intersection(scopes):
            raise CapabilityError("active claims reserve the same scope")
        occupied.update(scopes)


def validate_claim_scope_coverage(
    state: dict[str, Any], registry: dict[str, Any]
) -> None:
    for claim in state["claims"].values():
        model_id = claim["model"]
        model = registry["models"][model_id]
        subscription = model["subscription"]
        pool = model["quota_pool"]
        required = {f"route:{model_id}"}
        if state["named_agents"] == "unknown":
            required.add("named-agent-surface")
        if state["providers"][subscription] == "unknown":
            required.add(f"provider:{subscription}")
        if state["pools"][subscription][pool] == "unknown":
            required.add(f"pool:{subscription}/{pool}")
        if not required.issubset(claim["scopes"]):
            raise CapabilityError("claim omits an unknown capability scope")


def validate_circuit_map(
    value: Any,
    expected_keys: set[str],
    label: str,
) -> None:
    if not isinstance(value, dict) or set(value) != expected_keys:
        raise CapabilityError(f"{label} must contain every canonical key")
    if any(
        not isinstance(status, str) or status not in CIRCUIT_STATES
        for status in value.values()
    ):
        raise CapabilityError(f"{label} contains an invalid circuit state")


def validate_state(
    state: Any,
    task_id: str,
    registry: dict[str, Any],
    digest: str,
) -> dict[str, Any]:
    if not isinstance(state, dict):
        raise CapabilityError("capability state must be an object")
    require_exact_keys(
        state,
        {
            "schema_version",
            "registry_sha256",
            "task_id",
            "revision",
            "named_agents",
            "providers",
            "pools",
            "routes",
            "claims",
        },
        "capability state",
    )
    if (
        type(state["schema_version"]) is not int
        or state["schema_version"] != STATE_SCHEMA_VERSION
    ):
        raise CapabilityError("unsupported capability state schema")
    if state["registry_sha256"] != digest:
        raise CapabilityError("capability state uses a different routing registry")
    if state["task_id"] != task_id:
        raise CapabilityError("capability state belongs to a different task")
    if type(state["revision"]) is not int or state["revision"] < 0:
        raise CapabilityError(
            "capability state revision must be a non-negative integer"
        )
    if (
        not isinstance(state["named_agents"], str)
        or state["named_agents"] not in CIRCUIT_STATES
    ):
        raise CapabilityError("named-agent surface has an invalid circuit state")
    validate_circuit_map(
        state["providers"], set(registry["subscriptions"]), "provider circuits"
    )
    if not isinstance(state["pools"], dict) or set(state["pools"]) != set(
        registry["quota_pools"]
    ):
        raise CapabilityError("pool circuits must contain every subscription")
    for subscription, pools in registry["quota_pools"].items():
        validate_circuit_map(
            state["pools"][subscription], set(pools), f"{subscription} pool circuits"
        )
    validate_circuit_map(state["routes"], set(registry["models"]), "route circuits")
    validate_claims(state["claims"], registry)
    if any(
        claim["plan_revision"] >= state["revision"]
        for claim in state["claims"].values()
    ):
        raise CapabilityError("claim plan revision must precede state revision")
    validate_claim_scope_coverage(state, registry)
    return state


def load_state(
    path: Path,
    task_id: str,
    registry: dict[str, Any],
    digest: str,
) -> dict[str, Any]:
    raw = read_regular_bytes(path, "capability state", MAX_STATE_BYTES)
    return validate_state(
        strict_json_loads(raw, "capability state"), task_id, registry, digest
    )


def initialize(path: Path, task_id: str) -> dict[str, Any]:
    require_task_id(task_id)
    path = state_path(path)
    registry, digest = load_registry_context()
    with exclusive_state_lock(path):
        if os.path.lexists(path):
            state = load_state(path, task_id, registry, digest)
            created = False
        else:
            state = new_state(task_id, registry, digest)
            write_state(path, state)
            created = True
    return {
        "created": created,
        "taskId": task_id,
        "revision": state["revision"],
        "registrySha256": digest,
    }


def require_revision(state: dict[str, Any], expected_revision: int) -> None:
    if type(expected_revision) is not int or expected_revision < 0:
        raise CapabilityError("expected revision must be a non-negative integer")
    if state["revision"] != expected_revision:
        raise CapabilityError(
            f"stale capability revision: expected {expected_revision}, current {state['revision']}"
        )


def mark_available(container: dict[str, str], key: str) -> bool:
    if container[key] != "unknown":
        return False
    container[key] = "available"
    return True


def mark_open(container: dict[str, str], key: str) -> bool:
    if container[key] == "open":
        return False
    container[key] = "open"
    return True


def mark_named_available(state: dict[str, Any]) -> bool:
    # The named-agent surface is recoverable inside one task because a host can
    # accept named agent types again. Quota-pool circuits stay open instead.
    if state["named_agents"] == "available":
        return False
    state["named_agents"] = "available"
    return True


def save_if_changed(path: Path, state: dict[str, Any], changed: bool) -> bool:
    if changed:
        state["revision"] += 1
        write_state(path, state)
    return changed


def record_outcome(
    path: Path,
    task_id: str,
    claim_id: str,
    outcome: str,
) -> dict[str, Any]:
    require_task_id(task_id)
    if not isinstance(outcome, str) or outcome not in OUTCOMES:
        raise CapabilityError("unsupported capability outcome")
    if not isinstance(claim_id, str) or not CLAIM_ID_RE.fullmatch(claim_id):
        raise CapabilityError("claim ID has an invalid format")
    path = state_path(path)
    registry, digest = load_registry_context()

    with exclusive_state_lock(path):
        state = load_state(path, task_id, registry, digest)
        if claim_id not in state["claims"]:
            raise CapabilityError("claim is not active")
        claim = state["claims"].pop(claim_id)
        model = claim["model"]
        need = claim["need"]
        route = registry["models"][model]
        subscription = route["subscription"]
        pool = route["quota_pool"]
        if outcome == "success":
            mark_named_available(state)
            mark_available(state["providers"], subscription)
            mark_available(state["pools"][subscription], pool)
            mark_available(state["routes"], model)
        elif outcome == "quota-exhausted":
            mark_named_available(state)
            mark_available(state["providers"], subscription)
            mark_open(state["pools"][subscription], pool)
        elif outcome == "route-unavailable":
            mark_named_available(state)
            mark_available(state["providers"], subscription)
            mark_open(state["routes"], model)
        elif outcome in {"auth-failure", "connection-failure"}:
            mark_named_available(state)
            mark_open(state["providers"], subscription)
        elif outcome == "agent-type-unavailable":
            # Availability evidence from a later outcome closes this surface.
            state["named_agents"] = "open"
        elif outcome == "agent-type-available":
            mark_named_available(state)
        else:
            mark_open(state["routes"], model)
        save_if_changed(path, state, True)

    return {
        "claimId": claim_id,
        "taskId": task_id,
        "revision": state["revision"],
        "outcome": outcome,
        "need": need,
        "model": model,
    }


def cancel_claim(path: Path, task_id: str, claim_id: str) -> dict[str, Any]:
    require_task_id(task_id)
    if not isinstance(claim_id, str) or not CLAIM_ID_RE.fullmatch(claim_id):
        raise CapabilityError("claim ID has an invalid format")
    path = state_path(path)
    registry, digest = load_registry_context()
    with exclusive_state_lock(path):
        state = load_state(path, task_id, registry, digest)
        if claim_id not in state["claims"]:
            raise CapabilityError("claim is not active")
        claim = state["claims"].pop(claim_id)
        model = claim["model"]
        need = claim["need"]
        save_if_changed(path, state, True)
    return {
        "cancelled": True,
        "claimId": claim_id,
        "taskId": task_id,
        "revision": state["revision"],
        "need": need,
        "model": model,
    }


def active_claim_scopes(state: dict[str, Any]) -> set[str]:
    return {scope for claim in state["claims"].values() for scope in claim["scopes"]}


def route_block_reason(
    state: dict[str, Any],
    model_id: str,
    model: dict[str, Any],
    *,
    include_named_surface: bool = True,
) -> str | None:
    subscription = model["subscription"]
    pool = model["quota_pool"]
    claimed = active_claim_scopes(state)
    if include_named_surface:
        if state["named_agents"] == "open":
            return "named-agent-surface"
        if "named-agent-surface" in claimed:
            return "claim:named-agent-surface"
    if state["routes"][model_id] == "open":
        return f"route:{model_id}"
    if f"route:{model_id}" in claimed:
        return f"claim:route:{model_id}"
    if state["providers"][subscription] == "open":
        return f"provider:{subscription}"
    if f"provider:{subscription}" in claimed:
        return f"claim:provider:{subscription}"
    if state["pools"][subscription][pool] == "open":
        return f"pool:{subscription}/{pool}"
    if f"pool:{subscription}/{pool}" in claimed:
        return f"claim:pool:{subscription}/{pool}"
    return None


def route_needs_probe(
    state: dict[str, Any], model_id: str, model: dict[str, Any]
) -> bool:
    subscription = model["subscription"]
    pool = model["quota_pool"]
    return "unknown" in {
        state["named_agents"],
        state["routes"][model_id],
        state["providers"][subscription],
        state["pools"][subscription][pool],
    }


def task_route(registry: dict[str, Any], need: str) -> dict[str, Any]:
    routes = {route["need"]: route for route in registry["task_routes"]}
    if not isinstance(need, str) or need not in routes:
        raise CapabilityError("unknown task need")
    return routes[need]


def candidate_model_ids(
    state: dict[str, Any], registry: dict[str, Any], route: dict[str, Any]
) -> list[str]:
    return [
        model_id
        for model_id in [*route["preferred"], *route["fallbacks"]]
        if route_block_reason(state, model_id, registry["models"][model_id]) is None
    ]


def semantic_fallback_models(
    registry: dict[str, Any], route: dict[str, Any], gateway_enabled: bool
) -> list[str]:
    role = registry["semantic_roles"][route["semantic_role"]]
    projection = role["gateway"] if gateway_enabled else role["native"]
    return sorted(
        {model for model in projection.values() if model in registry["models"]}
    )


def semantic_fallback_block_reason(
    state: dict[str, Any],
    registry: dict[str, Any],
    route: dict[str, Any],
    gateway_enabled: bool,
) -> str | None:
    # A gateway role runs on a named model, so it shares route, provider, and
    # pool circuits with the blocked candidates. The open named-agent surface is
    # excluded because the semantic role is the answer to that failure.
    reasons = []
    for model_id in semantic_fallback_models(registry, route, gateway_enabled):
        reason = route_block_reason(
            state,
            model_id,
            registry["models"][model_id],
            include_named_surface=False,
        )
        if reason is None:
            return None
        reasons.append(reason)
    return reasons[0] if reasons else None


def claim_route(
    path: Path,
    task_id: str,
    expected_revision: int,
    need: str,
    model_id: str,
    override_reason: str | None = None,
) -> dict[str, Any]:
    require_task_id(task_id)
    path = state_path(path)
    registry, digest = load_registry_context()
    if not isinstance(model_id, str) or model_id not in registry["models"]:
        raise CapabilityError("claim references an unknown model")
    if override_reason is not None and (
        not isinstance(override_reason, str)
        or override_reason not in NON_CANDIDATE_OVERRIDE_REASONS
    ):
        raise CapabilityError("claim has an invalid non-candidate override reason")
    with exclusive_state_lock(path):
        state = load_state(path, task_id, registry, digest)
        require_revision(state, expected_revision)
        if len(state["claims"]) >= MAX_ACTIVE_CLAIMS:
            raise CapabilityError("too many active claims")
        route = task_route(registry, need)
        planned_candidates = candidate_model_ids(state, registry, route)
        is_candidate = model_id in planned_candidates
        if not is_candidate and override_reason is None:
            raise CapabilityError(
                "claim model is not in the current planned candidate set"
            )
        if is_candidate and override_reason is not None:
            raise CapabilityError("non-candidate override is not valid for a candidate")
        model = registry["models"][model_id]
        reason = route_block_reason(state, model_id, model)
        if reason is not None:
            raise CapabilityError(f"route is unavailable: {reason}")
        scopes = {f"route:{model_id}"}
        if state["named_agents"] == "unknown":
            scopes.add("named-agent-surface")
        subscription = model["subscription"]
        if state["providers"][subscription] == "unknown":
            scopes.add(f"provider:{subscription}")
        pool = model["quota_pool"]
        if state["pools"][subscription][pool] == "unknown":
            scopes.add(f"pool:{subscription}/{pool}")
        claim_id = secrets.token_hex(16)
        while claim_id in state["claims"]:
            claim_id = secrets.token_hex(16)
        state["claims"][claim_id] = {
            "candidate_override": (
                None
                if override_reason is None
                else {"marker": "non-candidate", "reason": override_reason}
            ),
            "model": model_id,
            "need": need,
            "plan_revision": expected_revision,
            "planned_candidates": planned_candidates,
            "scopes": sorted(scopes),
        }
        save_if_changed(path, state, True)
    return {
        "claimId": claim_id,
        "taskId": task_id,
        "revision": state["revision"],
        "need": need,
        "model": model_id,
        "planRevision": expected_revision,
        "plannedCandidates": planned_candidates,
        "candidateOverride": state["claims"][claim_id]["candidate_override"],
        "probe": route_needs_probe(state, model_id, model),
        "reservedScopes": sorted(scopes),
    }


def plan_route(
    path: Path, task_id: str, need: str, gateway_enabled: bool = True
) -> dict[str, Any]:
    require_task_id(task_id)
    path = state_path(path)
    registry, digest = load_registry_context()
    state = load_state(path, task_id, registry, digest)
    route = task_route(registry, need)
    candidates = []
    preferred_candidates = []
    blocked = []
    for model_id in [*route["preferred"], *route["fallbacks"]]:
        model = registry["models"][model_id]
        reason = route_block_reason(state, model_id, model)
        if reason is not None:
            blocked.append({"model": model_id, "reason": reason})
            continue
        candidate = {
            "model": model_id,
            "subscription": model["subscription"],
            "pool": model["quota_pool"],
            "probe": route_needs_probe(state, model_id, model),
        }
        candidates.append(candidate)
        if model_id in route["preferred"]:
            preferred_candidates.append(candidate)
    claim_conflicts = any(
        blocked_route["reason"].startswith("claim:") for blocked_route in blocked
    )
    semantic_fallback: str | None = route["semantic_role"]
    semantic_fallback_reason: str | None = None
    if not candidates:
        if claim_conflicts:
            semantic_fallback_reason = "claim-conflict"
        else:
            semantic_fallback_reason = semantic_fallback_block_reason(
                state, registry, route, gateway_enabled
            )
        if semantic_fallback_reason is not None:
            semantic_fallback = None
    selection_required = len(preferred_candidates) > 1
    selected = None
    if not selection_required:
        selected_candidates = preferred_candidates or candidates
        selected = selected_candidates[0]["model"] if selected_candidates else None
    return {
        "taskId": task_id,
        "revision": state["revision"],
        "need": need,
        "semanticRole": route["semantic_role"],
        "writePolicy": route["write_policy"],
        "gatewayEnabled": gateway_enabled,
        "selected": selected,
        "selectionRequired": selection_required,
        "preferredCandidates": preferred_candidates,
        "candidates": candidates,
        "blocked": blocked,
        "claimConflicts": claim_conflicts,
        "semanticFallback": semantic_fallback,
        "semanticFallbackReason": semantic_fallback_reason,
    }


def expected_pool_models(
    registry: dict[str, Any], subscription: str, pool: str
) -> set[str]:
    return {
        model_id
        for model_id, model in registry["models"].items()
        if model["subscription"] == subscription and model["quota_pool"] == pool
    }


def validate_google_telemetry(
    value: Any, registry: dict[str, Any]
) -> dict[str, Any] | None:
    if not isinstance(value, dict) or value.get("provider") != "google":
        raise CapabilityError("Google telemetry must identify provider google")
    if "status" in value:
        require_exact_keys(value, {"provider", "status", "reason"}, "Google telemetry")
        if value["status"] != "unknown" or not isinstance(value["reason"], str):
            raise CapabilityError("Google provider telemetry has an invalid status")
        return None
    require_exact_keys(value, {"provider", "pools"}, "Google telemetry")
    pools = value["pools"]
    expected_pools = set(registry["quota_pools"]["google"])
    if not isinstance(pools, dict) or set(pools) != expected_pools:
        raise CapabilityError("Google telemetry must contain every canonical pool")
    for pool, report in pools.items():
        if not isinstance(report, dict):
            raise CapabilityError("Google pool telemetry must be an object")
        status_value = report.get("status")
        expected_keys = {"status", "models"}
        if status_value == "unknown":
            expected_keys.add("reason")
        require_exact_keys(report, expected_keys, f"Google pool telemetry {pool}")
        if not isinstance(status_value, str) or status_value not in {
            "available",
            "exhausted",
            "unknown",
        }:
            raise CapabilityError("Google pool telemetry has an invalid status")
        if status_value == "unknown" and not isinstance(report["reason"], str):
            raise CapabilityError("Google pool telemetry needs an unknown reason")
        models = report["models"]
        if (
            not isinstance(models, list)
            or any(not isinstance(model, str) for model in models)
            or len(models) != len(set(models))
            or set(models) != expected_pool_models(registry, "google", pool)
        ):
            raise CapabilityError("Google pool telemetry has the wrong model set")
    return pools


def ingest_google_telemetry(
    path: Path,
    task_id: str,
    expected_revision: int,
    telemetry: Any,
) -> dict[str, Any]:
    require_task_id(task_id)
    path = state_path(path)
    registry, digest = load_registry_context()
    pools = validate_google_telemetry(telemetry, registry)
    with exclusive_state_lock(path):
        state = load_state(path, task_id, registry, digest)
        require_revision(state, expected_revision)
        changed = False
        if pools is not None:
            if any(report["status"] != "unknown" for report in pools.values()):
                changed |= mark_available(state["providers"], "google")
            for pool, report in pools.items():
                if report["status"] == "available":
                    changed |= mark_available(state["pools"]["google"], pool)
                elif report["status"] == "exhausted":
                    changed |= mark_open(state["pools"]["google"], pool)
        save_if_changed(path, state, changed)
    return {
        "changed": changed,
        "taskId": task_id,
        "revision": state["revision"],
        "provider": "google",
    }


def status_report(path: Path, task_id: str) -> dict[str, Any]:
    require_task_id(task_id)
    path = state_path(path)
    registry, digest = load_registry_context()
    state = load_state(path, task_id, registry, digest)
    return {
        "taskId": task_id,
        "revision": state["revision"],
        "namedAgents": state["named_agents"],
        "providers": state["providers"],
        "pools": state["pools"],
        "routes": state["routes"],
        "activeClaims": [
            {
                "candidateOverride": claim["candidate_override"],
                "claimId": claim_id,
                "model": claim["model"],
                "need": claim["need"],
                "planRevision": claim["plan_revision"],
                "plannedCandidates": claim["planned_candidates"],
                "reservedScopes": claim["scopes"],
            }
            for claim_id, claim in sorted(state["claims"].items())
        ],
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--state", type=Path, required=True)
    parser.add_argument("--task-id", required=True)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("init")

    plan = commands.add_parser("plan")
    plan.add_argument("--need", required=True)
    plan.add_argument("--gateway", choices=("on", "off"), default="on")

    claim = commands.add_parser("claim")
    claim.add_argument("--expected-revision", type=int, required=True)
    claim.add_argument("--need", required=True)
    claim.add_argument("--model", required=True)
    claim.add_argument(
        "--override-reason",
        choices=sorted(NON_CANDIDATE_OVERRIDE_REASONS),
    )

    record = commands.add_parser("record")
    record.add_argument("--claim-id", required=True)
    record.add_argument("--outcome", choices=sorted(OUTCOMES), required=True)

    cancel = commands.add_parser("cancel")
    cancel.add_argument("--claim-id", required=True)

    ingest = commands.add_parser("ingest-google")
    ingest.add_argument("--expected-revision", type=int, required=True)
    ingest.add_argument("--input", type=Path, default=Path("-"))

    commands.add_parser("status")
    return parser


def emit(value: Any, stream: Any = sys.stdout) -> None:
    print(
        json.dumps(value, ensure_ascii=True, separators=(",", ":"), sort_keys=True),
        file=stream,
    )


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.command == "init":
            result = initialize(args.state, args.task_id)
        elif args.command == "plan":
            result = plan_route(
                args.state, args.task_id, args.need, args.gateway == "on"
            )
        elif args.command == "claim":
            result = claim_route(
                args.state,
                args.task_id,
                args.expected_revision,
                args.need,
                args.model,
                args.override_reason,
            )
        elif args.command == "record":
            result = record_outcome(
                args.state,
                args.task_id,
                args.claim_id,
                args.outcome,
            )
        elif args.command == "cancel":
            result = cancel_claim(args.state, args.task_id, args.claim_id)
        elif args.command == "ingest-google":
            if args.input == Path("-"):
                raw = read_stream_bytes(
                    sys.stdin.buffer, "Google telemetry", MAX_TELEMETRY_BYTES
                )
            else:
                raw = read_regular_bytes(
                    args.input, "Google telemetry", MAX_TELEMETRY_BYTES
                )
            telemetry = strict_json_loads(raw, "Google telemetry")
            result = ingest_google_telemetry(
                args.state,
                args.task_id,
                args.expected_revision,
                telemetry,
            )
        else:
            result = status_report(args.state, args.task_id)
    except (CapabilityError, OSError, ValueError) as error:
        emit({"error": str(error)}, sys.stderr)
        return 1
    emit(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
