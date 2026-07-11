#!/usr/bin/env python3
"""Inspect and safely mutate pull request review threads.

Derived in part from GitHub's gh-address-comments skill. See
../LICENSE-gh-address-comments.txt.
"""

from __future__ import annotations

import argparse
import fnmatch
from typing import Any

from _github import (
    GhClient,
    InputError,
    Target,
    ToolkitError,
    emit_json,
    fail,
    pull_request_oids,
    read_text_input,
    resolve_target,
)

THREADS_QUERY = """
query($owner: String!, $repo: String!, $number: Int!, $cursor: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      number
      url
      headRefOid
      reviewThreads(first: 50, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          diffSide
          startLine
          startDiffSide
          originalLine
          originalStartLine
          resolvedBy { login }
          comments(first: 100) {
            totalCount
            pageInfo { hasNextPage endCursor }
            nodes {
              id
              databaseId
              body
              createdAt
              updatedAt
              url
              author { login }
            }
          }
        }
      }
    }
  }
}
"""


MORE_COMMENTS_QUERY = """
query($threadId: ID!, $cursor: String) {
  node(id: $threadId) {
    ... on PullRequestReviewThread {
      comments(first: 100, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          databaseId
          body
          createdAt
          updatedAt
          url
          author { login }
        }
      }
    }
  }
}
"""


REPLY_MUTATION = """
mutation($threadId: ID!, $body: String!) {
  addPullRequestReviewThreadReply(
    input: {pullRequestReviewThreadId: $threadId, body: $body}
  ) {
    comment { id databaseId body createdAt updatedAt url author { login } }
  }
}
"""


RESOLVE_MUTATION = """
mutation($threadId: ID!) {
  resolveReviewThread(input: {threadId: $threadId}) {
    thread { id isResolved resolvedBy { login } }
  }
}
"""


def add_target_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--repo",
        help="Base OWNER/REPO or checkout path (defaults to current checkout).",
    )
    parser.add_argument(
        "--pr",
        help="Pull request number or URL (defaults to current branch pull request).",
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Inspect, reply to, or resolve pull request review threads."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    inspect = subparsers.add_parser("inspect", help="Inspect filtered review threads.")
    add_target_arguments(inspect)
    inspect.add_argument(
        "--state",
        choices=("unresolved", "resolved", "all"),
        default="unresolved",
    )
    inspect.add_argument(
        "--outdated",
        choices=("exclude", "include", "only"),
        default="exclude",
    )
    inspect.add_argument(
        "--path",
        action="append",
        default=[],
        help="Keep matching path or shell-style path pattern; repeatable.",
    )
    inspect.add_argument(
        "--author",
        action="append",
        default=[],
        help="Keep threads containing a comment by this login; repeatable.",
    )
    inspect.add_argument(
        "--include-bodies",
        action="store_true",
        help="Emit full comment bodies instead of bounded previews.",
    )
    inspect.add_argument(
        "--max-body-chars",
        type=int,
        default=240,
        help="Maximum body preview characters when bodies are filtered.",
    )

    reply = subparsers.add_parser("reply", help="Plan or apply a thread reply.")
    add_target_arguments(reply)
    reply.add_argument("--thread", required=True, help="Review thread node ID.")
    reply.add_argument(
        "--expected-head-sha",
        required=True,
        help="Exact PR head SHA required before planning or applying reply.",
    )
    body = reply.add_mutually_exclusive_group(required=True)
    body.add_argument("--body", help="Reply body.")
    body.add_argument("--body-file", help="Reply body file, or - for stdin.")
    reply.add_argument("--apply", action="store_true", help="Apply planned reply.")

    resolve = subparsers.add_parser("resolve", help="Plan or apply thread resolution.")
    add_target_arguments(resolve)
    resolve.add_argument("--thread", required=True, help="Review thread node ID.")
    resolve.add_argument(
        "--expected-head-sha",
        required=True,
        help="Exact PR head SHA required before planning or applying resolution.",
    )
    resolve.add_argument(
        "--apply", action="store_true", help="Apply planned resolution."
    )
    return parser.parse_args()


def _graphql_pr(payload: dict[str, Any]) -> dict[str, Any]:
    try:
        pull_request = payload["data"]["repository"]["pullRequest"]
    except (KeyError, TypeError) as error:
        raise ToolkitError("GitHub response omitted pull request data") from error
    if not isinstance(pull_request, dict):
        raise ToolkitError("pull request was not found in base repository")
    return pull_request


def _fetch_more_comments(
    client: GhClient, thread_id: str, cursor: str
) -> list[dict[str, Any]]:
    comments: list[dict[str, Any]] = []
    next_cursor: str | None = cursor
    while next_cursor is not None:
        payload = client.graphql(
            MORE_COMMENTS_QUERY,
            {"threadId": thread_id, "cursor": next_cursor},
        )
        try:
            connection = payload["data"]["node"]["comments"]
        except (KeyError, TypeError) as error:
            raise ToolkitError(
                "GitHub response omitted review thread comments"
            ) from error
        comments.extend(
            node for node in connection.get("nodes", []) if isinstance(node, dict)
        )
        page = connection.get("pageInfo", {})
        next_cursor = page.get("endCursor") if page.get("hasNextPage") else None
    return comments


def fetch_threads(
    client: GhClient, target: Target
) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    cursor: str | None = None
    metadata: dict[str, Any] | None = None
    threads: list[dict[str, Any]] = []
    while True:
        payload = client.graphql(
            THREADS_QUERY,
            {
                "owner": target.owner,
                "repo": target.name,
                "number": target.pull_request,
                "cursor": cursor,
            },
        )
        pull_request = _graphql_pr(payload)
        if metadata is None:
            metadata = {
                "head_sha": pull_request.get("headRefOid"),
                "number": pull_request.get("number"),
                "repository": target.repository,
                "url": pull_request.get("url"),
            }
        connection = pull_request.get("reviewThreads")
        if not isinstance(connection, dict):
            raise ToolkitError("GitHub response omitted reviewThreads")
        for raw_thread in connection.get("nodes", []):
            if not isinstance(raw_thread, dict):
                continue
            thread = dict(raw_thread)
            comments = thread.get("comments")
            if not isinstance(comments, dict):
                raise ToolkitError("GitHub response omitted thread comments")
            nodes = [
                node for node in comments.get("nodes", []) if isinstance(node, dict)
            ]
            page = comments.get("pageInfo", {})
            if page.get("hasNextPage"):
                end_cursor = page.get("endCursor")
                if not isinstance(end_cursor, str):
                    raise ToolkitError("thread comment pagination omitted endCursor")
                nodes.extend(_fetch_more_comments(client, thread["id"], end_cursor))
            thread["comments"] = nodes
            threads.append(thread)
        page = connection.get("pageInfo", {})
        if not page.get("hasNextPage"):
            break
        cursor = page.get("endCursor")
        if not isinstance(cursor, str):
            raise ToolkitError("review thread pagination omitted endCursor")
    assert metadata is not None
    return metadata, threads


def body_value(body: Any, include_bodies: bool, max_chars: int) -> dict[str, Any]:
    text = body if isinstance(body, str) else ""
    if include_bodies:
        return {"body": text, "body_length": len(text), "body_truncated": False}
    preview = text[:max_chars]
    return {
        "body_length": len(text),
        "body_preview": preview,
        "body_truncated": len(text) > len(preview),
    }


def normalize_thread(
    thread: dict[str, Any], include_bodies: bool, max_chars: int
) -> dict[str, Any]:
    comments = []
    for comment in thread.get("comments", []):
        if not isinstance(comment, dict):
            continue
        author = comment.get("author")
        comments.append(
            {
                "author": author.get("login") if isinstance(author, dict) else None,
                "created_at": comment.get("createdAt"),
                "database_id": comment.get("databaseId"),
                "id": comment.get("id"),
                "updated_at": comment.get("updatedAt"),
                "url": comment.get("url"),
                **body_value(comment.get("body"), include_bodies, max_chars),
            }
        )
    resolver = thread.get("resolvedBy")
    return {
        "comments": comments,
        "id": thread.get("id"),
        "is_outdated": bool(thread.get("isOutdated")),
        "is_resolved": bool(thread.get("isResolved")),
        "location": {
            "line": thread.get("line"),
            "original_line": thread.get("originalLine"),
            "original_start_line": thread.get("originalStartLine"),
            "path": thread.get("path"),
            "side": thread.get("diffSide"),
            "start_line": thread.get("startLine"),
            "start_side": thread.get("startDiffSide"),
        },
        "resolved_by": resolver.get("login") if isinstance(resolver, dict) else None,
    }


def filter_threads(
    threads: list[dict[str, Any]], args: argparse.Namespace
) -> list[dict[str, Any]]:
    selected = []
    wanted_authors = {author.lower() for author in args.author}
    for thread in threads:
        resolved = bool(thread.get("isResolved"))
        if args.state == "unresolved" and resolved:
            continue
        if args.state == "resolved" and not resolved:
            continue
        outdated = bool(thread.get("isOutdated"))
        if args.outdated == "exclude" and outdated:
            continue
        if args.outdated == "only" and not outdated:
            continue
        path = str(thread.get("path") or "")
        if args.path and not any(fnmatch.fnmatchcase(path, item) for item in args.path):
            continue
        if wanted_authors:
            authors = {
                str(comment.get("author", {}).get("login", "")).lower()
                for comment in thread.get("comments", [])
                if isinstance(comment, dict) and isinstance(comment.get("author"), dict)
            }
            if authors.isdisjoint(wanted_authors):
                continue
        selected.append(thread)
    return selected


def find_thread(threads: list[dict[str, Any]], thread_id: str) -> dict[str, Any]:
    matches = [thread for thread in threads if thread.get("id") == thread_id]
    if len(matches) != 1:
        raise InputError("--thread does not identify one thread in target pull request")
    return matches[0]


def verify_expected_head_sha(pull_request: dict[str, Any], expected: str) -> None:
    current = pull_request.get("head_sha")
    if (
        not expected.strip()
        or not isinstance(current, str)
        or expected.lower() != current.lower()
    ):
        raise InputError(
            f"expected head SHA does not match current PR head: {expected} != {current}"
        )


def verify_current_head_sha(client: GhClient, target: Target, expected: str) -> None:
    current = pull_request_oids(client, target)["head_sha"]
    if not expected.strip() or expected.lower() != current.lower():
        raise InputError(
            "expected head SHA does not match current PR head immediately before "
            f"mutation: {expected} != {current}"
        )


def inspect(args: argparse.Namespace, client: GhClient) -> dict[str, Any]:
    if args.max_body_chars < 0:
        raise InputError("--max-body-chars must be zero or greater")
    target = resolve_target(client, args.repo, args.pr)
    pull_request, threads = fetch_threads(client, target)
    selected = filter_threads(threads, args)
    return {
        "counts": {"matched": len(selected), "total": len(threads)},
        "filters": {
            "authors": args.author,
            "include_bodies": args.include_bodies,
            "outdated": args.outdated,
            "paths": args.path,
            "state": args.state,
        },
        "pull_request": pull_request,
        "threads": [
            normalize_thread(thread, args.include_bodies, args.max_body_chars)
            for thread in selected
        ],
    }


def verification(status: str, error: Exception | str | None = None) -> dict[str, Any]:
    result: dict[str, Any] = {"status": status}
    if error is not None:
        detail = str(error)
        result.update(
            {
                "detail": detail[:1000],
                "detail_chars_total": len(detail),
                "detail_truncated": len(detail) > 1000,
            }
        )
    return result


def reply(args: argparse.Namespace, client: GhClient) -> dict[str, Any]:
    target = resolve_target(client, args.repo, args.pr)
    pull_request, threads = fetch_threads(client, target)
    verify_expected_head_sha(pull_request, args.expected_head_sha)
    thread = find_thread(threads, args.thread)
    body = read_text_input(args.body, args.body_file)
    plan = {
        "action": "reply",
        "applied": False,
        "body": body,
        "pull_request": pull_request,
        "thread": normalize_thread(thread, False, 240),
    }
    if not args.apply:
        return plan
    latest_pull_request, latest_threads = fetch_threads(client, target)
    verify_expected_head_sha(latest_pull_request, args.expected_head_sha)
    thread = find_thread(latest_threads, args.thread)
    plan["thread"] = normalize_thread(thread, False, 240)
    verify_current_head_sha(client, target, args.expected_head_sha)
    payload = client.graphql(REPLY_MUTATION, {"threadId": args.thread, "body": body})
    try:
        created = payload["data"]["addPullRequestReviewThreadReply"]["comment"]
    except (KeyError, TypeError) as error:
        raise ToolkitError("reply mutation omitted created comment") from error
    if not isinstance(created, dict) or not isinstance(created.get("id"), str):
        raise ToolkitError("reply mutation returned an invalid comment")
    plan["applied"] = True
    plan["created_comment"] = created
    plan["verification"] = verification("unverified")
    try:
        _, refreshed = fetch_threads(client, target)
        refreshed_thread = find_thread(refreshed, args.thread)
        if not any(
            comment.get("id") == created["id"]
            for comment in refreshed_thread.get("comments", [])
            if isinstance(comment, dict)
        ):
            raise ToolkitError("reply readback did not contain created comment")
    except Exception as error:
        plan["verification"] = verification("unverified", error)
        return plan
    plan["verification"] = verification("verified")
    plan["thread"] = normalize_thread(refreshed_thread, False, 240)
    return plan


def resolve(args: argparse.Namespace, client: GhClient) -> dict[str, Any]:
    target = resolve_target(client, args.repo, args.pr)
    pull_request, threads = fetch_threads(client, target)
    verify_expected_head_sha(pull_request, args.expected_head_sha)
    thread = find_thread(threads, args.thread)
    if thread.get("isResolved"):
        raise InputError("review thread is already resolved")
    plan = {
        "action": "resolve",
        "applied": False,
        "pull_request": pull_request,
        "thread": normalize_thread(thread, False, 240),
    }
    if not args.apply:
        return plan
    latest_pull_request, latest_threads = fetch_threads(client, target)
    verify_expected_head_sha(latest_pull_request, args.expected_head_sha)
    thread = find_thread(latest_threads, args.thread)
    if thread.get("isResolved"):
        raise InputError("review thread became resolved before mutation")
    plan["thread"] = normalize_thread(thread, False, 240)
    verify_current_head_sha(client, target, args.expected_head_sha)
    payload = client.graphql(RESOLVE_MUTATION, {"threadId": args.thread})
    try:
        resolved = payload["data"]["resolveReviewThread"]["thread"]
    except (KeyError, TypeError) as error:
        raise ToolkitError("resolve mutation omitted review thread") from error
    if not isinstance(resolved, dict) or not resolved.get("isResolved"):
        raise ToolkitError("resolve mutation did not report resolved state")
    plan["applied"] = True
    plan["verification"] = verification("unverified")
    try:
        _, refreshed = fetch_threads(client, target)
        refreshed_thread = find_thread(refreshed, args.thread)
        if not refreshed_thread.get("isResolved"):
            raise ToolkitError("resolve readback still reports unresolved state")
    except Exception as error:
        plan["verification"] = verification("unverified", error)
        return plan
    plan["verification"] = verification("verified")
    plan["thread"] = normalize_thread(refreshed_thread, False, 240)
    return plan


def run(args: argparse.Namespace, client: GhClient) -> dict[str, Any]:
    if args.command == "inspect":
        return inspect(args, client)
    if args.command == "reply":
        return reply(args, client)
    if args.command == "resolve":
        return resolve(args, client)
    raise InputError(f"unsupported command: {args.command}")


def main() -> int:
    try:
        emit_json(run(parse_args(), GhClient()))
    except ToolkitError as error:
        return fail(error)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
