#!/usr/bin/env python3
"""Inspect, create, update, or delete current-actor pull request reviews."""

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

HUNK_HEADER = re.compile(r"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@")


REVIEWS_QUERY = """
query($owner: String!, $repo: String!, $number: Int!, $cursor: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      id
      number
      url
      state
      isDraft
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


DELETE_COMMENT_MUTATION = """
mutation($id: ID!) {
  deletePullRequestReviewComment(input: {id: $id}) {
    pullRequestReviewComment { id }
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


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Inspect, plan, or apply current-actor pull request review writes."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    inspect = subparsers.add_parser("inspect", help="Inspect pull request reviews.")
    add_target_arguments(inspect)
    inspect.add_argument(
        "--all-reviews", action="store_true", help="Include reviews by other actors."
    )
    inspect.add_argument(
        "--include-bodies",
        action="store_true",
        help="Emit full review and comment bodies instead of previews.",
    )
    inspect.add_argument("--max-body-chars", type=int, default=240)

    for command in ("create", "update", "delete"):
        child = subparsers.add_parser(command, help=f"Plan or apply review {command}.")
        add_target_arguments(child)
        child.add_argument("--input", required=True, help="JSON file, or - for stdin.")
        child.add_argument(
            "--apply", action="store_true", help="Apply validated review write."
        )
    return parser.parse_args(argv)


def _graphql_pr(payload: dict[str, Any]) -> dict[str, Any]:
    try:
        pull_request = payload["data"]["repository"]["pullRequest"]
    except (KeyError, TypeError) as error:
        raise ToolkitError("GitHub response omitted pull request data") from error
    if not isinstance(pull_request, dict):
        raise ToolkitError("pull request was not found in base repository")
    return pull_request


def mutation_object(
    payload: dict[str, Any], mutation: str, field: str
) -> dict[str, Any]:
    try:
        value = payload["data"][mutation][field]
    except (KeyError, TypeError) as error:
        raise ToolkitError(f"GitHub response omitted {mutation}.{field}") from error
    if not isinstance(value, dict):
        raise ToolkitError(f"GitHub response returned invalid {mutation}.{field}")
    return value


def validate_mutation_id(
    payload: dict[str, Any], mutation: str, field: str, expected_id: Any
) -> dict[str, Any]:
    value = mutation_object(payload, mutation, field)
    if str(value.get("id")) != str(expected_id):
        raise ToolkitError(f"GitHub response returned wrong {mutation}.{field} ID")
    return value


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
                "id": pull_request.get("id"),
                "is_draft": bool(pull_request.get("isDraft")),
                "number": pull_request.get("number"),
                "repository": target.repository,
                "state": pull_request.get("state"),
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
                (
                    f"repos/{target.repository}/pulls/{target.pull_request}/files"
                    f"?per_page=100&page={page}"
                ),
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
                (
                    f"repos/{target.repository}/pulls/{target.pull_request}/reviews/"
                    f"{review_id}/comments?per_page=100&page={page}"
                ),
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


def _text(value: Any, field: str) -> str:
    if not isinstance(value, str):
        raise InputError(f"{field} must be a string")
    return value


def _only_keys(value: dict[str, Any], allowed: set[str], context: str) -> None:
    unknown = sorted(set(value) - allowed)
    if "event" in unknown:
        raise InputError(
            "review event is never accepted; this helper cannot submit reviews"
        )
    if unknown:
        raise InputError(f"unsupported {context} fields: {', '.join(unknown)}")


def validate_expected_sha(value: Any, pull_request: dict[str, Any]) -> str:
    expected = _string(value, "expected_head_sha")
    current = pull_request.get("head_sha")
    if not isinstance(current, str) or expected.lower() != current.lower():
        raise InputError(
            f"expected_head_sha does not match current PR head: {expected} != {current}"
        )
    return expected


def validate_expected_review_state(value: Any, review: dict[str, Any]) -> str:
    expected = _string(value, "expected_review_state")
    current = review.get("state")
    if not isinstance(current, str) or expected != current:
        raise InputError(
            "expected_review_state does not match current review state: "
            f"{expected} != {current}"
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
    owned = [review for review in reviews if review_author(review) == actor]
    selected = reviews if args.all_reviews else owned
    return {
        "actor": actor,
        "counts": {
            "owned": len(owned),
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
    body = _text(data["body"], "body") if "body" in data else ""
    raw_comments = data.get("comments", [])
    if not isinstance(raw_comments, list):
        raise InputError("comments must be an array")
    comments = [
        normalize_create_comment(comment, index)
        for index, comment in enumerate(raw_comments)
    ]
    if not body.strip() and not comments:
        raise InputError("create input must include a non-empty body or comments")
    ensure_create_available(reviews, actor)
    files = fetch_diff_files(client, target) if comments else {}
    for index, comment in enumerate(comments):
        verify_anchor(comment, files, f"comments[{index}]")
    payload = {"commit_id": expected_sha}
    if "body" in data:
        payload["body"] = body
    if comments:
        payload["comments"] = comments
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
    latest_files = fetch_diff_files(client, target) if comments else {}
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
                and str(review.get("body") or "") == body
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
    except Exception as error:  # noqa: BLE001 - report readback as unverified
        plan["verification"] = verification("unverified", error)
        return plan
    plan["verification"] = verification("verified")
    plan["review"] = normalize_review(created_review, True, 0)
    return plan


def select_owned_review(
    reviews: list[dict[str, Any]], actor: str, requested_id: Any
) -> dict[str, Any]:
    value = _string(
        str(requested_id) if requested_id is not None else None, "review_id"
    )
    matches = [
        review
        for review in reviews
        if str(review.get("id")) == value or str(review.get("databaseId")) == value
    ]
    if len(matches) != 1:
        raise InputError("review_id does not identify one pull request review")
    review = matches[0]
    if review_author(review) != actor:
        raise InputError("target review is not owned by current actor")
    return review


def select_comment(
    request: dict[str, Any], comments: list[dict[str, Any]], index: int
) -> dict[str, Any]:
    identifier = request.get("id")
    database_id = request.get("database_id")
    if identifier is None and database_id is None:
        raise InputError(f"comments[{index}] needs id or database_id")
    matches = [
        comment
        for comment in comments
        if (identifier is not None and str(comment.get("id")) == str(identifier))
        or (
            database_id is not None
            and str(comment.get("databaseId")) == str(database_id)
        )
    ]
    if len(matches) != 1:
        raise InputError(f"comments[{index}] does not identify one review comment")
    selected = matches[0]
    comparisons = {
        "path": selected.get("path"),
        "line": selected.get("line"),
        "start_line": selected.get("startLine"),
    }
    for field, actual in comparisons.items():
        if field in request and request[field] != actual:
            raise InputError(f"comments[{index}].{field} does not match review anchor")
    return selected


def normalize_update_operations(
    data: dict[str, Any], review: dict[str, Any]
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
            {"body", "database_id", "id", "line", "path", "start_line"},
            f"comments[{index}]",
        )
        body = _string(request.get("body"), f"comments[{index}].body")
        selected = select_comment(request, review.get("comments", []), index)
        if selected.get("body") != body:
            operations.append(
                {
                    "body": body,
                    "database_id": selected.get("databaseId"),
                    "id": selected.get("id"),
                    "line": selected.get("line"),
                    "path": selected.get("path"),
                    "side": selected.get("diffSide"),
                    "start_line": selected.get("startLine"),
                    "start_side": selected.get("startDiffSide"),
                    "type": "comment_body",
                }
            )
    return operations


def update(args: argparse.Namespace, client: GhClient) -> dict[str, Any]:
    data = read_json_input(args.input)
    _only_keys(
        data,
        {
            "body",
            "comments",
            "expected_head_sha",
            "expected_review_state",
            "review_id",
        },
        "input",
    )
    if "body" not in data and "comments" not in data:
        raise InputError("update input must include body or comments")
    target = resolve_target(client, args.repo, args.pr)
    pull_request, reviews = fetch_review_context(client, target)
    actor = current_actor(client)
    review = select_owned_review(reviews, actor, data.get("review_id"))
    expected_head_sha = (
        validate_expected_sha(data.get("expected_head_sha"), pull_request)
        if "expected_head_sha" in data
        else None
    )
    expected_review_state = (
        validate_expected_review_state(data.get("expected_review_state"), review)
        if "expected_review_state" in data
        else None
    )
    body = (
        _text(data["body"], "body") if "body" in data else str(review.get("body") or "")
    )
    operations = normalize_update_operations(data, review)
    if body != review.get("body"):
        operations.insert(
            0, {"body": body, "id": review.get("id"), "type": "review_body"}
        )
    plan: dict[str, Any] = {
        "action": "update" if operations else "noop",
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
    latest_review = select_owned_review(latest_reviews, latest_actor, review.get("id"))
    if expected_head_sha is not None:
        validate_expected_sha(expected_head_sha, latest_pull_request)
    if expected_review_state is not None:
        validate_expected_review_state(expected_review_state, latest_review)
    latest_body = (
        _text(data["body"], "body")
        if "body" in data
        else str(latest_review.get("body") or "")
    )
    operations = normalize_update_operations(data, latest_review)
    if latest_body != latest_review.get("body"):
        operations.insert(
            0,
            {"body": latest_body, "id": latest_review.get("id"), "type": "review_body"},
        )
    if not operations:
        plan["action"] = "noop"
        plan["operations"] = []
        plan["review"] = normalize_review(latest_review, True, 0)
        plan["verification"] = verification("verified")
        return plan
    body = latest_body
    review = latest_review
    plan["operations"] = operations
    plan["review"] = normalize_review(latest_review, True, 0)
    if expected_head_sha is not None:
        verify_current_oids(client, target, expected_head_sha)
    applied_operations: list[dict[str, Any]] = []
    plan["mutation"] = {
        "applied_operations": applied_operations,
        "attempted_operations": [],
        "complete": False,
        "requested_operations": len(operations),
    }
    for operation in operations:
        attempted = {"id": operation["id"], "type": operation["type"]}
        plan["mutation"]["attempted_operations"].append(attempted)
        try:
            if operation["type"] == "review_body":
                payload = client.graphql(
                    UPDATE_REVIEW_MUTATION,
                    {"id": operation["id"], "body": operation["body"]},
                )
                validate_mutation_id(
                    payload,
                    "updatePullRequestReview",
                    "pullRequestReview",
                    operation["id"],
                )
            else:
                payload = client.graphql(
                    UPDATE_COMMENT_MUTATION,
                    {"id": operation["id"], "body": operation["body"]},
                )
                validate_mutation_id(
                    payload,
                    "updatePullRequestReviewComment",
                    "pullRequestReviewComment",
                    operation["id"],
                )
        except Exception as error:  # noqa: BLE001 - preserve ambiguous write truth
            plan["applied"] = bool(applied_operations)
            status = "partial" if applied_operations else "unverified"
            plan["verification"] = verification(status, error)
            return plan
        applied_operations.append({"id": operation["id"], "type": operation["type"]})
    plan["applied"] = True
    plan["mutation"]["complete"] = True
    plan["verification"] = verification("unverified")
    try:
        _, refreshed = fetch_review_context(client, target)
        updated = select_owned_review(refreshed, actor, review.get("id"))
        if expected_review_state is not None:
            validate_expected_review_state(expected_review_state, updated)
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
            if not comment or not _readback_matches_request(comment, operation):
                raise ToolkitError("review comment body readback does not match update")
        if review_author(updated) != actor:
            raise ToolkitError("updated review lost actor ownership")
    except Exception as error:  # noqa: BLE001 - report readback as unverified
        plan["verification"] = verification("unverified", error)
        return plan
    plan["verification"] = verification("verified")
    plan["review"] = normalize_review(updated, True, 0)
    return plan


def normalize_delete_comments(
    data: dict[str, Any], review: dict[str, Any]
) -> list[dict[str, Any]]:
    raw_comments = data.get("comments")
    if raw_comments is None:
        return []
    if not isinstance(raw_comments, list) or not raw_comments:
        raise InputError("comments must be a non-empty array when provided")
    operations = []
    seen: set[str] = set()
    for index, request in enumerate(raw_comments):
        if not isinstance(request, dict):
            raise InputError(f"comments[{index}] must be an object")
        _only_keys(request, {"database_id", "id"}, f"comments[{index}]")
        selected = select_comment(request, review.get("comments", []), index)
        identifier = selected.get("id")
        if not isinstance(identifier, str):
            raise ToolkitError(f"comments[{index}] omitted GraphQL ID")
        if identifier in seen:
            raise InputError(f"comments[{index}] duplicates a selected review comment")
        seen.add(identifier)
        operations.append(
            {
                "database_id": selected.get("databaseId"),
                "id": identifier,
                "type": "delete_comment",
            }
        )
    return operations


def delete(args: argparse.Namespace, client: GhClient) -> dict[str, Any]:
    data = read_json_input(args.input)
    _only_keys(data, {"comments", "review_id"}, "input")
    target = resolve_target(client, args.repo, args.pr)
    pull_request, reviews = fetch_review_context(client, target)
    actor = current_actor(client)
    review = select_owned_review(reviews, actor, data.get("review_id"))
    if "comments" in data:
        operations = normalize_delete_comments(data, review)
    else:
        if review.get("state") != "PENDING":
            raise InputError("GitHub can delete only pending pull request reviews")
        database_id = review.get("databaseId")
        if database_id is None:
            raise ToolkitError("pending review omitted database ID")
        operations = [
            {
                "database_id": str(database_id),
                "id": review.get("id"),
                "type": "delete_review",
            }
        ]
    plan: dict[str, Any] = {
        "action": "delete",
        "actor": actor,
        "applied": False,
        "operations": operations,
        "pull_request": pull_request,
        "review": normalize_review(review, True, 0),
    }
    if not args.apply:
        return plan

    _, latest_reviews = fetch_review_context(client, target)
    latest_actor = current_actor(client)
    if latest_actor != actor:
        raise InputError("current GitHub actor changed before review deletion")
    latest_review = select_owned_review(latest_reviews, latest_actor, review.get("id"))
    if "comments" in data:
        operations = normalize_delete_comments(data, latest_review)
    else:
        if latest_review.get("state") != "PENDING":
            raise InputError("GitHub can delete only pending pull request reviews")
        database_id = latest_review.get("databaseId")
        if database_id is None:
            raise ToolkitError("pending review omitted database ID")
        operations = [
            {
                "database_id": str(database_id),
                "id": latest_review.get("id"),
                "type": "delete_review",
            }
        ]
    plan["operations"] = operations
    plan["review"] = normalize_review(latest_review, True, 0)
    applied_operations: list[dict[str, Any]] = []
    plan["mutation"] = {
        "applied_operations": applied_operations,
        "attempted_operations": [],
        "complete": False,
        "requested_operations": len(operations),
    }
    for operation in operations:
        attempted = {"id": operation["id"], "type": operation["type"]}
        plan["mutation"]["attempted_operations"].append(attempted)
        try:
            if operation["type"] == "delete_review":
                response = client.run_json(
                    [
                        "api",
                        "--method",
                        "DELETE",
                        f"repos/{target.repository}/pulls/{target.pull_request}/reviews/{operation['database_id']}",
                        "-H",
                        "Accept: application/vnd.github+json",
                        "-H",
                        "X-GitHub-Api-Version: 2022-11-28",
                    ]
                )
                if not isinstance(response, dict) or (
                    str(response.get("id")) != operation["database_id"]
                    and str(response.get("node_id")) != str(operation["id"])
                ):
                    raise ToolkitError("GitHub returned wrong deleted review identity")
            else:
                payload = client.graphql(
                    DELETE_COMMENT_MUTATION, {"id": operation["id"]}
                )
                validate_mutation_id(
                    payload,
                    "deletePullRequestReviewComment",
                    "pullRequestReviewComment",
                    operation["id"],
                )
        except Exception as error:  # noqa: BLE001 - preserve ambiguous write truth
            plan["applied"] = bool(applied_operations)
            status = "partial" if applied_operations else "unverified"
            plan["verification"] = verification(status, error)
            return plan
        applied_operations.append({"id": operation["id"], "type": operation["type"]})
    plan["applied"] = True
    plan["mutation"]["complete"] = True
    plan["verification"] = verification("unverified")
    try:
        _, refreshed = fetch_review_context(client, target)
        matches = [
            item
            for item in refreshed
            if str(item.get("id")) == str(review.get("id"))
            or str(item.get("databaseId")) == str(review.get("databaseId"))
        ]
        if "comments" not in data:
            if matches:
                raise ToolkitError("deleted pending review remains present in readback")
        else:
            if len(matches) != 1 or review_author(matches[0]) != actor:
                raise ToolkitError("review comment deletion lost review ownership")
            refreshed_review = dict(matches[0])
            remaining = {comment.get("id") for comment in refreshed_review["comments"]}
            deleted = {operation["id"] for operation in operations}
            if remaining & deleted:
                raise ToolkitError("deleted review comment remains present in readback")
            plan["review"] = normalize_review(refreshed_review, True, 0)
    except Exception as error:  # noqa: BLE001 - report readback as unverified
        plan["verification"] = verification("unverified", error)
        return plan
    plan["verification"] = verification("verified")
    return plan


def run(args: argparse.Namespace, client: GhClient) -> dict[str, Any]:
    if args.command == "inspect":
        return inspect(args, client)
    if args.command == "create":
        return create(args, client)
    if args.command == "update":
        return update(args, client)
    if args.command == "delete":
        return delete(args, client)
    raise InputError(f"unsupported command: {args.command}")


def main() -> int:
    try:
        emit_json(run(parse_args(), GhClient()))
    except ToolkitError as error:
        return fail(error)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
