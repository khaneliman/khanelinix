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
PROVIDERS = ("codex", "claude", "opencode", "copilot", "antigravity")
MAX_REQUEST_BYTES = 256 * 1024
T3_DRIVERS = {"codex": "codex", "claude": "claudeAgent", "antigravity": "antigravity"}


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
            "capabilities": {
                "type": "object",
                "required": ["providers"],
                "properties": {"providers": {"type": "array"}},
            },
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
                "if": {"required": ["capabilities"]},
                "then": {"properties": {"gateway": {"const": False}}},
            },
            {
                "if": {"properties": {"provider": {"const": "copilot"}}},
                "then": {"properties": {"gateway": {"const": False}}},
            },
            {
                "if": {"properties": {"provider": {"const": "antigravity"}}},
                "then": {"required": ["capabilities"]},
            },
        ],
    }


def validate(request: Any, registry: dict[str, Any]) -> None:
    required = {"task_type", "provider", "gateway"}
    if (
        not isinstance(request, dict)
        or not required <= request.keys()
        or request.keys() - required - {"state", "subscription", "capabilities"}
    ):
        raise ValueError("request has unknown or missing fields; use --schema")
    if request["task_type"] not in [route["need"] for route in registry["task_routes"]]:
        raise ValueError("unknown task_type; use --schema")
    if request["provider"] not in PROVIDERS or type(request["gateway"]) is not bool:
        raise ValueError("invalid provider or gateway")
    if "capabilities" in request:
        if request["gateway"]:
            raise ValueError(
                "T3 capabilities select native targets, not gateway agents"
            )
        validate_capabilities(request["capabilities"])
    elif request["provider"] == "antigravity":
        raise ValueError("Antigravity dispatch requires T3 capabilities")
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


def validate_capabilities(value: Any) -> None:
    if not isinstance(value, dict) or not isinstance(value.get("providers"), list):
        raise capability.CapabilityError(
            "capabilities requires the live T3 providers list"
        )
    instances: set[str] = set()
    for provider in value["providers"]:
        if not isinstance(provider, dict):
            raise capability.CapabilityError("T3 provider must be an object")
        for key in ("providerInstanceId", "driverKind"):
            if not isinstance(provider.get(key), str) or not provider[key]:
                raise capability.CapabilityError(f"T3 provider requires {key}")
        if provider["providerInstanceId"] in instances:
            raise capability.CapabilityError("duplicate T3 provider instance")
        instances.add(provider["providerInstanceId"])
        if (
            type(provider.get("canRunChildTask")) is not bool
            or type(provider.get("canRunCrossProviderChildTask")) is not bool
        ):
            raise capability.CapabilityError(
                "T3 provider requires child-task capability flags"
            )
        if not isinstance(provider.get("models"), list):
            raise capability.CapabilityError("T3 provider requires models")
        models: set[str] = set()
        for model in provider["models"]:
            if (
                not isinstance(model, dict)
                or not isinstance(model.get("id"), str)
                or not model["id"]
            ):
                raise capability.CapabilityError("T3 model requires an ID")
            if model["id"] in models:
                raise capability.CapabilityError("duplicate T3 model ID")
            models.add(model["id"])
            options = model.get("options")
            if options is None:
                options = []
            if not isinstance(options, list):
                raise capability.CapabilityError("T3 model options must be a list")
            option_ids: set[str] = set()
            for option in options:
                if (
                    not isinstance(option, dict)
                    or not isinstance(option.get("id"), str)
                    or option["id"] in option_ids
                ):
                    raise capability.CapabilityError(
                        "invalid or duplicate T3 model option"
                    )
                option_ids.add(option["id"])
                if option.get("type") == "select":
                    choices = option.get("options")
                    if not isinstance(choices, list) or any(
                        not isinstance(c, dict) or not isinstance(c.get("id"), str)
                        for c in choices
                    ):
                        raise capability.CapabilityError(
                            "T3 select option requires choice IDs"
                        )


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


def native_model_ids(
    registry: dict[str, Any], provider: str, native_model: str
) -> list[str]:
    source = provider
    if provider == "opencode":
        namespace, _, native_model = native_model.partition("/")
        source = {
            "openai": "codex",
            "anthropic": "claude",
            "google": "antigravity",
        }.get(namespace)
    return [
        model_id
        for model_id, model in registry["models"].items()
        if model["upstream_provider"] == source
        and (
            model["upstream_model"] == native_model
            or (
                source == "claude"
                and model["upstream_model"].startswith(f"claude-{native_model}-")
            )
        )
    ]


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
    if "capabilities" in request:
        return select_t3(request, registry, route, state, result)
    if not request["gateway"]:
        dispatch = semantic_dispatch(registry, route["semantic_role"], provider, False)
        if state_request or "subscription" in request:
            matches = native_model_ids(registry, provider, dispatch["model"])
            if len(matches) != 1:
                return result | {
                    "status": "blocked",
                    "reason": "native profile has no unique quota route",
                }
            model_id = matches[0]
            model = registry["models"][model_id]
            if (
                request.get("subscription", model["subscription"])
                != model["subscription"]
            ):
                return result | {
                    "status": "blocked",
                    "reason": "subscription requires T3 or an explicit gateway route",
                }
            reason = capability.route_block_reason(
                state, model_id, model, include_named_surface=False
            )
            if reason:
                return result | {"status": "blocked", "reason": reason}
            if state_request:
                plan = capability.plan_from_state(
                    state, registry, route["need"], named_agent=False
                )
                result |= claim_arguments(request, plan, model_id, named_agent=False)
        return (
            result
            | {
                "status": "claim_required" if state_request else "ready",
                "selection_basis": "native-profile",
            }
            | dispatch
        )
    plan = capability.plan_from_state(
        state, registry, route["need"], gateway_enabled=True
    )
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
        result |= claim_arguments(request, plan, model_id, named_agent=True)
    return result


def claim_arguments(
    request: dict[str, Any], plan: dict[str, Any], model_id: str, *, named_agent: bool
) -> dict[str, Any]:
    state = request["state"]
    argv = [
        "python3",
        str(CAPABILITY_PATH),
        "--state",
        state["path"],
        "--task-id",
        state["task_id"],
        "claim",
        "--expected-revision",
        str(plan["revision"]),
        "--need",
        plan["need"],
        "--model",
        model_id,
    ]
    if not named_agent:
        argv.append("--native-dispatch")
    if model_id not in [candidate["model"] for candidate in plan["candidates"]]:
        argv += ["--override-reason", "caller-capability-judgment"]
    return {"claim_argv": argv}


def select_t3(
    request: dict[str, Any],
    registry: dict[str, Any],
    route: dict[str, Any],
    state: dict[str, Any],
    result: dict[str, Any],
) -> dict[str, Any]:
    plan = capability.plan_from_state(state, registry, route["need"], named_agent=False)
    for candidate in plan["candidates"]:
        model_id = candidate["model"]
        model = registry["models"][model_id]
        if request.get("subscription", model["subscription"]) != model["subscription"]:
            continue
        # Policy routes stay separate from app instance IDs and live availability.
        targets = []
        for instance in request["capabilities"]["providers"]:
            if (
                instance["driverKind"] != T3_DRIVERS[model["upstream_provider"]]
                or not instance["canRunChildTask"]
            ):
                continue
            if (
                instance["driverKind"] != T3_DRIVERS.get(request["provider"])
                and not instance["canRunCrossProviderChildTask"]
            ):
                continue
            for live_model in instance["models"]:
                if live_model["id"] != model["upstream_model"]:
                    continue
                effort = model["reasoning_effort"]
                profile = registry["semantic_roles"][route["semantic_role"]]
                source = model["upstream_provider"]
                if model_id in native_model_ids(
                    registry, source, profile["native"].get(source, "")
                ):
                    effort = profile["reasoning_effort"].get(source, effort)
                options = {}
                effort_key = (
                    "reasoningEffort" if instance["driverKind"] == "codex" else "effort"
                )
                supported = next(
                    (
                        option
                        for option in live_model.get("options") or []
                        if option["id"] == effort_key and option.get("type") == "select"
                    ),
                    None,
                )
                if effort is not None and supported is not None:
                    if effort not in [choice["id"] for choice in supported["options"]]:
                        continue
                    options[effort_key] = effort
                else:
                    effort = None
                target = {
                    "providerInstanceId": instance["providerInstanceId"],
                    "model": live_model["id"],
                }
                if options:
                    target["options"] = options
                targets.append((target, effort))
        if len(targets) > 1:
            return result | {
                "status": "blocked",
                "reason": "multiple live provider instances match; narrow capabilities to the intended account",
            }
        if not targets:
            continue
        target, effort = targets[0]
        result |= {
            "status": "claim_required" if "state" in request else "ready",
            "selection_basis": "live-native-catalog",
            "model_id": model_id,
            "model": target["model"],
            "subscription": model["subscription"],
            "reasoning_effort": effort,
            "target": target,
        }
        if "state" in request:
            result |= claim_arguments(request, plan, model_id, named_agent=False)
        return result
    return result | {
        "status": "blocked",
        "reason": "no eligible live native target",
        "blocked": plan["blocked"],
    }


def resolve(request: Any) -> dict[str, Any]:
    result = select(request)
    result["next_action"] = {
        "ready": "dispatch",
        "blocked": "do_not_dispatch",
        "claim_required": "run_claim_argv_then_dispatch_only_on_success",
    }[result["status"]]
    if result["status"] == "ready" and "target" in result:
        result["next_action"] = "delegate_task"
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
        outcomes = capability.OUTCOMES
        if not request["gateway"]:
            outcomes = outcomes - {"agent-type-unavailable", "agent-type-available"}
        result["outcomes"] = sorted(outcomes)
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
