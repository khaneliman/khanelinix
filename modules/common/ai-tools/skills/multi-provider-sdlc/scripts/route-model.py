#!/usr/bin/env python3
"""Resolve one structured task to a provider-correct worker, without dispatching."""

from __future__ import annotations

import argparse
import importlib.util
import sys
from pathlib import Path
from typing import Any

CAPABILITY_PATH = Path(__file__).with_name("route-capability.py")
SPEC = importlib.util.spec_from_file_location("route_model_capability", CAPABILITY_PATH)
assert SPEC is not None and SPEC.loader is not None
capability = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(capability)
PROVIDERS = ("codex", "claude", "opencode", "copilot")
MAX_REQUEST_BYTES = 8192


def schema(registry: dict[str, Any]) -> dict[str, Any]:
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "type": "object",
        "additionalProperties": False,
        "required": ["task_type", "provider", "gateway"],
        "properties": {
            "task_type": {"enum": [route["need"] for route in registry["task_routes"]]},
            "provider": {"enum": list(PROVIDERS)},
            "gateway": {"type": "boolean"},
            "subscription": {"enum": registry["subscription_order"]},
            "state": {
                "type": "object",
                "additionalProperties": False,
                "required": ["path", "task_id"],
                "properties": {
                    "path": {"type": "string", "minLength": 1},
                    "task_id": {
                        "type": "string",
                        "pattern": "^[A-Za-z0-9][A-Za-z0-9._-]{0,79}$",
                    },
                },
            },
        },
        "allOf": [
            {
                "if": {"properties": {"gateway": {"const": False}}},
                "then": {
                    "not": {
                        "anyOf": [
                            {"required": ["state"]},
                            {"required": ["subscription"]},
                        ]
                    }
                },
            },
            {
                "if": {"properties": {"provider": {"const": "copilot"}}},
                "then": {"properties": {"gateway": {"const": False}}},
            },
        ],
    }


def validate(request: Any, registry: dict[str, Any]) -> None:
    required = {"task_type", "provider", "gateway"}
    if (
        not isinstance(request, dict)
        or not required <= request.keys()
        or request.keys() - required - {"state", "subscription"}
    ):
        raise ValueError("request has unknown or missing fields; use --schema")
    if request["task_type"] not in [route["need"] for route in registry["task_routes"]]:
        raise ValueError("unknown task_type; use --schema")
    if request["provider"] not in PROVIDERS or type(request["gateway"]) is not bool:
        raise ValueError("invalid provider or gateway")
    if not request["gateway"] and ("state" in request or "subscription" in request):
        raise ValueError("state and subscription apply only to gateway model routes")
    if request["gateway"] and request["provider"] == "copilot":
        raise ValueError("Copilot has no gateway model-agent projection")
    if (
        "subscription" in request
        and request["subscription"] not in registry["subscription_order"]
    ):
        raise ValueError("unknown subscription")
    if "state" in request:
        state = request["state"]
        if not isinstance(state, dict) or set(state) != {"path", "task_id"}:
            raise ValueError("state requires exactly path and task_id")
        if (
            not isinstance(state["path"], str)
            or not state["path"]
            or "\0" in state["path"]
        ):
            raise ValueError("state path must be a nonempty path")
        capability.require_task_id(state["task_id"])


def semantic_dispatch(
    registry: dict[str, Any], role: str, provider: str, gateway: bool
) -> dict[str, Any]:
    profile = registry["semantic_roles"][role]
    model = profile["native"][provider]
    if gateway and provider in profile["gateway"]:
        model = registry["models"][profile["gateway"][provider]]["gateway_alias"]
        if provider == "opencode":
            model = f"cliproxyapi/{model}"
    return {
        "agent_type": role,
        "model": model,
        "reasoning_effort": profile["reasoning_effort"].get(provider),
    }


def select(request: Any) -> dict[str, Any]:
    registry, digest = capability.load_registry_context()
    validate(request, registry)
    route = capability.task_route(registry, request["task_type"])
    provider = request["provider"]
    result = {
        "schema_version": 1,
        "semantic_role": route["semantic_role"],
        "write_policy": route["write_policy"],
        "availability": "unverified",
    }
    if not request["gateway"]:
        return (
            result
            | {"status": "ready", "selection_basis": "native-profile"}
            | semantic_dispatch(registry, route["semantic_role"], provider, False)
        )

    state_request = request.get("state")
    if state_request:
        state = capability.load_state(
            Path(state_request["path"]).expanduser(),
            state_request["task_id"],
            registry,
            digest,
        )
        result["availability"] = "task-state"
    else:
        state = capability.new_state("model-resolution", registry, digest)
    plan = capability.plan_from_state(state, registry, route["need"])
    candidates = [
        item
        for item in plan["candidates"]
        if "subscription" not in request
        or item["subscription"] == request["subscription"]
    ]
    if not candidates:
        if "subscription" not in request and plan["semanticFallback"]:
            return (
                result
                | {"status": "ready", "selection_basis": "semantic-fallback"}
                | semantic_dispatch(registry, route["semantic_role"], provider, True)
            )
        return result | {
            "status": "blocked",
            "reason": plan["semanticFallbackReason"] or "no eligible route",
            "blocked": plan["blocked"],
        }

    model_id = candidates[0]["model"]
    model = registry["models"][model_id]
    result |= {
        "status": "claim_required" if state_request else "ready",
        "selection_basis": "canonical-order",
        "agent_type": model_id,
        "model_id": model_id,
        "model": ("cliproxyapi/" if provider == "opencode" else "")
        + model["gateway_alias"],
        "subscription": model["subscription"],
        "reasoning_effort": model["reasoning_effort"]
        if provider == "codex" or (provider == "claude" and model_id == "gpt-6-astra")
        else None,
    }
    if state_request:
        result["claim_argv"] = [
            "python3",
            str(CAPABILITY_PATH),
            "--state",
            state_request["path"],
            "--task-id",
            state_request["task_id"],
            "claim",
            "--expected-revision",
            str(plan["revision"]),
            "--need",
            route["need"],
            "--model",
            model_id,
        ]
    return result


def resolve(request: Any) -> dict[str, Any]:
    result = select(request)
    result["next_action"] = {
        "ready": "dispatch",
        "blocked": "do_not_dispatch",
        "claim_required": "run_claim_argv_then_dispatch_only_on_success",
    }[result["status"]]
    if result["status"] == "claim_required":
        state = request["state"]
        result["record_argv"] = [
            "python3",
            str(CAPABILITY_PATH),
            "--state",
            state["path"],
            "--task-id",
            state["task_id"],
            "record",
            "--claim-id",
            "<claimId>",
            "--outcome",
            "<outcome>",
        ]
        result["outcomes"] = sorted(capability.OUTCOMES)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--schema", action="store_true", help="print the JSON input contract"
    )
    args = parser.parse_args()
    try:
        if args.schema:
            result = schema(capability.load_registry_context()[0])
        else:
            raw = capability.read_stream_bytes(
                sys.stdin.buffer, "model request", MAX_REQUEST_BYTES
            )
            result = resolve(capability.strict_json_loads(raw, "model request"))
    except (ValueError, OSError) as error:
        capability.emit({"error": str(error)}, sys.stderr)
        return 2
    capability.emit(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
