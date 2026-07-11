#!/usr/bin/env python3
"""Search repository issues with deterministic counts and bounded output."""

from __future__ import annotations

import argparse
import re
from collections import Counter
from typing import Any

from _github import (
    GhClient,
    InputError,
    ToolkitError,
    emit_json,
    fail,
    resolve_repository,
)

DEFAULT_QUERY = "is:issue is:open -linked:pr"
SEARCH_RESULT_CAP = 1000
REPO_QUALIFIER = re.compile(r"(?:^|\s)repo:", re.IGNORECASE)
PULL_REQUEST_QUALIFIER = re.compile(
    r"(?:^|\s)-?is:(?:pr|pull-request)(?=\s|$)", re.IGNORECASE
)
ISSUE_QUALIFIER = re.compile(r"(?:^|\s)is:issue(?=\s|$)", re.IGNORECASE)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Search GitHub issues and emit total count, sampled labels, comment-ranked "
            "candidates, and truncation metadata."
        )
    )
    parser.add_argument(
        "--repo",
        help="OWNER/REPO or checkout path (defaults to current checkout).",
    )
    parser.add_argument("--query", default=DEFAULT_QUERY, help="Issue search query.")
    parser.add_argument(
        "--limit",
        type=int,
        default=100,
        help="Maximum search results to inspect (1-1000).",
    )
    parser.add_argument(
        "--top",
        type=int,
        default=25,
        help="Maximum normalized issue candidates to emit.",
    )
    parser.add_argument(
        "--sort",
        choices=("comments", "created", "updated", "best-match"),
        default="comments",
    )
    parser.add_argument("--order", choices=("asc", "desc"), default="desc")
    return parser.parse_args()


def validate_args(args: argparse.Namespace) -> None:
    if not 1 <= args.limit <= SEARCH_RESULT_CAP:
        raise InputError(f"--limit must be between 1 and {SEARCH_RESULT_CAP}")
    if args.top < 0:
        raise InputError("--top must be zero or greater")
    if not args.query.strip():
        raise InputError("--query must not be empty")
    if REPO_QUALIFIER.search(args.query):
        raise InputError("put repository scope in --repo, not a repo: query qualifier")
    if PULL_REQUEST_QUALIFIER.search(args.query):
        raise InputError("issue scan does not accept pull-request type qualifiers")


def normalize_issue_query(query: str) -> str:
    value = query.strip()
    if PULL_REQUEST_QUALIFIER.search(value):
        raise InputError("issue scan does not accept pull-request type qualifiers")
    return value if ISSUE_QUALIFIER.search(value) else f"is:issue {value}"


def fetch_issues(
    client: GhClient,
    repository: str,
    query: str,
    limit: int,
    sort: str,
    order: str,
) -> tuple[int, bool, list[dict[str, Any]]]:
    scoped_query = f"repo:{repository} {normalize_issue_query(query)}"
    results: list[dict[str, Any]] = []
    total_count = 0
    incomplete = False
    page = 1

    while len(results) < limit:
        per_page = min(100, limit - len(results))
        command = [
            "api",
            "--method",
            "GET",
            "/search/issues",
            "-H",
            "Accept: application/vnd.github+json",
            "-H",
            "X-GitHub-Api-Version: 2022-11-28",
            "-f",
            f"q={scoped_query}",
            "-F",
            f"per_page={per_page}",
            "-F",
            f"page={page}",
        ]
        if sort != "best-match":
            command.extend(["-f", f"sort={sort}", "-f", f"order={order}"])
        payload = client.run_json(command)
        if not isinstance(payload, dict):
            raise ToolkitError("GitHub issue search returned an unexpected JSON shape")
        count = payload.get("total_count")
        items = payload.get("items")
        if not isinstance(count, int) or not isinstance(items, list):
            raise ToolkitError("GitHub issue search omitted total_count or items")
        total_count = count
        incomplete = incomplete or bool(payload.get("incomplete_results"))
        page_items = [item for item in items if isinstance(item, dict)]
        results.extend(page_items)
        searchable = min(total_count, SEARCH_RESULT_CAP)
        if not page_items or len(results) >= searchable:
            break
        page += 1

    return total_count, incomplete, results[:limit]


def normalize_issue(item: dict[str, Any], rank: int) -> dict[str, Any]:
    raw_labels = item.get("labels")
    labels = []
    if isinstance(raw_labels, list):
        labels = sorted(
            label["name"]
            for label in raw_labels
            if isinstance(label, dict) and isinstance(label.get("name"), str)
        )
    return {
        "comments": item.get("comments", 0),
        "created_at": item.get("created_at"),
        "labels": labels,
        "number": item.get("number"),
        "rank": rank,
        "state": item.get("state"),
        "title": item.get("title"),
        "updated_at": item.get("updated_at"),
        "url": item.get("html_url"),
    }


def summarize(
    repository: str,
    query: str,
    limit: int,
    top: int,
    sort: str,
    order: str,
    total_count: int,
    incomplete: bool,
    items: list[dict[str, Any]],
) -> dict[str, Any]:
    label_counts: Counter[str] = Counter()
    for item in items:
        labels = item.get("labels")
        if not isinstance(labels, list):
            continue
        label_counts.update(
            label["name"]
            for label in labels
            if isinstance(label, dict) and isinstance(label.get("name"), str)
        )

    reasons = []
    if total_count > SEARCH_RESULT_CAP:
        reasons.append("github_search_cap")
    if limit < min(total_count, SEARCH_RESULT_CAP):
        reasons.append("requested_limit")
    if incomplete:
        reasons.append("incomplete_results")
    if len(items) < min(limit, total_count, SEARCH_RESULT_CAP) and not incomplete:
        reasons.append("api_returned_fewer_items")

    emitted = items[: min(top, len(items))]
    return {
        "counts": {
            "emitted": len(emitted),
            "fetched": len(items),
            "total": total_count,
        },
        "incomplete_results": incomplete,
        "issues": [
            normalize_issue(item, rank) for rank, item in enumerate(emitted, start=1)
        ],
        "labels": [
            {"count": count, "name": name}
            for name, count in sorted(
                label_counts.items(), key=lambda pair: (-pair[1], pair[0].lower())
            )
        ],
        "query": query,
        "repository": repository,
        "sample_limit": limit,
        "search_cap": SEARCH_RESULT_CAP,
        "sort": {"field": sort, "order": order if sort != "best-match" else None},
        "truncated": bool(reasons),
        "truncation_reasons": reasons,
    }


def run(args: argparse.Namespace, client: GhClient) -> dict[str, Any]:
    validate_args(args)
    repository = resolve_repository(client, args.repo)
    query = normalize_issue_query(args.query)
    total_count, incomplete, items = fetch_issues(
        client,
        repository,
        query,
        args.limit,
        args.sort,
        args.order,
    )
    return summarize(
        repository,
        query,
        args.limit,
        args.top,
        args.sort,
        args.order,
        total_count,
        incomplete,
        items,
    )


def main() -> int:
    try:
        emit_json(run(parse_args(), GhClient()))
    except ToolkitError as error:
        return fail(error)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
