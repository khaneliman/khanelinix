#!/usr/bin/env python3
"""Inspect, create, or edit an owned pending pull request review."""

from __future__ import annotations

import argparse
import re
from typing import Any

from _github import (
    GhClient,
    InputError,
    Target,
    ToolkitError,
    current_actor,
    emit_json,
    fail,
    pull_request_oids,
    read_json_input,
    resolve_target,
)

MARKER = "<!-- ai-tools:review-pr -->"
HUNK_HEADER = re.compile(r"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@")


REVIEWS_QUERY = """
query($owner: String!, $repo: String!, $number: Int!, $cursor: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      number
      url
      baseRefOid
      headRefOid
      reviews(first: 100, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          databaseId: fullDatabaseId
          state
          body
          submittedAt
          updatedAt
          author { login }
          comments(first: 100) {
            pageInfo { hasNextPage endCursor }
            nodes {
              id
              databaseId: fullDatabaseId
              path
              startLine
              line
              body
              createdAt
              updatedAt
              url
            }
          }
        }
      }
    }
  }
}
"""


MORE_REVIEW_COMMENTS_QUERY = """
query($reviewId: ID!, $cursor: String) {
  node(id: $reviewId) {
    ... on PullRequestReview {
      comments(first: 100, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          databaseId: fullDatabaseId
          path
          startLine
          line
          body
          createdAt
          updatedAt
          url
        }
      }
    }
  }
}
"""


REVIEW_THREAD_SIDES_QUERY = """
query($owner: String!, $repo: String!, $number: Int!, $cursor: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          diffSide
          startDiffSide
          comments(last: 100) { nodes { id } }
        }
      }
    }
  }
}
"""


UPDATE_REVIEW_MUTATION = """
mutation($id: ID!, $body: String!) {
  updatePullRequestReview(input: {pullRequestReviewId: $id, body: $body}) {
    pullRequestReview { id state body updatedAt author { login } }
  }
}
"""


UPDATE_COMMENT_MUTATION = """
mutation($id: ID!, $body: String!) {
  updatePullRequestReviewComment(
    input: {pullRequestReviewCommentId: $id, body: $body}
  ) {
    pullRequestReviewComment { id path startLine line body updatedAt }
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
        description="Inspect, plan, or apply an owned pending pull request review."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    inspect = subparsers.add_parser(
        "inspect", help="Inspect pending or marked reviews."
    )
    add_target_arguments(inspect)
    inspect.add_argument(
        "--all-reviews", action="store_true", help="Include unmarked submitted reviews."
    )
    inspect.add_argument(
        "--include-bodies",
        action="store_true",
        help="Emit full review and comment bodies instead of previews.",
    )
    inspect.add_argument("--max-body-chars", type=int, default=240)

    for command in ("create", "update"):
        child = subparsers.add_parser(
            command, help=f"Plan or apply pending review {command}."
        )
        add_target_arguments(child)
        child.add_argument("--input", required=True, help="JSON file, or - for stdin.")
        child.add_argument(
            "--apply", action="store_true", help="Apply validated pending review write."
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


def _fetch_more_review_comments(
    client: GhClient, review_id: str, cursor: str
) -> list[dict[str, Any]]:
    comments: list[dict[str, Any]] = []
    next_cursor: str | None = cursor
    while next_cursor is not None:
        payload = client.graphql(
            MORE_REVIEW_COMMENTS_QUERY,
            {"reviewId": review_id, "cursor": next_cursor},
        )
        try:
            connection = payload["data"]["node"]["comments"]
        except (KeyError, TypeError) as error:
            raise ToolkitError("GitHub response omitted review comments") from error
        comments.extend(
            node for node in connection.get("nodes", []) if isinstance(node, dict)
        )
        page = connection.get("pageInfo", {})
        next_cursor = page.get("endCursor") if page.get("hasNextPage") else None
    return comments


def fetch_review_context(
    client: GhClient, target: Target
) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    cursor: str | None = None
    metadata: dict[str, Any] | None = None
    reviews: list[dict[str, Any]] = []
    while True:
        payload = client.graphql(
            REVIEWS_QUERY,
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
                "base_sha": pull_request.get("baseRefOid"),
                "head_sha": pull_request.get("headRefOid"),
                "number": pull_request.get("number"),
                "repository": target.repository,
                "url": pull_request.get("url"),
            }
        connection = pull_request.get("reviews")
        if not isinstance(connection, dict):
            raise ToolkitError("GitHub response omitted reviews")
        for raw_review in connection.get("nodes", []):
            if not isinstance(raw_review, dict):
                continue
            review = dict(raw_review)
            comments = review.get("comments")
            if not isinstance(comments, dict):
                raise ToolkitError("GitHub response omitted review comments")
            nodes = [
                node for node in comments.get("nodes", []) if isinstance(node, dict)
            ]
            page = comments.get("pageInfo", {})
            if page.get("hasNextPage"):
                end_cursor = page.get("endCursor")
                if not isinstance(end_cursor, str):
                    raise ToolkitError("review comment pagination omitted endCursor")
                nodes.extend(
                    _fetch_more_review_comments(client, review["id"], end_cursor)
                )
            review["comments"] = nodes
            reviews.append(review)
        page = connection.get("pageInfo", {})
        if not page.get("hasNextPage"):
            break
        cursor = page.get("endCursor")
        if not isinstance(cursor, str):
            raise ToolkitError("review pagination omitted endCursor")
    assert metadata is not None
    return metadata, reviews


def fetch_diff_files(client: GhClient, target: Target) -> dict[str, dict[str, Any]]:
    files: dict[str, dict[str, Any]] = {}
    page = 1
    while True:
        payload = client.run_json(
            [
                "api",
                "--method",
                "GET",
                f"repos/{target.repository}/pulls/{target.pull_request}/files"
                f"?per_page=100&page={page}",
                "-H",
                "Accept: application/vnd.github+json",
                "-H",
                "X-GitHub-Api-Version: 2022-11-28",
            ]
        )
        if not isinstance(payload, list):
            raise ToolkitError("GitHub pull request files response was not an array")
        for item in payload:
            if not isinstance(item, dict) or not isinstance(item.get("filename"), str):
                continue
            files[item["filename"]] = item
        if len(payload) < 100:
            break
        page += 1
        if page > 30:
            raise ToolkitError("pull request exceeds GitHub's 3000-file review limit")
    return files


def fetch_review_comments_with_sides(
    client: GhClient, target: Target, review: dict[str, Any]
) -> list[dict[str, Any]]:
    review_id = review.get("databaseId")
    if review_id is None:
        raise ToolkitError("review readback omitted database ID")
    graphql_comments = {
        comment.get("id"): comment
        for comment in review.get("comments", [])
        if isinstance(comment, dict) and isinstance(comment.get("id"), str)
    }
    try:
        thread_sides = fetch_review_thread_sides(client, target)
    except ToolkitError:
        # Pending review threads are not exposed consistently across GitHub
        # versions. REST path/body/position and GraphQL review lines still
        # provide useful readback without turning a successful write into an
        # error solely because side metadata is unavailable.
        thread_sides = {}
    comments: list[dict[str, Any]] = []
    page = 1
    while True:
        payload = client.run_json(
            [
                "api",
                "--method",
                "GET",
                f"repos/{target.repository}/pulls/{target.pull_request}/reviews/"
                f"{review_id}/comments?per_page=100&page={page}",
                "-H",
                "Accept: application/vnd.github+json",
                "-H",
                "X-GitHub-Api-Version: 2022-11-28",
            ]
        )
        if not isinstance(payload, list):
            raise ToolkitError("review comment readback was not an array")
        for comment in payload:
            if not isinstance(comment, dict):
                raise ToolkitError("review comment readback contained an invalid item")
            node_id = comment.get("node_id")
            graphql_comment = graphql_comments.get(node_id, {})
            sides = thread_sides.get(node_id, {})
            comments.append(
                {
                    "body": comment.get("body"),
                    "createdAt": comment.get("created_at"),
                    "databaseId": comment.get("id"),
                    "diffSide": comment.get("side") or sides.get("diffSide"),
                    "id": node_id,
                    "line": comment.get("line") or graphql_comment.get("line"),
                    "path": comment.get("path"),
                    "position": comment.get("position"),
                    "startDiffSide": comment.get("start_side")
                    or sides.get("startDiffSide"),
                    "startLine": comment.get("start_line")
                    or graphql_comment.get("startLine"),
                    "updatedAt": comment.get("updated_at"),
                    "url": comment.get("html_url"),
                }
            )
        if len(payload) < 100:
            break
        page += 1
    return comments


def fetch_review_thread_sides(
    client: GhClient, target: Target
) -> dict[str, dict[str, Any]]:
    cursor: str | None = None
    sides: dict[str, dict[str, Any]] = {}
    while True:
        payload = client.graphql(
            REVIEW_THREAD_SIDES_QUERY,
            {
                "cursor": cursor,
                "number": target.pull_request,
                "owner": target.owner,
                "repo": target.name,
            },
        )
        try:
            connection = payload["data"]["repository"]["pullRequest"]["reviewThreads"]
        except (KeyError, TypeError) as error:
            raise ToolkitError("review thread side readback was unavailable") from error
        if not isinstance(connection, dict):
            raise ToolkitError("review thread side readback was unavailable")
        for thread in connection.get("nodes", []):
            if not isinstance(thread, dict):
                continue
            comments = thread.get("comments")
            if not isinstance(comments, dict):
                continue
            for comment in comments.get("nodes", []):
                if isinstance(comment, dict) and isinstance(comment.get("id"), str):
                    sides[comment["id"]] = {
                        "diffSide": thread.get("diffSide"),
                        "startDiffSide": thread.get("startDiffSide"),
                    }
        page = connection.get("pageInfo", {})
        if not page.get("hasNextPage"):
            break
        cursor = page.get("endCursor")
        if not isinstance(cursor, str):
            raise ToolkitError("review thread side pagination omitted endCursor")
    return sides


def parse_patch_lines(patch: str) -> dict[str, set[int]]:
    valid = {"LEFT": set(), "RIGHT": set()}
    old_line = 0
    new_line = 0
    inside_hunk = False
    for text in patch.splitlines():
        match = HUNK_HEADER.match(text)
        if match:
            old_line = int(match.group(1))
            new_line = int(match.group(3))
            inside_hunk = True
            continue
        if not inside_hunk or not text:
            continue
        prefix = text[0]
        if prefix == " ":
            valid["LEFT"].add(old_line)
            valid["RIGHT"].add(new_line)
            old_line += 1
            new_line += 1
        elif prefix == "-":
            valid["LEFT"].add(old_line)
            old_line += 1
        elif prefix == "+":
            valid["RIGHT"].add(new_line)
            new_line += 1
        elif prefix != "\\":
            inside_hunk = False
    return valid


def _integer(value: Any, field: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
        raise InputError(f"{field} must be a positive integer")
    return value


def _string(value: Any, field: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise InputError(f"{field} must be a non-empty string")
    return value


def _only_keys(value: dict[str, Any], allowed: set[str], context: str) -> None:
    unknown = sorted(set(value) - allowed)
    if "event" in unknown:
        raise InputError(
            "review event is never accepted; this helper cannot submit reviews"
        )
    if unknown:
        raise InputError(f"unsupported {context} fields: {', '.join(unknown)}")


def validate_marker(body: str) -> None:
    if body.count(MARKER) != 1:
        raise InputError(f"review body must contain marker exactly once: {MARKER}")


def validate_expected_sha(value: Any, pull_request: dict[str, Any]) -> str:
    expected = _string(value, "expected_head_sha")
    current = pull_request.get("head_sha")
    if not isinstance(current, str) or expected.lower() != current.lower():
        raise InputError(
            f"expected_head_sha does not match current PR head: {expected} != {current}"
        )
    return expected


def normalize_create_comment(value: Any, index: int) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise InputError(f"comments[{index}] must be an object")
    _only_keys(
        value,
        {"body", "line", "path", "side", "start_line", "start_side"},
        f"comments[{index}]",
    )
    path = _string(value.get("path"), f"comments[{index}].path")
    body = _string(value.get("body"), f"comments[{index}].body")
    line = _integer(value.get("line"), f"comments[{index}].line")
    side = _string(value.get("side"), f"comments[{index}].side").upper()
    if side not in {"LEFT", "RIGHT"}:
        raise InputError(f"comments[{index}].side must be LEFT or RIGHT")
    comment = {"body": body, "line": line, "path": path, "side": side}
    start_line = value.get("start_line")
    start_side = value.get("start_side")
    if start_line is None and start_side is not None:
        raise InputError(f"comments[{index}].start_side requires start_line")
    if start_line is not None:
        normalized_start = _integer(start_line, f"comments[{index}].start_line")
        if normalized_start >= line:
            raise InputError(f"comments[{index}].start_line must be less than line")
        normalized_side = (
            _string(start_side, f"comments[{index}].start_side").upper()
            if start_side is not None
            else side
        )
        if normalized_side != side:
            raise InputError(f"comments[{index}] range must stay on one diff side")
        comment["start_line"] = normalized_start
        comment["start_side"] = normalized_side
    return comment


def verify_anchor(
    comment: dict[str, Any], files: dict[str, dict[str, Any]], context: str
) -> None:
    path = comment.get("path")
    if path not in files:
        raise InputError(f"{context}.path is not present in current PR diff: {path}")
    patch = files[path].get("patch")
    if not isinstance(patch, str):
        raise InputError(
            f"{context} anchor cannot be verified because patch is unavailable"
        )
    valid = parse_patch_lines(patch)
    side = comment.get("side")
    line = comment.get("line")
    start_line = comment.get("start_line")
    if side is None:
        candidates = [name for name, lines in valid.items() if line in lines]
        if not candidates:
            raise InputError(f"{context}.line is not present in current PR diff")
        sides = candidates
    else:
        sides = [str(side).upper()]
        if sides[0] not in valid:
            raise InputError(f"{context}.side must be LEFT or RIGHT")
    first = start_line if isinstance(start_line, int) else line
    if not isinstance(first, int) or not isinstance(line, int):
        raise InputError(f"{context} must include numeric line information")
    if not any(
        all(number in valid[name] for number in range(first, line + 1))
        for name in sides
    ):
        raise InputError(f"{context} range is not contiguous on current PR diff")


def review_author(review: dict[str, Any]) -> str | None:
    author = review.get("author")
    return author.get("login") if isinstance(author, dict) else None


def marker_reviews(reviews: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [review for review in reviews if MARKER in str(review.get("body") or "")]


def body_fields(body: Any, include: bool, max_chars: int) -> dict[str, Any]:
    text = body if isinstance(body, str) else ""
    if include:
        return {"body": text, "body_length": len(text), "body_truncated": False}
    preview = text[:max_chars]
    return {
        "body_length": len(text),
        "body_preview": preview,
        "body_truncated": len(text) > len(preview),
    }


def normalize_review(
    review: dict[str, Any], include_bodies: bool, max_chars: int
) -> dict[str, Any]:
    comments = []
    for comment in review.get("comments", []):
        if not isinstance(comment, dict):
            continue
        comments.append(
            {
                "created_at": comment.get("createdAt"),
                "database_id": comment.get("databaseId"),
                "id": comment.get("id"),
                "line": comment.get("line"),
                "path": comment.get("path"),
                "position": comment.get("position"),
                "side": comment.get("diffSide") or comment.get("side"),
                "start_line": comment.get("startLine"),
                "start_side": comment.get("startDiffSide") or comment.get("start_side"),
                "updated_at": comment.get("updatedAt"),
                "url": comment.get("url"),
                **body_fields(comment.get("body"), include_bodies, max_chars),
            }
        )
    return {
        "author": review_author(review),
        "comments": comments,
        "database_id": review.get("databaseId"),
        "id": review.get("id"),
        "marker_count": str(review.get("body") or "").count(MARKER),
        "state": review.get("state"),
        "submitted_at": review.get("submittedAt"),
        "updated_at": review.get("updatedAt"),
        **body_fields(review.get("body"), include_bodies, max_chars),
    }


def inspect(args: argparse.Namespace, client: GhClient) -> dict[str, Any]:
    if args.max_body_chars < 0:
        raise InputError("--max-body-chars must be zero or greater")
    target = resolve_target(client, args.repo, args.pr)
    pull_request, reviews = fetch_review_context(client, target)
    actor = current_actor(client)
    selected = (
        reviews
        if args.all_reviews
        else [
            review
            for review in reviews
            if review.get("state") == "PENDING"
            or MARKER in str(review.get("body") or "")
        ]
    )
    return {
        "actor": actor,
        "counts": {
            "marked": len(marker_reviews(reviews)),
            "selected": len(selected),
            "total": len(reviews),
        },
        "pull_request": pull_request,
        "reviews": [
            normalize_review(review, args.include_bodies, args.max_body_chars)
            for review in selected
        ],
    }


def _comment_anchor_value(comment: dict[str, Any], field: str) -> Any:
    aliases = {
        "side": "diffSide",
        "start_line": "startLine",
        "start_side": "startDiffSide",
    }
    value = comment.get(field)
    if value is not None:
        return value
    return comment.get(aliases.get(field, field))


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


def _readback_matches_request(
    actual: dict[str, Any], requested: dict[str, Any]
) -> bool:
    if actual.get("path") != requested.get("path"):
        return False
    if actual.get("body") != requested.get("body"):
        return False
    for field in ("line", "side", "start_line", "start_side"):
        actual_value = _comment_anchor_value(actual, field)
        requested_value = _comment_anchor_value(requested, field)
        if actual_value != requested_value:
            return False
    return True


def verify_current_oids(
    client: GhClient,
    target: Target,
    expected_head_sha: str,
    expected_base_sha: str | None = None,
) -> None:
    current = pull_request_oids(client, target)
    if current["head_sha"].lower() != expected_head_sha.lower():
        raise InputError(
            "expected_head_sha does not match current PR head immediately before "
            f"write: {expected_head_sha} != {current['head_sha']}"
        )
    if (
        expected_base_sha is not None
        and current["base_sha"].lower() != expected_base_sha.lower()
    ):
        raise InputError(
            "PR base changed while validating current diff anchors: "
            f"{expected_base_sha} != {current['base_sha']}"
        )


def verify_created_review(
    review: dict[str, Any], actor: str, body: str, comments: list[dict[str, Any]]
) -> None:
    if review.get("state") != "PENDING":
        raise ToolkitError("review readback is not pending")
    if review_author(review) != actor:
        raise ToolkitError("review readback is not owned by current actor")
    if review.get("body") != body:
        raise ToolkitError("review body readback does not match requested body")
    actual = [
        comment for comment in review.get("comments", []) if isinstance(comment, dict)
    ]
    if len(actual) != len(comments):
        raise ToolkitError("review comment anchor/body readback does not match request")
    remaining = list(comments)
    actual.sort(
        key=lambda comment: sum(
            _comment_anchor_value(comment, field) is not None
            for field in ("line", "side", "start_line", "start_side")
        ),
        reverse=True,
    )
    for comment in actual:
        match = next(
            (
                index
                for index, requested in enumerate(remaining)
                if _readback_matches_request(comment, requested)
            ),
            None,
        )
        if match is None:
            raise ToolkitError(
                "review comment anchor/body readback does not match request"
            )
        remaining.pop(match)


def ensure_create_available(reviews: list[dict[str, Any]], actor: str) -> None:
    if marker_reviews(reviews):
        raise InputError("target pull request already contains a marked AI review")
    actor_pending = [
        review
        for review in reviews
        if review.get("state") == "PENDING" and review_author(review) == actor
    ]
    if actor_pending:
        raise InputError("current actor already owns a pending review; use update")


def create(args: argparse.Namespace, client: GhClient) -> dict[str, Any]:
    data = read_json_input(args.input)
    _only_keys(data, {"body", "comments", "expected_head_sha"}, "input")
    target = resolve_target(client, args.repo, args.pr)
    pull_request, reviews = fetch_review_context(client, target)
    actor = current_actor(client)
    expected_sha = validate_expected_sha(data.get("expected_head_sha"), pull_request)
    body = _string(data.get("body"), "body")
    validate_marker(body)
    raw_comments = data.get("comments")
    if not isinstance(raw_comments, list) or not raw_comments:
        raise InputError("comments must be a non-empty array")
    comments = [
        normalize_create_comment(comment, index)
        for index, comment in enumerate(raw_comments)
    ]
    ensure_create_available(reviews, actor)
    files = fetch_diff_files(client, target)
    for index, comment in enumerate(comments):
        verify_anchor(comment, files, f"comments[{index}]")
    payload = {"body": body, "commit_id": expected_sha, "comments": comments}
    plan: dict[str, Any] = {
        "action": "create",
        "actor": actor,
        "applied": False,
        "payload": payload,
        "pull_request": pull_request,
    }
    if not args.apply:
        return plan
    latest_pull_request, latest_reviews = fetch_review_context(client, target)
    latest_actor = current_actor(client)
    if latest_actor != actor:
        raise InputError("current GitHub actor changed before review creation")
    validate_expected_sha(data.get("expected_head_sha"), latest_pull_request)
    ensure_create_available(latest_reviews, latest_actor)
    latest_files = fetch_diff_files(client, target)
    for index, comment in enumerate(comments):
        verify_anchor(comment, latest_files, f"comments[{index}]")
    latest_base_sha = latest_pull_request.get("base_sha")
    if not isinstance(latest_base_sha, str):
        raise ToolkitError("GitHub response omitted current PR base SHA")
    verify_current_oids(client, target, expected_sha, latest_base_sha)
    response = client.run_json(
        [
            "api",
            "--method",
            "POST",
            f"repos/{target.repository}/pulls/{target.pull_request}/reviews",
            "-H",
            "Accept: application/vnd.github+json",
            "-H",
            "X-GitHub-Api-Version: 2022-11-28",
            "--input",
            "-",
        ],
        input_value=payload,
    )
    plan["applied"] = True
    plan["verification"] = verification("unverified")
    if not isinstance(response, dict):
        plan["verification"] = verification(
            "unverified", "review creation returned an unexpected JSON shape"
        )
        return plan
    node_id = response.get("node_id")
    plan["review_node_id"] = node_id
    try:
        _, refreshed = fetch_review_context(client, target)
        candidates = [
            review
            for review in refreshed
            if (node_id and review.get("id") == node_id)
            or (
                not node_id
                and review.get("state") == "PENDING"
                and review_author(review) == actor
                and review.get("body") == body
            )
        ]
        if len(candidates) != 1:
            raise ToolkitError(
                "review creation readback did not identify one pending review"
            )
        created_review = dict(candidates[0])
        created_review["comments"] = fetch_review_comments_with_sides(
            client, target, created_review
        )
        verify_created_review(created_review, actor, body, comments)
    except Exception as error:
        plan["verification"] = verification("unverified", error)
        return plan
    plan["verification"] = verification("verified")
    plan["review"] = normalize_review(created_review, True, 0)
    return plan


def select_pending_review(
    reviews: list[dict[str, Any]], actor: str, requested_id: Any
) -> dict[str, Any]:
    if requested_id is not None:
        value = str(requested_id)
        matches = [
            review
            for review in reviews
            if str(review.get("id")) == value or str(review.get("databaseId")) == value
        ]
    else:
        matches = [
            review
            for review in reviews
            if review.get("state") == "PENDING" and review_author(review) == actor
        ]
    if len(matches) != 1:
        raise InputError("review_id does not identify one current-actor pending review")
    review = matches[0]
    if review.get("state") != "PENDING":
        raise InputError("target review is not pending")
    if review_author(review) != actor:
        raise InputError("target pending review is not owned by current actor")
    return review


def select_comment(
    request: dict[str, Any], comments: list[dict[str, Any]], index: int
) -> dict[str, Any]:
    identifier = request.get("id")
    database_id = request.get("database_id")
    if identifier is not None or database_id is not None:
        matches = [
            comment
            for comment in comments
            if (identifier is not None and str(comment.get("id")) == str(identifier))
            or (
                database_id is not None
                and str(comment.get("databaseId")) == str(database_id)
            )
        ]
    else:
        path = request.get("path")
        line = request.get("line")
        start_line = request.get("start_line")
        if not isinstance(path, str) or not isinstance(line, int):
            raise InputError(
                f"comments[{index}] needs id, database_id, or path plus line"
            )
        matches = [
            comment
            for comment in comments
            if comment.get("path") == path
            and comment.get("line") == line
            and comment.get("startLine") == start_line
        ]
    if len(matches) != 1:
        raise InputError(f"comments[{index}] does not identify one draft comment")
    selected = matches[0]
    comparisons = {
        "path": selected.get("path"),
        "line": selected.get("line"),
        "start_line": selected.get("startLine"),
    }
    for field, actual in comparisons.items():
        if field in request and request[field] != actual:
            raise InputError(f"comments[{index}].{field} does not match draft anchor")
    return selected


def normalize_update_operations(
    data: dict[str, Any], review: dict[str, Any], files: dict[str, dict[str, Any]]
) -> list[dict[str, Any]]:
    raw_comments = data.get("comments", [])
    if not isinstance(raw_comments, list):
        raise InputError("comments must be an array")
    operations = []
    for index, request in enumerate(raw_comments):
        if not isinstance(request, dict):
            raise InputError(f"comments[{index}] must be an object")
        _only_keys(
            request,
            {
                "body",
                "database_id",
                "id",
                "line",
                "path",
                "side",
                "start_line",
            },
            f"comments[{index}]",
        )
        body = _string(request.get("body"), f"comments[{index}].body")
        selected = select_comment(request, review.get("comments", []), index)
        anchor = {
            "line": selected.get("line"),
            "path": selected.get("path"),
            "start_line": selected.get("startLine"),
        }
        if "side" in request:
            side = _string(request["side"], f"comments[{index}].side").upper()
            if side not in {"LEFT", "RIGHT"}:
                raise InputError(f"comments[{index}].side must be LEFT or RIGHT")
            anchor["side"] = side
        verify_anchor(anchor, files, f"comments[{index}]")
        if selected.get("body") != body:
            operations.append(
                {
                    "body": body,
                    "database_id": selected.get("databaseId"),
                    "id": selected.get("id"),
                    "line": selected.get("line"),
                    "path": selected.get("path"),
                    "start_line": selected.get("startLine"),
                    "type": "comment_body",
                }
            )
    return operations


def update(args: argparse.Namespace, client: GhClient) -> dict[str, Any]:
    data = read_json_input(args.input)
    _only_keys(
        data,
        {"body", "comments", "expected_head_sha", "review_id"},
        "input",
    )
    if "body" not in data and "comments" not in data:
        raise InputError("update input must include body or comments")
    target = resolve_target(client, args.repo, args.pr)
    pull_request, reviews = fetch_review_context(client, target)
    actor = current_actor(client)
    validate_expected_sha(data.get("expected_head_sha"), pull_request)
    review = select_pending_review(reviews, actor, data.get("review_id"))
    body = (
        _string(data["body"], "body")
        if "body" in data
        else str(review.get("body") or "")
    )
    validate_marker(body)
    duplicates = [item for item in marker_reviews(reviews) if item is not review]
    if duplicates:
        raise InputError("another review already contains the AI review marker")
    files = fetch_diff_files(client, target) if data.get("comments") else {}
    operations = normalize_update_operations(data, review, files)
    if body != review.get("body"):
        operations.insert(
            0, {"body": body, "id": review.get("id"), "type": "review_body"}
        )
    if not operations:
        raise InputError("update contains no changes")
    plan: dict[str, Any] = {
        "action": "update",
        "actor": actor,
        "applied": False,
        "operations": operations,
        "pull_request": pull_request,
        "review": normalize_review(review, True, 0),
    }
    if not args.apply:
        return plan
    latest_pull_request, latest_reviews = fetch_review_context(client, target)
    latest_actor = current_actor(client)
    if latest_actor != actor:
        raise InputError("current GitHub actor changed before review update")
    validate_expected_sha(data.get("expected_head_sha"), latest_pull_request)
    latest_review = select_pending_review(
        latest_reviews, latest_actor, review.get("id")
    )
    latest_body = (
        _string(data["body"], "body")
        if "body" in data
        else str(latest_review.get("body") or "")
    )
    validate_marker(latest_body)
    latest_duplicates = [
        item for item in marker_reviews(latest_reviews) if item is not latest_review
    ]
    if latest_duplicates:
        raise InputError("another review already contains the AI review marker")
    latest_files = fetch_diff_files(client, target) if data.get("comments") else {}
    operations = normalize_update_operations(data, latest_review, latest_files)
    if latest_body != latest_review.get("body"):
        operations.insert(
            0,
            {"body": latest_body, "id": latest_review.get("id"), "type": "review_body"},
        )
    if not operations:
        raise InputError("update contains no changes after pre-write refresh")
    body = latest_body
    review = latest_review
    plan["operations"] = operations
    plan["review"] = normalize_review(latest_review, True, 0)
    latest_base_sha = latest_pull_request.get("base_sha")
    if data.get("comments") and not isinstance(latest_base_sha, str):
        raise ToolkitError("GitHub response omitted current PR base SHA")
    applied_operations: list[dict[str, Any]] = []
    plan["mutation"] = {
        "applied_operations": applied_operations,
        "complete": False,
        "requested_operations": len(operations),
    }
    for operation in operations:
        try:
            verify_current_oids(
                client,
                target,
                str(data["expected_head_sha"]),
                latest_base_sha if data.get("comments") else None,
            )
            if operation["type"] == "review_body":
                client.graphql(
                    UPDATE_REVIEW_MUTATION,
                    {"id": operation["id"], "body": operation["body"]},
                )
            else:
                client.graphql(
                    UPDATE_COMMENT_MUTATION,
                    {"id": operation["id"], "body": operation["body"]},
                )
        except Exception as error:
            if not applied_operations:
                raise
            plan["applied"] = True
            plan["verification"] = verification("partial", error)
            return plan
        applied_operations.append({"id": operation["id"], "type": operation["type"]})
    plan["applied"] = True
    plan["mutation"]["complete"] = True
    plan["verification"] = verification("unverified")
    try:
        _, refreshed = fetch_review_context(client, target)
        updated = select_pending_review(refreshed, actor, review.get("id"))
        if updated.get("body") != body:
            raise ToolkitError("review body readback does not match update")
        refreshed_comments = {
            comment.get("id"): comment
            for comment in updated.get("comments", [])
            if isinstance(comment, dict)
        }
        for operation in operations:
            if operation["type"] != "comment_body":
                continue
            comment = refreshed_comments.get(operation["id"])
            if not comment or comment.get("body") != operation["body"]:
                raise ToolkitError("draft comment body readback does not match update")
        if updated.get("state") != "PENDING" or review_author(updated) != actor:
            raise ToolkitError("updated review lost pending state or actor ownership")
    except Exception as error:
        plan["verification"] = verification("unverified", error)
        return plan
    plan["verification"] = verification("verified")
    plan["review"] = normalize_review(updated, True, 0)
    return plan


def run(args: argparse.Namespace, client: GhClient) -> dict[str, Any]:
    if args.command == "inspect":
        return inspect(args, client)
    if args.command == "create":
        return create(args, client)
    if args.command == "update":
        return update(args, client)
    raise InputError(f"unsupported command: {args.command}")


def main() -> int:
    try:
        emit_json(run(parse_args(), GhClient()))
    except ToolkitError as error:
        return fail(error)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
