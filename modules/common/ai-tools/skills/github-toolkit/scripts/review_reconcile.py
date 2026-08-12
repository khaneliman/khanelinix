"""Reconcile one owned pending pull request review to declared desired state."""

from __future__ import annotations

import re
from typing import Any

import review_draft
from _github import GhClient, InputError, Target, ToolkitError, current_actor

COMMENT_MARKER_PREFIX = "<!-- ai-tools:review-comment:"
COMMENT_MARKER_PATTERN = re.compile(
    r"<!-- ai-tools:review-comment:([A-Za-z0-9][A-Za-z0-9._-]{0,79}) -->"
)

ADD_THREAD_MUTATION = """
mutation($input: AddPullRequestReviewThreadInput!) {
  addPullRequestReviewThread(input: $input) {
    thread {
      id
      comments(last: 1) { nodes { id path startLine line body } }
    }
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


def managed_key(body: Any) -> str | None:
    text = body if isinstance(body, str) else ""
    matches = COMMENT_MARKER_PATTERN.findall(text)
    if text.count(COMMENT_MARKER_PREFIX) != len(matches):
        raise InputError("managed review comment contains an invalid key marker")
    if len(matches) > 1:
        raise InputError("managed review comment contains multiple key markers")
    return matches[0] if matches else None


def render_comment_body(body: str, key: str) -> str:
    if COMMENT_MARKER_PREFIX in body:
        raise InputError("comment body must not contain a managed key marker")
    return f"{body.rstrip()}\n\n{COMMENT_MARKER_PREFIX}{key} -->"


def visible_comment_body(comment: dict[str, Any]) -> str:
    body = str(comment["body"])
    key = str(comment["key"])
    suffix = f"\n\n{COMMENT_MARKER_PREFIX}{key} -->"
    if not body.endswith(suffix):
        raise ToolkitError("desired review comment omitted its managed key suffix")
    return body[: -len(suffix)]


def normalize_desired_comments(value: Any) -> list[dict[str, Any]]:
    if value is None:
        return []
    if not isinstance(value, list):
        raise InputError("comments must be an array")
    comments: list[dict[str, Any]] = []
    keys: set[str] = set()
    for index, raw in enumerate(value):
        if not isinstance(raw, dict):
            raise InputError(f"comments[{index}] must be an object")
        review_draft._only_keys(
            raw,
            {
                "body",
                "key",
                "line",
                "path",
                "side",
                "start_line",
                "start_side",
            },
            f"comments[{index}]",
        )
        key = review_draft._string(raw.get("key"), f"comments[{index}].key")
        if (
            COMMENT_MARKER_PATTERN.fullmatch(f"{COMMENT_MARKER_PREFIX}{key} -->")
            is None
        ):
            raise InputError(
                f"comments[{index}].key must use 1-80 letters, digits, '.', '_', or '-'"
            )
        if key in keys:
            raise InputError(f"duplicate managed review comment key: {key}")
        keys.add(key)
        normalized = review_draft.normalize_create_comment(
            {name: value for name, value in raw.items() if name != "key"}, index
        )
        normalized["key"] = key
        normalized["body"] = render_comment_body(normalized["body"], key)
        comments.append(normalized)
    return comments


def normalize_input(
    data: dict[str, Any], pull_request: dict[str, Any]
) -> dict[str, Any]:
    review_draft._only_keys(data, {"body", "comments", "expected_head_sha"}, "input")
    expected_sha = review_draft.validate_expected_sha(
        data.get("expected_head_sha"), pull_request
    )
    body = review_draft._string(data.get("body"), "body")
    review_draft.validate_marker(body)
    return {
        "body": body,
        "comments": normalize_desired_comments(data.get("comments", [])),
        "expected_head_sha": expected_sha,
    }


def require_reviewable(pull_request: dict[str, Any]) -> None:
    if pull_request.get("state") != "OPEN":
        raise InputError("pull request must be open for pending review reconciliation")
    if pull_request.get("is_draft"):
        raise InputError("draft pull requests cannot receive reconciled reviews")


def select_managed_pending_review(
    reviews: list[dict[str, Any]], actor: str
) -> dict[str, Any] | None:
    actor_pending = [
        review
        for review in reviews
        if review.get("state") == "PENDING"
        and review_draft.review_author(review) == actor
    ]
    if len(actor_pending) > 1:
        raise InputError("current actor owns multiple pending reviews")
    foreign_marked = [
        review
        for review in reviews
        if review.get("state") == "PENDING"
        and review_draft.review_author(review) != actor
        and review_draft.MARKER in str(review.get("body") or "")
    ]
    if foreign_marked:
        raise InputError("another actor owns a marked pending review")
    if not actor_pending:
        return None
    review = actor_pending[0]
    if str(review.get("body") or "").count(review_draft.MARKER) != 1:
        raise InputError("current actor pending review is not managed by this helper")
    return review


def comment_anchor(comment: dict[str, Any]) -> dict[str, Any]:
    return {
        "line": review_draft._comment_anchor_value(comment, "line"),
        "path": review_draft._comment_anchor_value(comment, "path"),
        "side": review_draft._comment_anchor_value(comment, "side"),
        "start_line": review_draft._comment_anchor_value(comment, "start_line"),
        "start_side": review_draft._comment_anchor_value(comment, "start_side"),
    }


def same_anchor(left: dict[str, Any], right: dict[str, Any]) -> bool:
    return comment_anchor(left) == comment_anchor(right)


def operation_comment(comment: dict[str, Any]) -> dict[str, Any]:
    return {
        "body": comment["body"],
        "key": comment["key"],
        "line": comment["line"],
        "path": comment["path"],
        "side": comment["side"],
        **(
            {
                "start_line": comment["start_line"],
                "start_side": comment["start_side"],
            }
            if "start_line" in comment
            else {}
        ),
    }


def _comment_sort_key(comment: dict[str, Any]) -> tuple[str, str]:
    return (str(comment.get("id") or ""), str(comment.get("databaseId") or ""))


def plan_existing_review(
    pull_request: dict[str, Any],
    review: dict[str, Any],
    actor: str,
    desired: dict[str, Any],
) -> dict[str, Any]:
    current_by_key: dict[str, list[dict[str, Any]]] = {}
    legacy_comments: list[dict[str, Any]] = []
    unmanaged = 0
    for comment in review.get("comments", []):
        if not isinstance(comment, dict):
            continue
        key = managed_key(comment.get("body"))
        if key is None:
            legacy_comments.append(comment)
            unmanaged += 1
            continue
        if not isinstance(comment.get("id"), str):
            raise ToolkitError("managed review comment omitted GraphQL ID")
        current_by_key.setdefault(key, []).append(comment)

    additions: list[dict[str, Any]] = []
    updates: list[dict[str, Any]] = []
    deletions: list[dict[str, Any]] = []
    desired_keys: set[str] = set()
    for wanted in desired["comments"]:
        key = wanted["key"]
        desired_keys.add(key)
        current = sorted(current_by_key.get(key, []), key=_comment_sort_key)
        legacy_anchored = [
            item
            for item in legacy_comments
            if same_anchor(item, wanted)
            and item.get("body") == visible_comment_body(wanted)
        ]
        exact = [
            item
            for item in current
            if same_anchor(item, wanted) and item.get("body") == wanted["body"]
        ]
        anchored = [item for item in current if same_anchor(item, wanted)]
        if exact:
            keeper = exact[0]
        elif anchored:
            keeper = anchored[0]
            updates.append(
                {
                    **operation_comment(wanted),
                    "id": keeper["id"],
                    "type": "update_comment",
                }
            )
        elif len(legacy_anchored) == 1:
            keeper = legacy_anchored[0]
            if not isinstance(keeper.get("id"), str):
                raise ToolkitError("legacy review comment omitted GraphQL ID")
            unmanaged -= 1
            legacy_comments.remove(keeper)
            updates.append(
                {
                    **operation_comment(wanted),
                    "id": keeper["id"],
                    "type": "update_comment",
                }
            )
        else:
            keeper = None
            additions.append({**operation_comment(wanted), "type": "add_comment"})
        for item in current:
            if item is keeper:
                continue
            deletions.append({"id": item["id"], "key": key, "type": "delete_comment"})

    for key, comments in current_by_key.items():
        if key in desired_keys:
            continue
        for comment in sorted(comments, key=_comment_sort_key):
            deletions.append(
                {"id": comment["id"], "key": key, "type": "delete_comment"}
            )

    operations: list[dict[str, Any]] = []
    if review.get("body") != desired["body"]:
        operations.append(
            {
                "body": desired["body"],
                "id": review["id"],
                "type": "update_review",
            }
        )
    operations.extend(additions)
    operations.extend(updates)
    operations.extend(deletions)
    return {
        "action": "update" if operations else "noop",
        "actor": actor,
        "applied": False,
        "desired": desired,
        "operations": operations,
        "preserved_unmanaged_comments": unmanaged,
        "pull_request": pull_request,
        "review": review_draft.normalize_review(review, True, 0),
    }


def plan_create_review(
    pull_request: dict[str, Any], actor: str, desired: dict[str, Any]
) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "body": desired["body"],
        "commit_id": desired["expected_head_sha"],
    }
    if desired["comments"]:
        payload["comments"] = [
            {key: value for key, value in comment.items() if key != "key"}
            for comment in desired["comments"]
        ]
    return {
        "action": "create",
        "actor": actor,
        "applied": False,
        "desired": desired,
        "payload": payload,
        "pull_request": pull_request,
    }


def build_plan(
    client: GhClient,
    target: Target,
    data: dict[str, Any],
    expected_actor: str | None = None,
) -> dict[str, Any]:
    pull_request, reviews = review_draft.fetch_review_context(client, target)
    require_reviewable(pull_request)
    actor = current_actor(client)
    if expected_actor is not None and actor != expected_actor:
        raise InputError("current GitHub actor changed during reconciliation")
    desired = normalize_input(data, pull_request)
    review = select_managed_pending_review(reviews, actor)
    files = review_draft.fetch_diff_files(client, target) if desired["comments"] else {}
    for index, comment in enumerate(desired["comments"]):
        review_draft.verify_anchor(comment, files, f"comments[{index}]")
    if review is None:
        return plan_create_review(pull_request, actor, desired)
    review = dict(review)
    review["comments"] = review_draft.fetch_review_comments_with_sides(
        client, target, review
    )
    return plan_existing_review(pull_request, review, actor, desired)


def add_comment(
    client: GhClient, review_id: str, operation: dict[str, Any]
) -> dict[str, Any]:
    input_value = {
        "body": operation["body"],
        "line": operation["line"],
        "path": operation["path"],
        "pullRequestReviewId": review_id,
        "side": operation["side"],
    }
    if "start_line" in operation:
        input_value["startLine"] = operation["start_line"]
        input_value["startSide"] = operation["start_side"]
    payload = client.graphql(ADD_THREAD_MUTATION, {"input": input_value})
    thread = review_draft.mutation_object(
        payload, "addPullRequestReviewThread", "thread"
    )
    try:
        comment = thread["comments"]["nodes"][0]
    except (KeyError, IndexError, TypeError) as error:
        raise ToolkitError("GitHub response omitted added review comment") from error
    if not isinstance(comment, dict) or not isinstance(comment.get("id"), str):
        raise ToolkitError("GitHub response returned invalid added review comment")
    return {"id": comment["id"], "key": operation["key"], "type": "add_comment"}


def apply_operation(
    client: GhClient, review_id: str, operation: dict[str, Any]
) -> dict[str, Any]:
    if operation["type"] == "add_comment":
        return add_comment(client, review_id, operation)
    if operation["type"] == "update_review":
        payload = client.graphql(
            review_draft.UPDATE_REVIEW_MUTATION,
            {"body": operation["body"], "id": operation["id"]},
        )
        review_draft.validate_mutation_id(
            payload,
            "updatePullRequestReview",
            "pullRequestReview",
            operation["id"],
        )
    elif operation["type"] == "update_comment":
        payload = client.graphql(
            review_draft.UPDATE_COMMENT_MUTATION,
            {"body": operation["body"], "id": operation["id"]},
        )
        review_draft.validate_mutation_id(
            payload,
            "updatePullRequestReviewComment",
            "pullRequestReviewComment",
            operation["id"],
        )
    elif operation["type"] == "delete_comment":
        payload = client.graphql(DELETE_COMMENT_MUTATION, {"id": operation["id"]})
        review_draft.validate_mutation_id(
            payload,
            "deletePullRequestReviewComment",
            "pullRequestReviewComment",
            operation["id"],
        )
    else:
        raise InputError(f"unsupported reconciliation operation: {operation['type']}")
    return {
        "id": operation["id"],
        **({"key": operation["key"]} if "key" in operation else {}),
        "type": operation["type"],
    }


def verify_desired_state(
    client: GhClient,
    target: Target,
    actor: str,
    desired: dict[str, Any],
    expected_base_sha: str,
) -> dict[str, Any]:
    review_draft.verify_current_oids(
        client, target, desired["expected_head_sha"], expected_base_sha
    )
    pull_request, reviews = review_draft.fetch_review_context(client, target)
    require_reviewable(pull_request)
    review = select_managed_pending_review(reviews, actor)
    if review is None:
        raise ToolkitError("reconciled pending review was not found")
    review = dict(review)
    review["comments"] = review_draft.fetch_review_comments_with_sides(
        client, target, review
    )
    if review.get("body") != desired["body"]:
        raise ToolkitError("reconciled review body does not match desired state")
    actual: dict[str, list[dict[str, Any]]] = {}
    for comment in review["comments"]:
        key = managed_key(comment.get("body"))
        if key is not None:
            actual.setdefault(key, []).append(comment)
    expected = {comment["key"]: comment for comment in desired["comments"]}
    if set(actual) != set(expected):
        raise ToolkitError("managed review comment keys do not match desired state")
    for key, wanted in expected.items():
        comments = actual[key]
        if len(comments) != 1 or not review_draft._readback_matches_request(
            comments[0], wanted
        ):
            raise ToolkitError(
                f"managed review comment does not match desired state: {key}"
            )
    if review.get("state") != "PENDING" or review_draft.review_author(review) != actor:
        raise ToolkitError("reconciled review lost pending state or actor ownership")
    return review_draft.normalize_review(review, True, 0)


def apply_plan(
    client: GhClient,
    target: Target,
    plan: dict[str, Any],
) -> dict[str, Any]:
    desired = plan["desired"]
    base_sha = plan["pull_request"].get("base_sha")
    if not isinstance(base_sha, str):
        raise ToolkitError("GitHub response omitted current PR base SHA")
    result = dict(plan)
    result["mutation"] = {
        "applied_operations": [],
        "attempted_operations": [],
        "complete": False,
        "requested_operations": (
            1 if plan["action"] == "create" else len(plan.get("operations", []))
        ),
    }
    if plan["action"] == "noop":
        result["mutation"]["complete"] = True
        result["review"] = verify_desired_state(
            client, target, plan["actor"], desired, base_sha
        )
        result["verification"] = review_draft.verification("verified")
        return result
    if plan["action"] == "create":
        review_draft.verify_current_oids(
            client, target, desired["expected_head_sha"], base_sha
        )
        attempted = {"type": "create_review"}
        result["mutation"]["attempted_operations"].append(attempted)
        try:
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
                input_value=plan["payload"],
            )
        except Exception as error:  # noqa: BLE001 - ambiguous remote write receipt
            result["verification"] = review_draft.verification("unverified", error)
            return result
        result["applied"] = True
        if not isinstance(response, dict) or not isinstance(
            response.get("node_id"), str
        ):
            result["verification"] = review_draft.verification(
                "unverified", "review creation returned no review node ID"
            )
            return result
        result["mutation"]["applied_operations"].append(
            {"id": response["node_id"], "type": "create_review"}
        )
    else:
        review_id = plan["review"].get("id")
        if not isinstance(review_id, str):
            raise ToolkitError("pending review omitted GraphQL ID")
        for operation in plan["operations"]:
            try:
                review_draft.verify_current_oids(
                    client, target, desired["expected_head_sha"], base_sha
                )
            except Exception as error:
                if not result["mutation"]["attempted_operations"]:
                    raise
                result["verification"] = review_draft.verification("partial", error)
                return result
            attempted = {
                "type": operation["type"],
                **({"id": operation["id"]} if "id" in operation else {}),
                **({"key": operation["key"]} if "key" in operation else {}),
            }
            result["mutation"]["attempted_operations"].append(attempted)
            try:
                receipt = apply_operation(client, review_id, operation)
            except Exception as error:  # noqa: BLE001 - preserve ambiguous write truth
                result["applied"] = bool(result["mutation"]["applied_operations"])
                status = "partial" if result["applied"] else "unverified"
                result["verification"] = review_draft.verification(status, error)
                return result
            result["applied"] = True
            result["mutation"]["applied_operations"].append(receipt)
    result["mutation"]["complete"] = True
    result["verification"] = review_draft.verification("unverified")
    try:
        result["review"] = verify_desired_state(
            client, target, plan["actor"], desired, base_sha
        )
    except Exception as error:  # noqa: BLE001 - report post-write readback failure
        result["verification"] = review_draft.verification("unverified", error)
        return result
    result["verification"] = review_draft.verification("verified")
    return result


def reconcile(args: Any, client: GhClient) -> dict[str, Any]:
    data = review_draft.read_json_input(args.input)
    target = review_draft.resolve_target(client, args.repo, args.pr)
    plan = build_plan(client, target, data)
    if not args.apply:
        return plan
    refreshed = build_plan(client, target, data, plan["actor"])
    return apply_plan(client, target, refreshed)
