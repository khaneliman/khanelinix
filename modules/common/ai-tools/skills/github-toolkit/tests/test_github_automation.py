from __future__ import annotations

import argparse
import json
import subprocess
import sys
import unittest
from pathlib import Path
from unittest import mock

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPTS))

import _github
import issue_scan
import pr_snapshot
import review_draft
import review_reconcile
import review_threads

HEAD_SHA = "a" * 40
PATCH = """@@ -20,3 +8,4 @@
 context eight
-old twenty-one
+new nine
+new ten
 context eleven
"""


def review_comment(
    *,
    identifier: str = "PRRC_1",
    body: str = "old body",
    line: int = 10,
    start_line: int | None = None,
    side: str = "RIGHT",
    start_side: str | None = None,
) -> dict[str, object]:
    return {
        "id": identifier,
        "databaseId": "101",
        "path": "src/example.py",
        "startLine": start_line,
        "line": line,
        "diffSide": side,
        "startDiffSide": start_side,
        "body": body,
        "createdAt": "2026-07-10T00:00:00Z",
        "updatedAt": "2026-07-10T00:00:00Z",
        "url": "https://github.com/base/repo/pull/7#discussion_r101",
    }


def pending_review(
    *,
    body: str = review_draft.MARKER,
    comments: list[dict[str, object]] | None = None,
) -> dict[str, object]:
    return {
        "id": "PRR_1",
        "databaseId": "55",
        "state": "PENDING",
        "body": body,
        "submittedAt": None,
        "updatedAt": "2026-07-10T00:00:00Z",
        "author": {"login": "viewer"},
        "comments": comments or [],
    }


def pull_request() -> dict[str, object]:
    return {
        "base_sha": "b" * 40,
        "head_sha": HEAD_SHA,
        "id": "PR_1",
        "is_draft": False,
        "number": 7,
        "repository": "base/repo",
        "state": "OPEN",
        "url": "https://github.com/base/repo/pull/7",
    }


class RecordingClient:
    def __init__(self, response: object | None = None):
        self.response = response
        self.json_calls: list[tuple[list[str], object | None]] = []
        self.graphql_calls: list[tuple[str, dict[str, object]]] = []

    def run_json(self, args: list[str], *, input_value: object | None = None) -> object:
        self.json_calls.append((args, input_value))
        if self.response is None:
            raise AssertionError("unexpected run_json mutation")
        return self.response

    def graphql(self, query: str, variables: dict[str, object]) -> dict[str, object]:
        self.graphql_calls.append((query, variables))
        raise AssertionError("unexpected GraphQL mutation")


class GitHubTransportTests(unittest.TestCase):
    def test_graphql_uses_argv_and_json_stdin_without_shell(self) -> None:
        completed = subprocess.CompletedProcess(
            args=[], returncode=0, stdout='{"data":{"ok":true}}', stderr=""
        )
        with mock.patch.object(
            _github.subprocess, "run", return_value=completed
        ) as run:
            payload = _github.GhClient().graphql(
                "query($id: ID!) { node(id: $id) { id } }", {"id": "NODE"}
            )

        self.assertEqual(payload["data"]["ok"], True)
        positional, keyword = run.call_args
        self.assertEqual(positional[0], ["gh", "api", "graphql", "--input", "-"])
        self.assertNotIn("shell", keyword)
        stdin = json.loads(keyword["input"])
        self.assertEqual(stdin["variables"], {"id": "NODE"})

    def test_current_branch_target_uses_base_repo_from_pr_url(self) -> None:
        client = mock.Mock()
        client.run_json.return_value = {
            "number": 7,
            "url": "https://github.com/base/repo/pull/7",
        }

        target = _github.resolve_target(client, None, None)

        self.assertEqual(target.repository, "base/repo")
        self.assertEqual(target.pull_request, 7)

    def test_repo_conflict_with_pr_url_is_rejected(self) -> None:
        with self.assertRaises(_github.InputError):
            _github.resolve_target(
                mock.Mock(),
                "other/repo",
                "https://github.com/base/repo/pull/7",
            )

    def test_non_github_dot_com_pr_url_is_rejected(self) -> None:
        self.assertIsNone(
            _github.parse_pull_request_url(
                "https://github.example.com/base/repo/pull/7"
            )
        )
        with self.assertRaisesRegex(_github.InputError, "github.com"):
            _github.resolve_target(
                mock.Mock(),
                None,
                "https://github.example.com/base/repo/pull/7",
            )

    def test_remote_repo_requires_explicit_pr(self) -> None:
        client = mock.Mock()

        with self.assertRaisesRegex(_github.InputError, "--pr is required"):
            _github.resolve_target(client, "base/repo", None)

        client.run_json.assert_not_called()


class SnapshotAndIssueScanTests(unittest.TestCase):
    def test_snapshot_normalizes_bounded_fields(self) -> None:
        result = pr_snapshot.normalize_snapshot(
            {
                "number": 7,
                "files": [{"path": "a.py", "additions": 2, "deletions": 1}],
                "commits": [{"oid": HEAD_SHA, "messageHeadline": "change"}],
                "statusCheckRollup": [{"name": "test", "conclusion": "SUCCESS"}],
                "headRepository": {"name": "fork"},
                "headRepositoryOwner": {"login": "author"},
            },
            "base/repo",
            "viewer",
            [{"filename": "a.py", "additions": 2, "deletions": 1}],
            [{"sha": HEAD_SHA, "commit": {"message": "change"}}],
            {
                "commits": {"complete": True},
                "files": {"complete": True},
            },
        )

        self.assertEqual(result["head"]["repository"], "author/fork")
        self.assertEqual(result["counts"], {"checks": 1, "commits": 1, "files": 1})
        self.assertEqual(result["actor"], "viewer")

    def test_snapshot_collection_paginates_and_reports_completeness(self) -> None:
        first = [{"filename": f"file-{index}"} for index in range(100)]
        second = [{"filename": f"file-{index}"} for index in range(100, 150)]
        client = mock.Mock()
        client.run_json.side_effect = [first, second]

        items, status = pr_snapshot.fetch_collection(
            client,
            _github.Target("base/repo", 7),
            "files",
            150,
            pr_snapshot.FILES_HARD_CAP,
            0,
        )

        self.assertEqual(len(items), 150)
        self.assertEqual(client.run_json.call_count, 2)
        self.assertTrue(status["complete"])
        self.assertFalse(status["truncated"])

    def test_snapshot_collection_reports_hard_cap(self) -> None:
        client = mock.Mock()
        client.run_json.return_value = [{"sha": "one"}, {"sha": "two"}]

        items, status = pr_snapshot.fetch_collection(
            client,
            _github.Target("base/repo", 7),
            "commits",
            3,
            2,
            0,
        )

        self.assertEqual(len(items), 2)
        self.assertFalse(status["complete"])
        self.assertEqual(status["truncation_reasons"], ["github_api_hard_cap"])

    def test_snapshot_defaults_bound_output_and_report_requested_limit(self) -> None:
        with mock.patch.object(sys, "argv", ["pr_snapshot.py"]):
            args = pr_snapshot.parse_args()

        self.assertEqual(args.max_files, 200)
        self.assertEqual(args.max_commits, 100)

        client = mock.Mock()
        client.run_json.side_effect = [
            [{"filename": f"file-{index}"} for index in range(100)],
            [{"filename": f"file-{index}"} for index in range(100, 200)],
        ]
        items, status = pr_snapshot.fetch_collection(
            client,
            _github.Target("base/repo", 7),
            "files",
            500,
            pr_snapshot.FILES_HARD_CAP,
            args.max_files,
        )

        self.assertEqual(len(items), 200)
        self.assertFalse(status["complete"])
        self.assertEqual(status["truncation_reasons"], ["requested_limit"])
        self.assertEqual(status["total"], 500)

    def test_issue_summary_reports_limit_and_search_cap_truncation(self) -> None:
        items = [
            {
                "number": 1,
                "title": "one",
                "comments": 5,
                "labels": [{"name": "bug"}],
                "html_url": "https://github.com/base/repo/issues/1",
            }
        ]
        summary = issue_scan.summarize(
            "base/repo",
            issue_scan.DEFAULT_QUERY,
            100,
            25,
            "comments",
            "desc",
            1200,
            False,
            items,
        )

        self.assertTrue(summary["truncated"])
        self.assertIn("github_search_cap", summary["truncation_reasons"])
        self.assertIn("requested_limit", summary["truncation_reasons"])
        self.assertEqual(summary["labels"], [{"count": 1, "name": "bug"}])

    def test_issue_query_forces_issue_type_and_rejects_pr_type(self) -> None:
        self.assertEqual(
            issue_scan.normalize_issue_query("is:open label:bug"),
            "is:issue is:open label:bug",
        )
        self.assertEqual(
            issue_scan.normalize_issue_query("is:issue is:open"),
            "is:issue is:open",
        )
        with self.assertRaisesRegex(_github.InputError, "pull-request"):
            issue_scan.normalize_issue_query("is:pr is:open")


class ReviewDraftTests(unittest.TestCase):
    def test_patch_parser_distinguishes_left_and_right_lines(self) -> None:
        lines = review_draft.parse_patch_lines(PATCH)
        self.assertIn(21, lines["LEFT"])
        self.assertNotIn(21, lines["RIGHT"])
        self.assertIn(10, lines["RIGHT"])
        self.assertNotIn(10, lines["LEFT"])

    def test_created_review_readback_rejects_wrong_diff_side(self) -> None:
        review = pending_review(
            body=f"{review_draft.MARKER}\ncontext",
            comments=[review_comment(body="defect", side="LEFT")],
        )
        requested = [
            {
                "body": "defect",
                "line": 10,
                "path": "src/example.py",
                "side": "RIGHT",
            }
        ]

        with self.assertRaisesRegex(_github.ToolkitError, "anchor/body"):
            review_draft.verify_created_review(
                review,
                "viewer",
                f"{review_draft.MARKER}\ncontext",
                requested,
            )

    def test_review_comment_rest_readback_preserves_diff_sides(self) -> None:
        client = RecordingClient(
            [
                {
                    "id": 101,
                    "node_id": "PRRC_1",
                    "path": "src/example.py",
                    "start_line": 8,
                    "start_side": "RIGHT",
                    "line": 10,
                    "side": "RIGHT",
                    "body": "defect",
                }
            ]
        )

        with mock.patch.object(
            review_draft,
            "fetch_review_thread_sides",
            return_value={"PRRC_1": {"diffSide": "RIGHT", "startDiffSide": "RIGHT"}},
        ):
            comments = review_draft.fetch_review_comments_with_sides(
                client,
                _github.Target("base/repo", 7),
                pending_review(),
            )

        self.assertEqual(comments[0]["diffSide"], "RIGHT")
        self.assertEqual(comments[0]["startDiffSide"], "RIGHT")

    def test_pending_rest_null_anchor_is_not_certified_from_position(self) -> None:
        body = f"{review_draft.MARKER}\ncontext"
        graphql_comment = review_comment(body="defect")
        review = pending_review(body=body, comments=[graphql_comment])
        client = RecordingClient(
            [
                {
                    "id": 101,
                    "node_id": "PRRC_1",
                    "path": "src/example.py",
                    "position": 4,
                    "start_line": None,
                    "start_side": None,
                    "line": None,
                    "side": None,
                    "body": "defect",
                }
            ]
        )
        with mock.patch.object(
            review_draft, "fetch_review_thread_sides", return_value={}
        ):
            comments = review_draft.fetch_review_comments_with_sides(
                client, _github.Target("base/repo", 7), review
            )
        review["comments"] = comments
        requested = [
            {
                "body": "defect",
                "line": 10,
                "path": "src/example.py",
                "side": "RIGHT",
            }
        ]

        self.assertEqual(comments[0]["line"], 10)
        self.assertIsNone(comments[0]["diffSide"])
        self.assertEqual(comments[0]["position"], 4)
        with self.assertRaisesRegex(_github.ToolkitError, "anchor/body"):
            review_draft.verify_created_review(
                review,
                "viewer",
                body,
                requested,
            )

    def test_create_dry_run_has_no_event_or_mutation(self) -> None:
        data = {
            "expected_head_sha": HEAD_SHA,
            "body": f"{review_draft.MARKER}\ncontext",
            "comments": [
                {
                    "path": "src/example.py",
                    "line": 10,
                    "side": "RIGHT",
                    "body": "issue (blocking): defect",
                }
            ],
        }
        args = argparse.Namespace(
            input="review.json", repo="base/repo", pr="7", apply=False
        )
        client = RecordingClient()
        with (
            mock.patch.object(review_draft, "read_json_input", return_value=data),
            mock.patch.object(
                review_draft,
                "resolve_target",
                return_value=_github.Target("base/repo", 7),
            ),
            mock.patch.object(
                review_draft,
                "fetch_review_context",
                return_value=(pull_request(), []),
            ),
            mock.patch.object(review_draft, "current_actor", return_value="viewer"),
            mock.patch.object(
                review_draft,
                "fetch_diff_files",
                return_value={"src/example.py": {"patch": PATCH}},
            ),
        ):
            result = review_draft.create(args, client)

        self.assertFalse(result["applied"])
        self.assertNotIn("event", result["payload"])
        self.assertEqual(client.json_calls, [])
        self.assertEqual(client.graphql_calls, [])

    def test_create_apply_posts_without_event_and_reads_back_pending(self) -> None:
        body = f"{review_draft.MARKER}\ncontext"
        data = {
            "expected_head_sha": HEAD_SHA,
            "body": body,
            "comments": [
                {
                    "path": "src/example.py",
                    "line": 10,
                    "side": "RIGHT",
                    "body": "issue (blocking): defect",
                }
            ],
        }
        created = pending_review(
            body=body,
            comments=[review_comment(body="issue (blocking): defect")],
        )
        args = argparse.Namespace(
            input="review.json", repo="base/repo", pr="7", apply=True
        )
        client = RecordingClient({"node_id": "PRR_1"})
        with (
            mock.patch.object(review_draft, "read_json_input", return_value=data),
            mock.patch.object(
                review_draft,
                "resolve_target",
                return_value=_github.Target("base/repo", 7),
            ),
            mock.patch.object(
                review_draft,
                "fetch_review_context",
                side_effect=[
                    (pull_request(), []),
                    (pull_request(), []),
                    (pull_request(), [created]),
                ],
            ),
            mock.patch.object(review_draft, "current_actor", return_value="viewer"),
            mock.patch.object(
                review_draft,
                "fetch_diff_files",
                return_value={"src/example.py": {"patch": PATCH}},
            ) as fetch_diff_files,
            mock.patch.object(
                review_draft,
                "pull_request_oids",
                return_value={"base_sha": "b" * 40, "head_sha": HEAD_SHA},
            ),
            mock.patch.object(
                review_draft,
                "fetch_review_comments_with_sides",
                return_value=created["comments"],
            ),
        ):
            result = review_draft.create(args, client)

        self.assertTrue(result["applied"])
        self.assertEqual(result["verification"]["status"], "verified")
        self.assertEqual(len(client.json_calls), 1)
        self.assertEqual(fetch_diff_files.call_count, 2)
        command, posted = client.json_calls[0]
        self.assertIn("POST", command)
        self.assertNotIn("event", posted)

    def test_create_apply_rechecks_head_immediately_before_post(self) -> None:
        body = f"{review_draft.MARKER}\ncontext"
        data = {
            "expected_head_sha": HEAD_SHA,
            "body": body,
            "comments": [
                {
                    "path": "src/example.py",
                    "line": 10,
                    "side": "RIGHT",
                    "body": "issue (blocking): defect",
                }
            ],
        }
        args = argparse.Namespace(
            input="review.json", repo="base/repo", pr="7", apply=True
        )
        client = RecordingClient()
        with (
            mock.patch.object(review_draft, "read_json_input", return_value=data),
            mock.patch.object(
                review_draft,
                "resolve_target",
                return_value=_github.Target("base/repo", 7),
            ),
            mock.patch.object(
                review_draft,
                "fetch_review_context",
                side_effect=[(pull_request(), []), (pull_request(), [])],
            ),
            mock.patch.object(review_draft, "current_actor", return_value="viewer"),
            mock.patch.object(
                review_draft,
                "fetch_diff_files",
                return_value={"src/example.py": {"patch": PATCH}},
            ),
            mock.patch.object(
                review_draft,
                "pull_request_oids",
                return_value={"base_sha": "b" * 40, "head_sha": "c" * 40},
            ),
            self.assertRaises(_github.InputError),
        ):
            review_draft.create(args, client)

        self.assertEqual(client.json_calls, [])

    def test_create_apply_rechecks_head_before_post(self) -> None:
        data = {
            "expected_head_sha": HEAD_SHA,
            "body": f"{review_draft.MARKER}\ncontext",
            "comments": [
                {
                    "path": "src/example.py",
                    "line": 10,
                    "side": "RIGHT",
                    "body": "issue (blocking): defect",
                }
            ],
        }
        stale_pull_request = pull_request()
        stale_pull_request["head_sha"] = "b" * 40
        args = argparse.Namespace(
            input="review.json", repo="base/repo", pr="7", apply=True
        )
        client = RecordingClient()
        with (
            mock.patch.object(review_draft, "read_json_input", return_value=data),
            mock.patch.object(
                review_draft,
                "resolve_target",
                return_value=_github.Target("base/repo", 7),
            ),
            mock.patch.object(
                review_draft,
                "fetch_review_context",
                side_effect=[(pull_request(), []), (stale_pull_request, [])],
            ),
            mock.patch.object(review_draft, "current_actor", return_value="viewer"),
            mock.patch.object(
                review_draft,
                "fetch_diff_files",
                return_value={"src/example.py": {"patch": PATCH}},
            ),
            self.assertRaises(_github.InputError),
        ):
            review_draft.create(args, client)

        self.assertEqual(client.json_calls, [])

    def test_update_rejects_pending_review_owned_by_another_actor(self) -> None:
        review = pending_review()
        review["author"] = {"login": "someone-else"}
        with self.assertRaises(_github.InputError):
            review_draft.select_pending_review([review], "viewer", "PRR_1")

    def test_update_apply_refetches_diff_before_comment_mutation(self) -> None:
        data = {
            "expected_head_sha": HEAD_SHA,
            "comments": [{"id": "PRRC_1", "body": "new body"}],
            "review_id": "PRR_1",
        }
        original = pending_review(comments=[review_comment(body="old body")])
        updated = pending_review(comments=[review_comment(body="new body")])
        args = argparse.Namespace(
            input="review.json", repo="base/repo", pr="7", apply=True
        )
        client = mock.Mock()
        client.graphql.return_value = {
            "data": {
                "updatePullRequestReviewComment": {
                    "pullRequestReviewComment": {"id": "PRRC_1"}
                }
            }
        }
        with (
            mock.patch.object(review_draft, "read_json_input", return_value=data),
            mock.patch.object(
                review_draft,
                "resolve_target",
                return_value=_github.Target("base/repo", 7),
            ),
            mock.patch.object(
                review_draft,
                "fetch_review_context",
                side_effect=[
                    (pull_request(), [original]),
                    (pull_request(), [original]),
                    (pull_request(), [updated]),
                ],
            ),
            mock.patch.object(review_draft, "current_actor", return_value="viewer"),
            mock.patch.object(
                review_draft,
                "fetch_diff_files",
                return_value={"src/example.py": {"patch": PATCH}},
            ) as fetch_diff_files,
            mock.patch.object(
                review_draft,
                "fetch_review_comments_with_sides",
                side_effect=[
                    original["comments"],
                    original["comments"],
                    updated["comments"],
                ],
            ),
            mock.patch.object(
                review_draft,
                "pull_request_oids",
                return_value={"base_sha": "b" * 40, "head_sha": HEAD_SHA},
            ),
        ):
            result = review_draft.update(args, client)

        self.assertTrue(result["applied"])
        self.assertEqual(fetch_diff_files.call_count, 2)
        client.graphql.assert_called_once()
        self.assertTrue(result["mutation"]["complete"])
        self.assertEqual(result["verification"]["status"], "verified")

    def test_create_reports_applied_but_unverified_for_missing_side(self) -> None:
        body = f"{review_draft.MARKER}\ncontext"
        data = {
            "expected_head_sha": HEAD_SHA,
            "body": body,
            "comments": [
                {
                    "path": "src/example.py",
                    "line": 10,
                    "side": "RIGHT",
                    "body": "defect",
                }
            ],
        }
        created = pending_review(
            body=body,
            comments=[review_comment(body="defect", side="RIGHT")],
        )
        unprovable = review_comment(body="defect", side="RIGHT")
        unprovable["diffSide"] = None
        unprovable["position"] = 4
        args = argparse.Namespace(
            input="review.json", repo="base/repo", pr="7", apply=True
        )
        client = RecordingClient({"node_id": "PRR_1"})
        with (
            mock.patch.object(review_draft, "read_json_input", return_value=data),
            mock.patch.object(
                review_draft,
                "resolve_target",
                return_value=_github.Target("base/repo", 7),
            ),
            mock.patch.object(
                review_draft,
                "fetch_review_context",
                side_effect=[
                    (pull_request(), []),
                    (pull_request(), []),
                    (pull_request(), [created]),
                ],
            ),
            mock.patch.object(review_draft, "current_actor", return_value="viewer"),
            mock.patch.object(
                review_draft,
                "fetch_diff_files",
                return_value={"src/example.py": {"patch": PATCH}},
            ),
            mock.patch.object(
                review_draft,
                "pull_request_oids",
                return_value={"base_sha": "b" * 40, "head_sha": HEAD_SHA},
            ),
            mock.patch.object(
                review_draft,
                "fetch_review_comments_with_sides",
                return_value=[unprovable],
            ),
        ):
            result = review_draft.create(args, client)

        self.assertTrue(result["applied"])
        self.assertEqual(result["review_node_id"], "PRR_1")
        self.assertEqual(result["verification"]["status"], "unverified")
        self.assertIn("anchor/body", result["verification"]["detail"])

    def test_update_reports_completed_write_when_readback_fails(self) -> None:
        data = {
            "expected_head_sha": HEAD_SHA,
            "body": f"{review_draft.MARKER}\nnew context",
            "review_id": "PRR_1",
        }
        original = pending_review(body=f"{review_draft.MARKER}\nold context")
        args = argparse.Namespace(
            input="review.json", repo="base/repo", pr="7", apply=True
        )
        client = mock.Mock()
        client.graphql.return_value = {
            "data": {"updatePullRequestReview": {"pullRequestReview": {"id": "PRR_1"}}}
        }
        with (
            mock.patch.object(review_draft, "read_json_input", return_value=data),
            mock.patch.object(
                review_draft,
                "resolve_target",
                return_value=_github.Target("base/repo", 7),
            ),
            mock.patch.object(
                review_draft,
                "fetch_review_context",
                side_effect=[
                    (pull_request(), [original]),
                    (pull_request(), [original]),
                    _github.ToolkitError("readback unavailable"),
                ],
            ),
            mock.patch.object(review_draft, "current_actor", return_value="viewer"),
            mock.patch.object(
                review_draft,
                "pull_request_oids",
                return_value={"base_sha": "b" * 40, "head_sha": HEAD_SHA},
            ),
        ):
            result = review_draft.update(args, client)

        self.assertTrue(result["applied"])
        self.assertTrue(result["mutation"]["complete"])
        self.assertEqual(result["verification"]["status"], "unverified")

    def test_update_reports_partial_operations_without_retrying_first(self) -> None:
        data = {
            "expected_head_sha": HEAD_SHA,
            "body": f"{review_draft.MARKER}\nnew context",
            "comments": [{"id": "PRRC_1", "body": "new body"}],
            "review_id": "PRR_1",
        }
        original = pending_review(
            body=f"{review_draft.MARKER}\nold context",
            comments=[review_comment(body="old body")],
        )
        args = argparse.Namespace(
            input="review.json", repo="base/repo", pr="7", apply=True
        )
        client = mock.Mock()
        client.graphql.side_effect = [
            {
                "data": {
                    "updatePullRequestReview": {"pullRequestReview": {"id": "PRR_1"}}
                }
            },
            _github.ToolkitError("second mutation unavailable"),
        ]
        with (
            mock.patch.object(review_draft, "read_json_input", return_value=data),
            mock.patch.object(
                review_draft,
                "resolve_target",
                return_value=_github.Target("base/repo", 7),
            ),
            mock.patch.object(
                review_draft,
                "fetch_review_context",
                side_effect=[
                    (pull_request(), [original]),
                    (pull_request(), [original]),
                ],
            ),
            mock.patch.object(review_draft, "current_actor", return_value="viewer"),
            mock.patch.object(
                review_draft,
                "fetch_diff_files",
                return_value={"src/example.py": {"patch": PATCH}},
            ),
            mock.patch.object(
                review_draft,
                "fetch_review_comments_with_sides",
                side_effect=[original["comments"], original["comments"]],
            ),
            mock.patch.object(
                review_draft,
                "pull_request_oids",
                return_value={"base_sha": "b" * 40, "head_sha": HEAD_SHA},
            ),
        ):
            result = review_draft.update(args, client)

        self.assertTrue(result["applied"])
        self.assertFalse(result["mutation"]["complete"])
        self.assertEqual(len(result["mutation"]["applied_operations"]), 1)
        self.assertEqual(result["verification"]["status"], "partial")

    def test_update_apply_rechecks_head_before_mutation(self) -> None:
        data = {
            "expected_head_sha": HEAD_SHA,
            "body": f"{review_draft.MARKER}\nnew context",
            "review_id": "PRR_1",
        }
        review = pending_review(body=f"{review_draft.MARKER}\nold context")
        stale_pull_request = pull_request()
        stale_pull_request["head_sha"] = "b" * 40
        args = argparse.Namespace(
            input="review.json", repo="base/repo", pr="7", apply=True
        )
        client = RecordingClient()
        with (
            mock.patch.object(review_draft, "read_json_input", return_value=data),
            mock.patch.object(
                review_draft,
                "resolve_target",
                return_value=_github.Target("base/repo", 7),
            ),
            mock.patch.object(
                review_draft,
                "fetch_review_context",
                side_effect=[
                    (pull_request(), [review]),
                    (stale_pull_request, [review]),
                ],
            ),
            mock.patch.object(review_draft, "current_actor", return_value="viewer"),
            self.assertRaises(_github.InputError),
        ):
            review_draft.update(args, client)

        self.assertEqual(client.graphql_calls, [])

    def test_unknown_event_field_is_always_rejected(self) -> None:
        with self.assertRaisesRegex(_github.InputError, "cannot submit"):
            review_draft._only_keys({"event": "APPROVE"}, set(), "input")


class ReviewReconcileTests(unittest.TestCase):
    def desired_comment(
        self,
        key: str,
        body: str = "issue (blocking): defect",
        *,
        line: int = 10,
        side: str = "RIGHT",
    ) -> dict[str, object]:
        return review_reconcile.normalize_desired_comments(
            [
                {
                    "body": body,
                    "key": key,
                    "line": line,
                    "path": "src/example.py",
                    "side": side,
                }
            ]
        )[0]

    def managed_comment(
        self,
        key: str,
        body: str = "issue (blocking): defect",
        *,
        identifier: str = "PRRC_1",
        line: int = 10,
        side: str = "RIGHT",
    ) -> dict[str, object]:
        return review_comment(
            identifier=identifier,
            body=review_reconcile.render_comment_body(body, key),
            line=line,
            side=side,
        )

    def test_cli_exposes_reconcile_without_submission_event(self) -> None:
        args = review_draft.parse_args(
            [
                "reconcile",
                "--repo",
                "base/repo",
                "--pr",
                "7",
                "--input",
                "review.json",
            ]
        )

        self.assertEqual(args.command, "reconcile")
        self.assertFalse(args.apply)
        self.assertFalse(hasattr(args, "event"))

    def test_normalize_allows_body_only_and_rejects_duplicate_keys(self) -> None:
        normalized = review_reconcile.normalize_input(
            {
                "body": f"{review_draft.MARKER}\nNo issues found.",
                "expected_head_sha": HEAD_SHA,
            },
            pull_request(),
        )
        self.assertEqual(normalized["comments"], [])

        comment = {
            "body": "defect",
            "key": "same-key",
            "line": 10,
            "path": "src/example.py",
            "side": "RIGHT",
        }
        with self.assertRaisesRegex(_github.InputError, "duplicate"):
            review_reconcile.normalize_desired_comments([comment, comment])

    def test_historical_marked_review_does_not_block_new_cycle(self) -> None:
        submitted = pending_review(body=review_draft.MARKER)
        submitted["state"] = "COMMENTED"

        selected = review_reconcile.select_managed_pending_review([submitted], "viewer")

        self.assertIsNone(selected)

    def test_foreign_marked_pending_review_is_rejected(self) -> None:
        review = pending_review(body=review_draft.MARKER)
        review["author"] = {"login": "other"}

        with self.assertRaisesRegex(_github.InputError, "another actor"):
            review_reconcile.select_managed_pending_review([review], "viewer")

    def test_plan_create_supports_body_only_review(self) -> None:
        desired = {
            "body": f"{review_draft.MARKER}\nNo issues found.",
            "comments": [],
            "expected_head_sha": HEAD_SHA,
        }

        plan = review_reconcile.plan_create_review(pull_request(), "viewer", desired)

        self.assertEqual(plan["action"], "create")
        self.assertNotIn("comments", plan["payload"])

    def test_plan_reconciles_full_managed_comment_lifecycle(self) -> None:
        exact = self.managed_comment("keep", identifier="PRRC_KEEP")
        update = self.managed_comment("update", "old body", identifier="PRRC_UPDATE")
        move = self.managed_comment(
            "move", identifier="PRRC_MOVE", line=21, side="LEFT"
        )
        remove = self.managed_comment("remove", identifier="PRRC_REMOVE")
        unmanaged = review_comment(identifier="PRRC_USER", body="user-authored", line=9)
        review = pending_review(
            body=f"{review_draft.MARKER}\nold context",
            comments=[exact, update, move, remove, unmanaged],
        )
        desired = {
            "body": f"{review_draft.MARKER}\nnew context",
            "comments": [
                self.desired_comment("keep"),
                self.desired_comment("update", "new body"),
                self.desired_comment("move"),
                self.desired_comment("add"),
            ],
            "expected_head_sha": HEAD_SHA,
        }

        plan = review_reconcile.plan_existing_review(
            pull_request(), review, "viewer", desired
        )

        types = [operation["type"] for operation in plan["operations"]]
        self.assertEqual(
            types,
            [
                "update_review",
                "add_comment",
                "add_comment",
                "update_comment",
                "delete_comment",
                "delete_comment",
            ],
        )
        self.assertEqual(plan["preserved_unmanaged_comments"], 1)
        self.assertLess(types.index("add_comment"), types.index("delete_comment"))

    def test_partial_replacement_converges_to_delete_old_anchor(self) -> None:
        old = self.managed_comment("move", identifier="PRRC_OLD", line=21, side="LEFT")
        replacement = self.managed_comment("move", identifier="PRRC_NEW")
        review = pending_review(comments=[old, replacement])
        desired = {
            "body": review_draft.MARKER,
            "comments": [self.desired_comment("move")],
            "expected_head_sha": HEAD_SHA,
        }

        plan = review_reconcile.plan_existing_review(
            pull_request(), review, "viewer", desired
        )

        self.assertEqual(
            plan["operations"],
            [{"id": "PRRC_OLD", "key": "move", "type": "delete_comment"}],
        )

    def test_plan_adopts_one_legacy_comment_at_desired_anchor(self) -> None:
        legacy = review_comment(identifier="PRRC_LEGACY", body="same finding")
        review = pending_review(comments=[legacy])
        desired = {
            "body": review_draft.MARKER,
            "comments": [self.desired_comment("adopt", "same finding")],
            "expected_head_sha": HEAD_SHA,
        }

        plan = review_reconcile.plan_existing_review(
            pull_request(), review, "viewer", desired
        )

        self.assertEqual(plan["operations"][0]["type"], "update_comment")
        self.assertEqual(plan["operations"][0]["id"], "PRRC_LEGACY")
        self.assertEqual(plan["preserved_unmanaged_comments"], 0)

    def test_plan_preserves_different_unkeyed_comment_at_desired_anchor(self) -> None:
        manual = review_comment(identifier="PRRC_MANUAL", body="manual comment")
        review = pending_review(comments=[manual])
        desired = {
            "body": review_draft.MARKER,
            "comments": [self.desired_comment("safe", "different finding")],
            "expected_head_sha": HEAD_SHA,
        }

        plan = review_reconcile.plan_existing_review(
            pull_request(), review, "viewer", desired
        )

        self.assertEqual(plan["operations"][0]["type"], "add_comment")
        self.assertEqual(plan["preserved_unmanaged_comments"], 1)

    def test_apply_orders_add_before_delete_and_records_receipts(self) -> None:
        desired = {
            "body": review_draft.MARKER,
            "comments": [self.desired_comment("move")],
            "expected_head_sha": HEAD_SHA,
        }
        plan = {
            "action": "update",
            "actor": "viewer",
            "applied": False,
            "desired": desired,
            "operations": [
                {
                    **review_reconcile.operation_comment(desired["comments"][0]),
                    "type": "add_comment",
                },
                {"id": "PRRC_OLD", "key": "move", "type": "delete_comment"},
            ],
            "pull_request": pull_request(),
            "review": {"id": "PRR_1"},
        }
        client = mock.Mock()
        with (
            mock.patch.object(review_draft, "verify_current_oids"),
            mock.patch.object(
                review_reconcile,
                "apply_operation",
                side_effect=[
                    {"id": "PRRC_NEW", "key": "move", "type": "add_comment"},
                    {"id": "PRRC_OLD", "key": "move", "type": "delete_comment"},
                ],
            ) as apply_operation,
            mock.patch.object(
                review_reconcile,
                "verify_desired_state",
                return_value={"id": "PRR_1"},
            ),
        ):
            result = review_reconcile.apply_plan(
                client, _github.Target("base/repo", 7), plan
            )

        self.assertEqual(
            [call.args[2]["type"] for call in apply_operation.call_args_list],
            ["add_comment", "delete_comment"],
        )
        self.assertTrue(result["mutation"]["complete"])
        self.assertEqual(result["verification"]["status"], "verified")

    def test_ambiguous_add_failure_records_attempt_for_safe_reconcile(self) -> None:
        desired = {
            "body": review_draft.MARKER,
            "comments": [self.desired_comment("add")],
            "expected_head_sha": HEAD_SHA,
        }
        operation = {
            **review_reconcile.operation_comment(desired["comments"][0]),
            "type": "add_comment",
        }
        plan = {
            "action": "update",
            "actor": "viewer",
            "applied": False,
            "desired": desired,
            "operations": [operation],
            "pull_request": pull_request(),
            "review": {"id": "PRR_1"},
        }
        with (
            mock.patch.object(review_draft, "verify_current_oids"),
            mock.patch.object(
                review_reconcile,
                "apply_operation",
                side_effect=_github.ToolkitError("connection reset"),
            ),
        ):
            result = review_reconcile.apply_plan(
                mock.Mock(), _github.Target("base/repo", 7), plan
            )

        self.assertFalse(result["applied"])
        self.assertEqual(
            result["mutation"]["attempted_operations"],
            [{"key": "add", "type": "add_comment"}],
        )
        self.assertEqual(result["verification"]["status"], "unverified")

    def test_update_response_validator_rejects_wrong_identity(self) -> None:
        with self.assertRaisesRegex(_github.ToolkitError, "wrong"):
            review_draft.validate_mutation_id(
                {
                    "data": {
                        "updatePullRequestReviewComment": {
                            "pullRequestReviewComment": {"id": "PRRC_OTHER"}
                        }
                    }
                },
                "updatePullRequestReviewComment",
                "pullRequestReviewComment",
                "PRRC_EXPECTED",
            )

    def test_verify_desired_state_rejects_wrong_diff_side(self) -> None:
        desired_comment = self.desired_comment("side")
        actual = self.managed_comment("side", side="LEFT")
        review = pending_review(comments=[actual])
        desired = {
            "body": review_draft.MARKER,
            "comments": [desired_comment],
            "expected_head_sha": HEAD_SHA,
        }
        client = mock.Mock()
        with (
            mock.patch.object(
                review_draft,
                "pull_request_oids",
                return_value={"base_sha": "b" * 40, "head_sha": HEAD_SHA},
            ),
            mock.patch.object(
                review_draft,
                "fetch_review_context",
                return_value=(pull_request(), [review]),
            ),
            mock.patch.object(
                review_draft,
                "fetch_review_comments_with_sides",
                return_value=[actual],
            ),
            self.assertRaisesRegex(_github.ToolkitError, "side"),
        ):
            review_reconcile.verify_desired_state(
                client,
                _github.Target("base/repo", 7),
                "viewer",
                desired,
                "b" * 40,
            )

    def test_build_plan_rejects_draft_pull_request(self) -> None:
        draft = pull_request()
        draft["is_draft"] = True
        with (
            mock.patch.object(
                review_draft, "fetch_review_context", return_value=(draft, [])
            ),
            self.assertRaisesRegex(_github.InputError, "draft"),
        ):
            review_reconcile.build_plan(
                mock.Mock(),
                _github.Target("base/repo", 7),
                {
                    "body": review_draft.MARKER,
                    "expected_head_sha": HEAD_SHA,
                },
            )


class ReviewThreadTests(unittest.TestCase):
    def test_stale_head_rejects_reply_before_mutation(self) -> None:
        args = argparse.Namespace(
            repo="base/repo",
            pr="7",
            thread="PRRT_1",
            expected_head_sha="b" * 40,
            body="reply",
            body_file=None,
            apply=True,
        )
        client = RecordingClient()
        with (
            mock.patch.object(
                review_threads,
                "resolve_target",
                return_value=_github.Target("base/repo", 7),
            ),
            mock.patch.object(
                review_threads,
                "fetch_threads",
                return_value=(pull_request(), []),
            ),
            self.assertRaises(_github.InputError),
        ):
            review_threads.reply(args, client)

        self.assertEqual(client.graphql_calls, [])
        self.assertEqual(client.json_calls, [])

    def test_reply_rechecks_head_after_thread_refresh(self) -> None:
        args = argparse.Namespace(
            repo="base/repo",
            pr="7",
            thread="PRRT_1",
            expected_head_sha=HEAD_SHA,
            body="reply",
            body_file=None,
            apply=True,
        )
        thread = {
            "id": "PRRT_1",
            "isResolved": False,
            "isOutdated": False,
            "path": "src/example.py",
            "line": 10,
            "comments": [],
        }
        client = RecordingClient()
        with (
            mock.patch.object(
                review_threads,
                "resolve_target",
                return_value=_github.Target("base/repo", 7),
            ),
            mock.patch.object(
                review_threads,
                "fetch_threads",
                side_effect=[
                    (pull_request(), [thread]),
                    (pull_request(), [thread]),
                ],
            ),
            mock.patch.object(
                review_threads,
                "pull_request_oids",
                return_value={"base_sha": "b" * 40, "head_sha": "c" * 40},
            ),
            self.assertRaises(_github.InputError),
        ):
            review_threads.reply(args, client)

        self.assertEqual(client.graphql_calls, [])

    def test_default_body_filter_emits_preview_not_full_body(self) -> None:
        thread = {
            "id": "PRRT_1",
            "isResolved": False,
            "isOutdated": False,
            "path": "src/example.py",
            "line": 10,
            "comments": [
                {
                    "id": "PRRC_1",
                    "body": "abcdefghij",
                    "author": {"login": "reviewer"},
                }
            ],
        }
        normalized = review_threads.normalize_thread(thread, False, 4)
        comment = normalized["comments"][0]
        self.assertEqual(comment["body_preview"], "abcd")
        self.assertTrue(comment["body_truncated"])
        self.assertNotIn("body", comment)

    def test_reply_preserves_applied_truth_when_readback_fails(self) -> None:
        args = argparse.Namespace(
            repo="base/repo",
            pr="7",
            thread="PRRT_1",
            expected_head_sha=HEAD_SHA,
            body="reply",
            body_file=None,
            apply=True,
        )
        thread = {
            "id": "PRRT_1",
            "isResolved": False,
            "isOutdated": False,
            "path": "src/example.py",
            "line": 10,
            "comments": [],
        }
        client = mock.Mock()
        client.graphql.return_value = {
            "data": {"addPullRequestReviewThreadReply": {"comment": {"id": "PRRC_2"}}}
        }
        with (
            mock.patch.object(
                review_threads,
                "resolve_target",
                return_value=_github.Target("base/repo", 7),
            ),
            mock.patch.object(
                review_threads,
                "fetch_threads",
                side_effect=[
                    (pull_request(), [thread]),
                    (pull_request(), [thread]),
                    _github.ToolkitError("readback unavailable"),
                ],
            ),
            mock.patch.object(
                review_threads,
                "pull_request_oids",
                return_value={"base_sha": "b" * 40, "head_sha": HEAD_SHA},
            ),
        ):
            result = review_threads.reply(args, client)

        self.assertTrue(result["applied"])
        self.assertEqual(result["created_comment"]["id"], "PRRC_2")
        self.assertEqual(result["verification"]["status"], "unverified")

    def test_resolve_preserves_applied_truth_when_readback_fails(self) -> None:
        args = argparse.Namespace(
            repo="base/repo",
            pr="7",
            thread="PRRT_1",
            expected_head_sha=HEAD_SHA,
            apply=True,
        )
        thread = {
            "id": "PRRT_1",
            "isResolved": False,
            "isOutdated": False,
            "path": "src/example.py",
            "line": 10,
            "comments": [],
        }
        client = mock.Mock()
        client.graphql.return_value = {
            "data": {"resolveReviewThread": {"thread": {"isResolved": True}}}
        }
        with (
            mock.patch.object(
                review_threads,
                "resolve_target",
                return_value=_github.Target("base/repo", 7),
            ),
            mock.patch.object(
                review_threads,
                "fetch_threads",
                side_effect=[
                    (pull_request(), [thread]),
                    (pull_request(), [thread]),
                    _github.ToolkitError("readback unavailable"),
                ],
            ),
            mock.patch.object(
                review_threads,
                "pull_request_oids",
                return_value={"base_sha": "b" * 40, "head_sha": HEAD_SHA},
            ),
        ):
            result = review_threads.resolve(args, client)

        self.assertTrue(result["applied"])
        self.assertEqual(result["verification"]["status"], "unverified")


if __name__ == "__main__":
    unittest.main()
