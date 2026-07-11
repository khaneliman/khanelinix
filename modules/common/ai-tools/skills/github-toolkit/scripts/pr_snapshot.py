#!/usr/bin/env python3
"""Emit a bounded, normalized snapshot of a GitHub pull request."""

from __future__ import annotations

import argparse
from typing import Any

from _github import (
    GhClient,
    InputError,
    Target,
    ToolkitError,
    current_actor,
    emit_json,
    fail,
    resolve_target,
)

FIELDS = ",".join(
    (
        "author",
        "baseRefName",
        "baseRefOid",
        "headRefName",
        "headRefOid",
        "headRepository",
        "headRepositoryOwner",
        "isCrossRepository",
        "isDraft",
        "mergeable",
        "mergeStateStatus",
        "number",
        "reviewDecision",
        "state",
        "statusCheckRollup",
        "title",
        "updatedAt",
        "url",
    )
)

FILES_HARD_CAP = 3000
COMMITS_HARD_CAP = 250
DEFAULT_MAX_FILES = 200
DEFAULT_MAX_COMMITS = 100
PAGE_SIZE = 100


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Emit canonical PR metadata, commits, files, and checks as JSON."
    )
    parser.add_argument(
        "--repo",
        help="Base OWNER/REPO or checkout path (defaults to current checkout).",
    )
    parser.add_argument(
        "--pr",
        help="Pull request number or URL (defaults to current branch pull request).",
    )
    parser.add_argument(
        "--max-files",
        type=int,
        default=DEFAULT_MAX_FILES,
        help="Maximum files to emit; 0 fetches through GitHub's API hard cap.",
    )
    parser.add_argument(
        "--max-commits",
        type=int,
        default=DEFAULT_MAX_COMMITS,
        help="Maximum commits to emit; 0 fetches through GitHub's API hard cap.",
    )
    return parser.parse_args()


def _author(value: Any) -> dict[str, Any] | None:
    if not isinstance(value, dict):
        return None
    return {
        "login": value.get("login"),
        "name": value.get("name"),
    }


def _commits(value: Any) -> list[dict[str, Any]]:
    if not isinstance(value, list):
        return []
    normalized = []
    for commit in value:
        if not isinstance(commit, dict):
            continue
        rest_commit = commit.get("commit")
        if isinstance(rest_commit, dict):
            git_author = rest_commit.get("author")
            git_committer = rest_commit.get("committer")
            github_author = commit.get("author")
            message = rest_commit.get("message")
            author = {
                "login": github_author.get("login")
                if isinstance(github_author, dict)
                else None,
                "name": git_author.get("name")
                if isinstance(git_author, dict)
                else None,
            }
            normalized.append(
                {
                    "authored_at": git_author.get("date")
                    if isinstance(git_author, dict)
                    else None,
                    "authors": [author]
                    if author["login"] is not None or author["name"] is not None
                    else [],
                    "committed_at": git_committer.get("date")
                    if isinstance(git_committer, dict)
                    else None,
                    "headline": message.splitlines()[0]
                    if isinstance(message, str) and message
                    else None,
                    "sha": commit.get("sha"),
                }
            )
            continue
        authors = commit.get("authors")
        normalized.append(
            {
                "authored_at": commit.get("authoredDate"),
                "authors": [
                    _author(author) for author in authors if isinstance(author, dict)
                ]
                if isinstance(authors, list)
                else [],
                "committed_at": commit.get("committedDate"),
                "headline": commit.get("messageHeadline"),
                "sha": commit.get("oid"),
            }
        )
    return normalized


def _files(value: Any) -> list[dict[str, Any]]:
    if not isinstance(value, list):
        return []
    normalized = []
    for file in value:
        if not isinstance(file, dict):
            continue
        normalized.append(
            {
                "additions": file.get("additions"),
                "deletions": file.get("deletions"),
                "path": file.get("path") or file.get("filename"),
            }
        )
    return normalized


def _checks(value: Any) -> list[dict[str, Any]]:
    if not isinstance(value, list):
        return []
    normalized = []
    for check in value:
        if not isinstance(check, dict):
            continue
        normalized.append(
            {
                "completed_at": check.get("completedAt"),
                "conclusion": check.get("conclusion"),
                "details_url": check.get("detailsUrl"),
                "name": check.get("name") or check.get("context"),
                "started_at": check.get("startedAt"),
                "status": check.get("status") or check.get("state"),
                "workflow": check.get("workflowName"),
            }
        )
    return normalized


def normalize_snapshot(
    payload: dict[str, Any],
    repository: str,
    viewer: str,
    files_value: list[dict[str, Any]],
    commits_value: list[dict[str, Any]],
    completeness: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    head_repository = payload.get("headRepository")
    head_owner = payload.get("headRepositoryOwner")
    head_name = None
    if isinstance(head_repository, dict):
        head_name = head_repository.get("nameWithOwner") or head_repository.get("name")
    owner_login = head_owner.get("login") if isinstance(head_owner, dict) else None
    if head_name and "/" not in str(head_name) and owner_login:
        head_name = f"{owner_login}/{head_name}"

    files = _files(files_value)
    checks = _checks(payload.get("statusCheckRollup"))
    commits = _commits(commits_value)
    return {
        "actor": viewer,
        "base": {
            "branch": payload.get("baseRefName"),
            "repository": repository,
            "sha": payload.get("baseRefOid"),
        },
        "checks": checks,
        "commits": commits,
        "completeness": completeness,
        "counts": {
            "checks": len(checks),
            "commits": len(commits),
            "files": len(files),
        },
        "files": files,
        "head": {
            "branch": payload.get("headRefName"),
            "repository": head_name,
            "sha": payload.get("headRefOid"),
        },
        "is_cross_repository": bool(payload.get("isCrossRepository")),
        "is_draft": bool(payload.get("isDraft")),
        "merge_state": payload.get("mergeStateStatus"),
        "mergeable": payload.get("mergeable"),
        "number": payload.get("number"),
        "review_decision": payload.get("reviewDecision"),
        "state": payload.get("state"),
        "title": payload.get("title"),
        "updated_at": payload.get("updatedAt"),
        "url": payload.get("url"),
        "author": _author(payload.get("author")),
    }


def fetch_collection_totals(client: GhClient, target: Target) -> dict[str, int]:
    payload = client.run_json(
        [
            "api",
            "--method",
            "GET",
            f"repos/{target.repository}/pulls/{target.pull_request}",
            "-H",
            "Accept: application/vnd.github+json",
            "-H",
            "X-GitHub-Api-Version: 2022-11-28",
        ]
    )
    if not isinstance(payload, dict):
        raise ToolkitError("GitHub pull request response was not an object")
    commits = payload.get("commits")
    files = payload.get("changed_files")
    for name, value in {"commits": commits, "files": files}.items():
        if isinstance(value, bool) or not isinstance(value, int) or value < 0:
            raise ToolkitError(f"GitHub pull request response omitted {name} total")
    assert isinstance(commits, int)
    assert isinstance(files, int)
    return {"commits": commits, "files": files}


def fetch_collection(
    client: GhClient,
    target: Target,
    endpoint: str,
    total: int,
    hard_cap: int,
    requested_limit: int,
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    available = min(total, hard_cap)
    wanted = available if requested_limit == 0 else min(available, requested_limit)
    items: list[dict[str, Any]] = []
    page = 1
    while len(items) < wanted:
        payload = client.run_json(
            [
                "api",
                "--method",
                "GET",
                f"repos/{target.repository}/pulls/{target.pull_request}/{endpoint}"
                f"?per_page={PAGE_SIZE}&page={page}",
                "-H",
                "Accept: application/vnd.github+json",
                "-H",
                "X-GitHub-Api-Version: 2022-11-28",
            ]
        )
        if not isinstance(payload, list):
            raise ToolkitError(
                f"GitHub pull request {endpoint} response was not an array"
            )
        if any(not isinstance(item, dict) for item in payload):
            raise ToolkitError(
                f"GitHub pull request {endpoint} response contained an invalid item"
            )
        items.extend(payload)
        if not payload:
            break
        page += 1

    items = items[:wanted]
    reasons = []
    if total > hard_cap:
        reasons.append("github_api_hard_cap")
    if requested_limit > 0 and requested_limit < available:
        reasons.append("requested_limit")
    if len(items) < wanted:
        reasons.append("api_returned_fewer_items")
    complete = total <= hard_cap and len(items) == total
    return items, {
        "complete": complete,
        "fetched": len(items),
        "hard_cap": hard_cap,
        "requested_limit": requested_limit,
        "total": total,
        "truncated": not complete,
        "truncation_reasons": reasons,
    }


def run(args: argparse.Namespace, client: GhClient) -> dict[str, Any]:
    if args.max_files < 0 or args.max_commits < 0:
        raise InputError("--max-files and --max-commits must be zero or greater")
    target = resolve_target(client, args.repo, args.pr)
    payload = client.run_json(
        [
            "pr",
            "view",
            str(target.pull_request),
            "--repo",
            target.repository,
            "--json",
            FIELDS,
        ]
    )
    if not isinstance(payload, dict):
        raise ToolkitError("gh pr view returned an unexpected JSON shape")
    totals = fetch_collection_totals(client, target)
    files, files_completeness = fetch_collection(
        client,
        target,
        "files",
        totals["files"],
        FILES_HARD_CAP,
        args.max_files,
    )
    commits, commits_completeness = fetch_collection(
        client,
        target,
        "commits",
        totals["commits"],
        COMMITS_HARD_CAP,
        args.max_commits,
    )
    return normalize_snapshot(
        payload,
        target.repository,
        current_actor(client),
        files,
        commits,
        {"commits": commits_completeness, "files": files_completeness},
    )


def main() -> int:
    try:
        emit_json(run(parse_args(), GhClient()))
    except ToolkitError as error:
        return fail(error)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
