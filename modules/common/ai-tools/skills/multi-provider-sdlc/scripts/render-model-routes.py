#!/usr/bin/env python3
"""Render and verify model-routing tables from canonical policy."""

from __future__ import annotations

import argparse
import json
import re
import sys
import textwrap
from collections.abc import Sequence
from pathlib import Path
from typing import Any

SKILL_ROOT = Path(__file__).resolve().parents[1]
REGISTRY_PATH = SKILL_ROOT / "references" / "model-routing.json"
REFERENCE_PATH = SKILL_ROOT / "references" / "routing.md"
SUBSCRIPTIONS_BEGIN = "<!-- BEGIN GENERATED SUBSCRIPTIONS -->"
SUBSCRIPTIONS_END = "<!-- END GENERATED SUBSCRIPTIONS -->"
ROUTES_BEGIN = "<!-- BEGIN GENERATED ROUTES -->"
ROUTES_END = "<!-- END GENERATED ROUTES -->"
EFFORT_VALUES = {"low", "medium", "high", "xhigh", "max"}
SUBSCRIPTION_IDS = {"openai", "google", "anthropic"}
WRITE_POLICIES = {
    "read-only",
    "read-only unless edit is explicit",
    "build artifacts only",
    "workspace write",
}
CLAUDE_NATIVE_MODELS = {"haiku", "sonnet", "opus", "fable"}
COPILOT_NATIVE_MODELS = {
    "claude-haiku-4.5",
    "claude-sonnet-4.6",
    "claude-opus-4.6",
}
CONTROL_CHARACTER_RE = re.compile(r"[\x00-\x1f\x7f]")


class RoutingError(ValueError):
    """Report invalid policy or generated reference state."""


def require_safe_policy_text(value: Any, context: str = "routing registry") -> None:
    if isinstance(value, str):
        if CONTROL_CHARACTER_RE.search(value):
            raise RoutingError(f"{context} contains control characters")
        return
    if isinstance(value, list):
        for index, item in enumerate(value):
            require_safe_policy_text(item, f"{context}[{index}]")
        return
    if isinstance(value, dict):
        for key, item in value.items():
            require_safe_policy_text(key, f"{context} field name")
            require_safe_policy_text(item, f"{context}.{key}")


def require_table_cell(value: str, context: str) -> None:
    if any(character in value for character in ("|", "\n", "\r", "`", "<", ">")):
        raise RoutingError(f"{context} contains unsupported Markdown table syntax")


def require_exact_keys(value: dict[str, Any], expected: set[str], context: str) -> None:
    if set(value) != expected:
        raise RoutingError(f"{context} has unknown or missing fields")


def validate_native_model(provider: str, model: str, role_id: str) -> None:
    valid = {
        "claude": model in CLAUDE_NATIVE_MODELS,
        "copilot": model in COPILOT_NATIVE_MODELS,
        "opencode": model.startswith("openai/"),
        "codex": model.startswith("gpt-"),
    }[provider]
    if not valid:
        raise RoutingError(f"semantic role {role_id} has cross-provider native model")


def load_registry(path: Path = REGISTRY_PATH) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise RoutingError(f"cannot read routing registry: {error}") from error
    if not isinstance(value, dict):
        raise RoutingError("routing registry must be an object")
    validate_registry(value)
    return value


def validate_registry(registry: dict[str, Any]) -> None:
    require_safe_policy_text(registry)
    require_exact_keys(
        registry,
        {
            "schema_version",
            "subscription_order",
            "subscriptions",
            "models",
            "cliproxy_alias_order",
            "gateway_defaults",
            "semantic_roles",
            "task_routes",
            "deliberation",
            "quota_pools",
        },
        "routing registry",
    )
    if (
        type(registry.get("schema_version")) is not int
        or registry["schema_version"] != 1
    ):
        raise RoutingError("routing registry schema_version must equal 1")

    models = registry.get("models")
    roles = registry.get("semantic_roles")
    routes = registry.get("task_routes")
    if not isinstance(models, dict) or not models:
        raise RoutingError("routing registry models must be a non-empty object")
    if not isinstance(roles, dict) or not roles:
        raise RoutingError("routing registry semantic_roles must be non-empty")
    if not isinstance(routes, list) or not routes:
        raise RoutingError("routing registry task_routes must be non-empty")

    required_model_strings = (
        "subscription",
        "quota_pool",
        "upstream_provider",
        "upstream_model",
        "gateway_alias",
        "display_name",
        "description",
    )
    model_fields = set(required_model_strings) | {
        "reasoning_effort",
        "write",
        "workspace_write",
        "publish_alias",
    }
    expected_upstream_providers = {
        "openai": "codex",
        "google": "antigravity",
        "anthropic": "claude",
    }
    for model_id, model in models.items():
        require_table_cell(model_id, f"model ID {model_id}")
        if not isinstance(model, dict):
            raise RoutingError(f"model entry must be an object: {model_id}")
        require_exact_keys(model, model_fields, f"model {model_id}")
        for field in required_model_strings:
            if not isinstance(model.get(field), str) or not model[field]:
                raise RoutingError(f"model {model_id} needs non-empty {field}")
        if (
            model.get("reasoning_effort") is not None
            and model["reasoning_effort"] not in EFFORT_VALUES
        ):
            raise RoutingError(
                f"model {model_id} reasoning_effort must be supported or null"
            )
        for field in ("write", "workspace_write", "publish_alias"):
            if not isinstance(model.get(field), bool):
                raise RoutingError(f"model {model_id} needs boolean {field}")
        if (
            expected_upstream_providers.get(model["subscription"])
            != model["upstream_provider"]
        ):
            raise RoutingError(f"model has wrong upstream provider: {model_id}")

    aliases = [model["gateway_alias"] for model in models.values()]
    if any(not isinstance(alias, str) or not alias for alias in aliases):
        raise RoutingError("every model needs a gateway_alias")
    if len(aliases) != len(set(aliases)):
        raise RoutingError("gateway_alias values must be unique")
    if not all(alias.startswith(("claude", "anthropic")) for alias in aliases):
        raise RoutingError("gateway_alias values must be visible to Claude")

    model_references: list[str] = []
    expected_native_providers = {"claude", "copilot", "opencode", "codex"}
    expected_gateway_providers = {"claude", "opencode"}
    for role_id, role in roles.items():
        require_table_cell(role_id, f"semantic role ID {role_id}")
        if not isinstance(role, dict):
            raise RoutingError(f"semantic role entry must be an object: {role_id}")
        require_exact_keys(
            role,
            {"native", "gateway", "reasoning_effort"},
            f"semantic role {role_id}",
        )
        native = role.get("native")
        gateway = role.get("gateway", {})
        effort = role.get("reasoning_effort")
        if not isinstance(native, dict) or set(native) != expected_native_providers:
            raise RoutingError(f"semantic role {role_id} needs every native provider")
        if not all(isinstance(model, str) and model for model in native.values()):
            raise RoutingError(f"semantic role {role_id} has an invalid native model")
        for provider, model in native.items():
            validate_native_model(provider, model, role_id)
        if not isinstance(gateway, dict) or set(gateway) != expected_gateway_providers:
            raise RoutingError(f"semantic role {role_id} needs gateway projections")
        if not all(isinstance(model, str) and model for model in gateway.values()):
            raise RoutingError(f"semantic role {role_id} has an invalid gateway model")
        if not isinstance(effort, dict) or set(effort) - {"codex"}:
            raise RoutingError(f"semantic role {role_id} has invalid effort policy")
        if not all(value in EFFORT_VALUES for value in effort.values()):
            raise RoutingError(f"semantic role {role_id} has invalid effort value")
        model_references.extend(gateway.values())

    route_names: list[str] = []
    for route in routes:
        if not isinstance(route, dict):
            raise RoutingError("task route entries must be objects")
        require_exact_keys(
            route,
            {"need", "primary", "fallbacks", "semantic_role", "write_policy"},
            "task route",
        )
        for field in ("need", "primary", "semantic_role", "write_policy"):
            if not isinstance(route.get(field), str) or not route[field]:
                raise RoutingError(f"task route needs non-empty {field}")
            require_table_cell(route[field], f"task route {field}")
        model_references.append(route.get("primary"))
        route_names.append(route["need"])
        fallbacks = route.get("fallbacks")
        if not isinstance(fallbacks, list) or not all(
            isinstance(model, str) and model for model in fallbacks
        ):
            raise RoutingError("task route fallbacks must be arrays")
        if route["write_policy"] not in WRITE_POLICIES:
            raise RoutingError("task route has invalid write policy")
        model_references.extend(fallbacks)
        if route.get("semantic_role") not in roles:
            raise RoutingError("task route references an unknown semantic role")
    if len(route_names) != len(set(route_names)):
        raise RoutingError("task route needs must be unique")

    deliberation = registry.get("deliberation")
    deliberation_keys = {"anthropic", "google", "google_fallback", "openai"}
    if not isinstance(deliberation, dict) or set(deliberation) != deliberation_keys:
        raise RoutingError("routing registry deliberation needs three providers")
    if not all(isinstance(model, str) and model for model in deliberation.values()):
        raise RoutingError("routing registry deliberation models must be text")
    model_references.extend(deliberation.values())
    defaults = registry.get("gateway_defaults")
    if not isinstance(defaults, dict) or set(defaults) != {"claude", "codex", "gemini"}:
        raise RoutingError("gateway_defaults must define claude, codex, and gemini")
    if not all(isinstance(model, str) and model for model in defaults.values()):
        raise RoutingError("gateway_defaults models must be text")
    model_references.extend(defaults.values())
    unknown = sorted({model for model in model_references if model not in models})
    if unknown:
        raise RoutingError(f"unknown model references: {', '.join(unknown)}")

    expected_deliberation_subscriptions = {
        "anthropic": "anthropic",
        "google": "google",
        "google_fallback": "google",
        "openai": "openai",
    }
    for seat, subscription_id in expected_deliberation_subscriptions.items():
        if models[deliberation[seat]]["subscription"] != subscription_id:
            raise RoutingError(f"deliberation seat has wrong provider: {seat}")

    expected_defaults = {
        "claude": ("anthropic", "claude"),
        "codex": ("openai", "codex"),
        "gemini": ("google", "antigravity"),
    }
    for route, (subscription_id, upstream_provider) in expected_defaults.items():
        model = models[defaults[route]]
        if (
            model["subscription"] != subscription_id
            or model["upstream_provider"] != upstream_provider
        ):
            raise RoutingError(f"gateway default has wrong provider: {route}")

    subscriptions = registry.get("subscriptions")
    order = registry.get("subscription_order")
    if (
        not isinstance(subscriptions, dict)
        or not isinstance(order, list)
        or not all(isinstance(item, str) and item for item in order)
    ):
        raise RoutingError("subscription map and order are required")
    if len(order) != len(set(order)) or set(order) != set(subscriptions):
        raise RoutingError("subscription_order must contain every subscription")
    if set(order) != SUBSCRIPTION_IDS:
        raise RoutingError("subscription map contains an unsupported provider")
    listed_models: list[str] = []
    for subscription_id, subscription in subscriptions.items():
        if (
            not isinstance(subscription, dict)
            or not isinstance(subscription.get("label"), str)
            or not subscription["label"]
        ):
            raise RoutingError(f"invalid subscription entry: {subscription_id}")
        require_exact_keys(
            subscription,
            {"label", "model_agents"},
            f"subscription {subscription_id}",
        )
        require_table_cell(subscription["label"], f"subscription {subscription_id}")
        members = subscription.get("model_agents", [])
        if not isinstance(members, list) or not all(
            isinstance(model, str) and model for model in members
        ):
            raise RoutingError("subscription model_agents must be arrays")
        for model_id in members:
            if model_id not in models:
                raise RoutingError(f"subscription references unknown model: {model_id}")
            if models[model_id].get("subscription") != subscription_id:
                raise RoutingError(f"subscription mismatch for model: {model_id}")
        listed_models.extend(members)
    if len(listed_models) != len(set(listed_models)) or set(listed_models) != set(
        models
    ):
        raise RoutingError("subscription model_agents must partition the model catalog")

    alias_order = registry.get("cliproxy_alias_order")
    if (
        not isinstance(alias_order, list)
        or not all(isinstance(model, str) and model for model in alias_order)
        or len(alias_order) != len(set(alias_order))
    ):
        raise RoutingError("cliproxy_alias_order must contain unique model IDs")
    published_models = {
        model_id for model_id, model in models.items() if model["publish_alias"]
    }
    if set(alias_order) != published_models:
        raise RoutingError("cliproxy_alias_order must contain every published model")

    quota_pools = registry.get("quota_pools")
    if not isinstance(quota_pools, dict) or set(quota_pools) != set(subscriptions):
        raise RoutingError("quota_pools must define every subscription")
    for subscription_id, pools in quota_pools.items():
        if (
            not isinstance(pools, list)
            or not all(isinstance(pool, str) and pool for pool in pools)
            or len(pools) != len(set(pools))
        ):
            raise RoutingError(
                f"invalid quota pools for subscription: {subscription_id}"
            )
    for model_id, model in models.items():
        if model["quota_pool"] not in quota_pools[model["subscription"]]:
            raise RoutingError(f"unknown quota pool for model: {model_id}")


def markdown_table(headers: list[str], rows: list[list[str]]) -> str:
    widths = [
        max(len(headers[index]), *(len(row[index]) for row in rows))
        for index in range(len(headers))
    ]

    def render(row: list[str]) -> str:
        cells = [cell.ljust(widths[index]) for index, cell in enumerate(row)]
        return "| " + " | ".join(cells) + " |"

    separator = "| " + " | ".join("-" * width for width in widths) + " |"
    return "\n".join([render(headers), separator, *(render(row) for row in rows)])


def render_subscriptions(registry: dict[str, Any]) -> str:
    rows = []
    for subscription_id in registry["subscription_order"]:
        subscription = registry["subscriptions"][subscription_id]
        agents = ", ".join(f"`{model}`" for model in subscription["model_agents"])
        rows.append([subscription["label"], agents])
    return markdown_table(["Subscription", "Model agents"], rows)


def render_routes(registry: dict[str, Any]) -> str:
    rows = []
    for route in registry["task_routes"]:
        fallbacks = ", ".join(f"`{model}`" for model in route["fallbacks"])
        rows.append(
            [
                route["need"],
                f"`{route['primary']}`",
                fallbacks,
                f"`{route['semantic_role']}`",
                route["write_policy"],
            ]
        )
    table = markdown_table(
        ["Need", "Primary", "Fallback", "Semantic role", "Write policy"], rows
    )
    deliberation = registry["deliberation"]
    sentence = (
        "For explicit three-provider deliberation, use Anthropic "
        f"`{deliberation['anthropic']}`, Google `{deliberation['google']}` with "
        f"`{deliberation['google_fallback']}` fallback, and OpenAI "
        f"`{deliberation['openai']}`."
    )
    return f"{table}\n\n{textwrap.fill(sentence, width=80)}"


def replace_section(text: str, begin: str, end: str, body: str) -> str:
    begin_index = text.find(begin)
    end_index = text.find(end)
    if text.count(begin) != 1 or text.count(end) != 1 or begin_index >= end_index:
        raise RoutingError(f"expected one generated section: {begin}")
    prefix = text[:begin_index]
    suffix = text[end_index + len(end) :]
    return f"{prefix}{begin}\n\n{body}\n\n{end}{suffix}"


def render_reference(registry: dict[str, Any], reference: str) -> str:
    reference = replace_section(
        reference,
        SUBSCRIPTIONS_BEGIN,
        SUBSCRIPTIONS_END,
        render_subscriptions(registry),
    )
    return replace_section(
        reference,
        ROUTES_BEGIN,
        ROUTES_END,
        render_routes(registry),
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("check", "render"))
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        registry = load_registry()
        reference = REFERENCE_PATH.read_text(encoding="utf-8")
        rendered = render_reference(registry, reference)
    except (OSError, RoutingError) as error:
        print(f"model routes: {error}", file=sys.stderr)
        return 2

    if args.command == "render":
        sys.stdout.write(rendered)
        return 0
    if rendered != reference:
        print("model routes: generated reference is stale", file=sys.stderr)
        return 1
    print("model routes: reference matches registry")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
