"""Classify gh, gh api, and review helper writes."""

from __future__ import annotations

import contextlib
import json
import re
from typing import Any

from .grants import (
    APPROVE,
    DELETE,
    FORCE_PUSH,
    MERGE,
    PUBLISH,
    PUSH,
    RELEASE,
    REQUEST_CHANGES,
    REVIEW_DRAFT,
    Action,
)
from .shell import (
    Context,
    expand,
    has_option,
    option_values,
    positionals,
    read_limited,
    resolve_path,
)

GH_WRITES: dict[tuple[str, str], frozenset[str]] = {
    **{
        ("pr", sub): frozenset({PUBLISH})
        for sub in (
            "create",
            "edit",
            "comment",
            "ready",
            "close",
            "reopen",
            "lock",
            "unlock",
        )
    },
    ("pr", "merge"): frozenset({MERGE}),
    ("pr", "update-branch"): frozenset({PUSH}),
    **{
        ("issue", sub): frozenset({PUBLISH})
        for sub in (
            "create",
            "edit",
            "comment",
            "close",
            "reopen",
            "lock",
            "unlock",
            "pin",
            "unpin",
            "transfer",
            "develop",
        )
    },
    ("issue", "delete"): frozenset({DELETE}),
    **{
        ("release", sub): frozenset({RELEASE})
        for sub in ("create", "edit", "upload", "delete", "delete-asset")
    },
    **{
        ("repo", sub): frozenset({PUBLISH})
        for sub in ("create", "edit", "rename", "archive", "unarchive", "fork")
    },
    ("repo", "delete"): frozenset({DELETE}),
    ("repo", "sync"): frozenset({PUSH}),
    **{("label", sub): frozenset({PUBLISH}) for sub in ("create", "edit", "clone")},
    ("label", "delete"): frozenset({DELETE}),
    **{("gist", sub): frozenset({PUBLISH}) for sub in ("create", "edit", "rename")},
    ("gist", "delete"): frozenset({DELETE}),
    **{(group, "set"): frozenset({PUBLISH}) for group in ("secret", "variable")},
    **{(group, "delete"): frozenset({DELETE}) for group in ("secret", "variable")},
    ("stack", "submit"): frozenset({PUBLISH, PUSH}),
    ("stack", "link"): frozenset({PUBLISH, PUSH}),
    ("stack", "push"): frozenset({PUSH}),
    ("stack", "merge"): frozenset({MERGE}),
}
GH_TEXT_OPTIONS = {
    "title": {"-t", "--title", "--subject"},
    "body": {"-b", "--body", "-c", "--comment", "-n", "--notes"},
    "file": {"-F", "--body-file", "--notes-file"},
}
GH_API_VALUE_OPTIONS = {
    "-X",
    "--method",
    "-H",
    "--header",
    "-f",
    "--raw-field",
    "-F",
    "--field",
    "--input",
    "-q",
    "--jq",
    "-t",
    "--template",
    "--cache",
    "-p",
    "--preview",
    "--hostname",
}
GRAPHQL_MUTATION = re.compile(r"\bmutation\b")
GRAPHQL_FIELD = re.compile(r"\b([a-z][A-Za-z]+)\s*\(\s*input\s*:")
GRAPHQL_BODY = re.compile(r"\b(?:body|title)\s*:\s*\"((?:[^\"\\]|\\.)*)\"")


def text_sources(
    values: list[str], files: list[str], context: Context, action: Action
) -> None:
    for value in values:
        if "$" in value and "$(" not in value:
            expanded = expand(value, context)
            if expanded is None:
                action.unresolved_text = True
                continue
            value = expanded
        if "$(" in value or "`" in value:
            match = re.search(r"\$\(\s*cat\s+['\"]?([^'\")\s]+)", value)
            text = (
                read_limited(resolve_path(match.group(1), context)) if match else None
            )
            if text is None:
                action.public_texts.extend(body for _, body in context.heredocs)
                action.unresolved_text = not context.heredocs
            else:
                action.public_texts.append(text)
        else:
            action.public_texts.append(value)
    for value in files:
        if value == "-":
            action.public_texts.extend(body for _, body in context.heredocs)
            action.unresolved_text = action.unresolved_text or not context.heredocs
            continue
        text = read_limited(resolve_path(value, context))
        if text is None:
            action.unresolved_text = True
        else:
            action.public_texts.append(text)


def json_strings(value: Any, keys: set[str]) -> list[str]:
    if isinstance(value, dict):
        found: list[str] = []
        for key, item in value.items():
            if key in keys and isinstance(item, str):
                found.append(item)
            else:
                found.extend(json_strings(item, keys))
        return found
    if isinstance(value, list):
        return [text for item in value for text in json_strings(item, keys)]
    return []


def load_json_input(source: str, context: Context) -> Any:
    if source == "-":
        texts = [body for _, body in context.heredocs]
    else:
        text = read_limited(resolve_path(source, context))
        texts = [text] if text is not None else []
    for text in texts:
        with contextlib.suppress(json.JSONDecodeError):
            return json.loads(text)
    return None


def classify_gh(args: list[str], context: Context) -> list[Action]:
    if len(args) < 2:
        return []
    group, sub = args[0], args[1]
    if group == "api":
        return classify_gh_api(args[1:], context)
    grants = GH_WRITES.get((group, sub))
    if grants is None:
        return []
    rest = args[2:]
    if sub in {"create", "comment"} and has_option(rest, {"--dry-run", "-w", "--web"}):
        return []
    if (group, sub) in {("pr", "comment"), ("issue", "comment")} and has_option(
        rest, {"--delete-last"}
    ):
        grants = frozenset({DELETE})
    if (group, sub) in {("pr", "close"), ("issue", "close")} and has_option(
        rest, {"-d", "--delete-branch"}
    ):
        grants = grants | {DELETE}
    action = Action(f"gh {group} {sub}", grants, publishes=True)
    text_sources(
        option_values(rest, GH_TEXT_OPTIONS["title"] | GH_TEXT_OPTIONS["body"]),
        option_values(rest, GH_TEXT_OPTIONS["file"]),
        context,
        action,
    )
    return [action]


def classify_gh_review(args: list[str], context: Context) -> list[Action]:
    rest = args[2:]
    if has_option(rest, {"-a", "--approve"}):
        grants = frozenset({APPROVE})
    elif has_option(rest, {"-r", "--request-changes"}):
        grants = frozenset({REQUEST_CHANGES})
    else:
        grants = frozenset({PUBLISH})
    action = Action("gh pr review", grants, publishes=True)
    text_sources(
        option_values(rest, {"-b", "--body"}),
        option_values(rest, {"-F", "--body-file"}),
        context,
        action,
    )
    return [action]


def review_event_grants(text: str) -> frozenset[str] | None:
    if re.search(r"\bAPPROVE\b", text):
        return frozenset({APPROVE})
    if re.search(r"\bREQUEST_CHANGES\b", text):
        return frozenset({REQUEST_CHANGES})
    if re.search(r"\bCOMMENT\b", text):
        return frozenset({PUBLISH})
    return None


def classify_gh_api(options: list[str], context: Context) -> list[Action]:
    found = positionals(options, GH_API_VALUE_OPTIONS)
    if not found:
        return []
    endpoint = found[0].lstrip("/").split("?", 1)[0]
    fields: dict[str, str] = {}
    for raw in option_values(options, {"-f", "--raw-field"}):
        key, _, value = raw.partition("=")
        fields[key] = value
    for raw in option_values(options, {"-F", "--field"}):
        key, _, value = raw.partition("=")
        if value.startswith("@"):
            value = (
                read_limited(resolve_path(value[1:], context))
                if value != "@-"
                else "\n".join(body for _, body in context.heredocs)
            )
            value = value or ""
        fields[key] = value
    inputs = option_values(options, {"--input"})
    loaded = load_json_input(inputs[0], context) if inputs else None
    method_values = option_values(options, {"-X", "--method"})
    method = (
        method_values[-1].upper()
        if method_values
        else ("POST" if fields or inputs else "GET")
    )
    if method in {"GET", "HEAD", "OPTIONS"}:
        return []
    label = f"gh api {method} {endpoint}"
    if endpoint == "graphql":
        query = fields.get("query", "")
        if match := re.search(r"\$\(\s*cat\s+['\"]?([^'\")\s]+)", query):
            query = read_limited(resolve_path(match.group(1), context)) or query
        if isinstance(loaded, dict) and isinstance(loaded.get("query"), str):
            query = loaded["query"]
        unreadable = "{" not in query and "{" not in context.raw
        if "{" not in query:
            query = context.raw
        if not GRAPHQL_MUTATION.search(query):
            if unreadable and "$(" in fields.get("query", ""):
                # An unreadable query file may hold a mutation; hold it like one.
                return [
                    Action(
                        label,
                        frozenset({PUBLISH}),
                        publishes=True,
                        unresolved_text=True,
                    )
                ]
            return []
        action = Action(label, graphql_grants(query, fields, loaded), publishes=True)
        action.public_texts.extend(GRAPHQL_BODY.findall(query))
        action.public_texts.extend(
            value for key, value in fields.items() if key in {"body", "title"}
        )
        if isinstance(loaded, dict):
            action.public_texts.extend(
                json_strings(loaded.get("variables"), {"body", "title"})
            )
        return [action]
    if re.match(r"(?:search/|markdown(?:/raw)?$|notifications)", endpoint) or re.search(
        r"(?:^|/)actions/", endpoint
    ):
        return []
    action = Action(
        label, rest_grants(endpoint, method, fields, loaded), publishes=True
    )
    if not method_values:
        action.label += " (implicit POST; add -X GET for a read)"
    action.public_texts.extend(
        value for key, value in fields.items() if key in {"body", "title"}
    )
    action.public_texts.extend(json_strings(loaded, {"body", "title"}))
    return [action]


def graphql_grants(query: str, fields: dict[str, str], loaded: Any) -> frozenset[str]:
    names = set(GRAPHQL_FIELD.findall(query)) or {"unknown"}
    context_text = " ".join(
        [query, *fields.values(), json.dumps(loaded) if loaded else ""]
    )
    grants: set[str] = set()
    for name in names:
        if name in {
            "mergePullRequest",
            "enablePullRequestAutoMerge",
            "enqueuePullRequest",
        }:
            grants.add(MERGE)
        elif name == "submitPullRequestReview":
            grants |= review_event_grants(context_text) or {PUBLISH}
        elif name == "addPullRequestReview":
            event = re.search(r"\bevent\b", context_text) and review_event_grants(
                context_text
            )
            grants |= event or {REVIEW_DRAFT}
        elif name in {
            "addPullRequestReviewThreadReply",
            "addPullRequestReviewComment",
            "addPullRequestReviewThread",
        }:
            grants.add(
                REVIEW_DRAFT if "pullRequestReviewId" in context_text else PUBLISH
            )
        elif name == "deletePullRequestReview":
            grants.add(REVIEW_DRAFT)
        elif name in {"createRef", "updateRef", "updateRefs"}:
            grants.add(
                FORCE_PUSH if re.search(r"\bforce\s*:\s*true\b", context_text) else PUSH
            )
        elif name.startswith("delete"):
            grants.add(DELETE)
        else:
            grants.add(PUBLISH)
    return frozenset(grants)


def rest_grants(
    endpoint: str, method: str, fields: dict[str, str], loaded: Any
) -> frozenset[str]:
    event = fields.get("event") or (
        loaded.get("event") if isinstance(loaded, dict) else None
    )
    if re.search(r"/pulls/\d+/merge$", endpoint):
        return frozenset({MERGE})
    if re.search(r"/pulls/\d+/reviews(?:/\d+/events)?$", endpoint) and method == "POST":
        return review_event_grants(str(event or "")) or frozenset({REVIEW_DRAFT})
    if re.search(r"/pulls/\d+/reviews/\d+$", endpoint) and method == "DELETE":
        return frozenset({REVIEW_DRAFT})
    if re.search(r"/git/refs(?:/|$)", endpoint):
        if method == "DELETE":
            return frozenset({DELETE})
        force = str(fields.get("force", "")).lower() == "true" or (
            isinstance(loaded, dict) and loaded.get("force") is True
        )
        return frozenset({FORCE_PUSH if force else PUSH})
    if re.search(r"/releases(?:/|$)", endpoint):
        return frozenset({RELEASE})
    if method == "DELETE":
        return frozenset({DELETE})
    return frozenset({PUBLISH})


def classify_helper(script: str, args: list[str], context: Context) -> list[Action]:
    if not args or not has_option(args, {"--apply"}):
        return []
    sub = args[0]
    if script == "review_threads.py":
        if sub == "resolve":
            return [
                Action(
                    "review_threads.py resolve", frozenset({PUBLISH}), publishes=True
                )
            ]
        if sub != "reply":
            return []
        grants = frozenset(
            {PUBLISH if has_option(args, {"--publish"}) else REVIEW_DRAFT}
        )
        action = Action("review_threads.py reply", grants, publishes=True)
        text_sources(
            option_values(args, {"--body"}),
            option_values(args, {"--body-file"}),
            context,
            action,
        )
        return [action]
    if sub not in {"create", "update", "delete"}:
        return []
    inputs = option_values(args, {"--input"})
    loaded = load_json_input(inputs[0], context) if inputs else None
    grants = {REVIEW_DRAFT}
    if isinstance(loaded, dict) and loaded.get("allow_submitted") is True:
        grants = {PUBLISH}
    action = Action(f"review_draft.py {sub}", frozenset(grants), publishes=True)
    action.public_texts.extend(json_strings(loaded, {"body"}))
    action.unresolved_text = bool(inputs) and loaded is None
    return [action]
