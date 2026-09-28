from __future__ import annotations

import unittest

from support import GateCase


class CommandTests(GateCase):
    def test_reads_dry_runs_and_local_work_pass(self) -> None:
        for command in (
            "gh pr view 12 --json title",
            "gh api repos/o/r/pulls/12/comments --paginate",
            "gh api search/issues -f q='repo:o/r is:open'",
            "gh api graphql -f query='query($o: String!) { repository(owner: $o, name: \"r\") { id } }' -f o=x",
            "gh api -X POST repos/o/r/actions/runs/1/rerun",
            "gh pr create --dry-run --title x --body y",
            "git push --dry-run origin HEAD",
            "git commit -m 'fix(x): y'",
            "rg -n 'gh pr comment' modules/",
            "echo 'git push origin main'",
            "python3 review_threads.py reply --repo o/r --pr 1 --thread T --expected-head-sha abc --body hi",
            "nixos-rebuild build --flake .#host",
            "nh os build .",
        ):
            with self.subTest(command=command):
                self.assert_allowed(command)

    def test_leading_gh_flags_and_variable_bodies_are_checked(self) -> None:
        self.say("investigate the failure")
        for command in (
            "gh --repo o/r pr comment 12 --body hi",
            "gh -R o/r pr merge 3 --squash",
            "gh --repo=o/r pr review 3 --approve",
        ):
            with self.subTest(command=command):
                self.assert_denied(command)
        self.say("post the reply")
        self.assert_denied(
            'body="Tested with Claude Code"; gh pr comment 12 --body "$body"',
            "prose rules",
        )
        self.assert_allowed('body="Fixed in abc123."; gh pr comment 12 --body "$body"')

    def test_continued_and_compound_commands_are_checked(self) -> None:
        self.say("open a PR for this")
        self.assert_denied(
            "gh pr create \\\n  --title 'fix: x' \\\n"
            "  --body 'Tested with Claude Code, all green.'",
            "prose rules",
        )
        self.say("never mind the PR, investigate the flaky test")
        for command in (
            "git \\\n  push origin main",
            "for b in a b; do git push origin $b; done",
            "if git push origin fix; then echo ok; fi",
            'while read pr; do gh pr merge "$pr" --squash; done < prs.txt',
            "{ git push; }",
            "! git push origin fix",
        ):
            with self.subTest(command=command):
                self.assert_denied(command)
        for command in (
            "for f in *.nix; do nixfmt $f; done",
            "if [ -f flake.nix ]; then echo yes; fi",
        ):
            with self.subTest(command=command):
                self.assert_allowed(command)

    def test_scripts_run_by_path_are_read(self) -> None:
        (self.work / "release.sh").write_text("#!/bin/sh\ngit push origin main\n")
        (self.work / "build.sh").write_text("#!/bin/sh\nnix build .#tests\n")
        self.say("run the release script")
        self.assert_denied("bash ./release.sh", "push")
        self.assert_denied("./release.sh", "push")
        self.assert_allowed("bash ./build.sh")

    def test_graphql_query_files_and_dry_runs(self) -> None:
        (self.work / "resolve.graphql").write_text(
            'mutation { resolveReviewThread(input: {threadId: "T"}) { clientMutationId } }'
        )
        (self.work / "read.graphql").write_text("query { viewer { login } }")
        self.say("investigate the review threads")
        self.assert_denied(
            'gh api graphql -f query="$(cat resolve.graphql)"', "publish"
        )
        self.assert_allowed('gh api graphql -f query="$(cat read.graphql)"')
        self.assert_denied(
            'gh api graphql -f query="$(cat missing.graphql)"', "publish"
        )
        for command in (
            "nh os switch . --dry",
            "home-manager switch -n --flake .",
            "nixos-rebuild switch --dry-run --flake .#host",
        ):
            with self.subTest(command=command):
                self.assert_allowed(command)

    def test_help_and_quoted_text_are_not_actions(self) -> None:
        for command in (
            "nh os switch --help | sed -n '1,40p'",
            "gh stack link --help",
            "git push -h",
            "jj describe -m 'refresh vars. Run `home-manager switch` to apply; see $(man bash).'",
            "gh api -X OPTIONS repos/o/r/stacks/1",
        ):
            with self.subTest(command=command):
                self.assert_allowed(command)

    def test_implicit_post_reads_get_a_hint(self) -> None:
        reason = self.assert_denied(
            "gh api repos/o/r/contents/a.nix -f ref=abc --jq .content"
        )
        self.assertIn("add -X GET", reason)

    def test_file_content_in_nested_heredocs_is_not_a_command(self) -> None:
        command = (
            "bash -c 'apply_patch <<'\"'\"'PATCH'\"'\"'\n*** Begin Patch\n*** Add File: report.md\n"
            "+Next: git push origin main, then gh pr create --fill.\n*** End Patch\nPATCH'"
        )
        self.assert_allowed(command)
        self.assert_allowed(
            "cat > notes.md <<'EOF'\ngh pr merge 5\ngit push --force\nEOF"
        )

    def test_wrapped_and_nested_writes_are_found(self) -> None:
        for command in (
            "cd repo && gh pr comment 1 --body hi",
            "bash -lc 'gh issue comment 3 --body hi'",
            "env GH_TOKEN=x gh pr edit 1 --title new",
            "/nix/store/abc-gh-2.80/bin/gh pr ready 4",
            'echo "$(gh pr comment 1 --body hi)"',
            "git -C ../other push origin main",
            "jj git push --bookmark fix",
            "nix run nixpkgs#nixpkgs-review -- pr 1234 --post-result",
            "gh api repos/o/r/issues/1/comments -f body=hi",
            'gh api graphql -f query=\'mutation { addComment(input: {subjectId: "I", body: "hi"}) { clientMutationId } }\'',
            "sudo nixos-rebuild switch --flake .#host",
            "nh home switch .",
        ):
            with self.subTest(command=command):
                self.assert_denied(command)

    def test_thread_reply_publish_flag_needs_publish(self) -> None:
        self.say("add a pending reply on that thread")
        base = "python3 /s/review_threads.py reply --repo o/r --pr 1 --thread T --expected-head-sha a --body 'Good catch.' --apply"
        self.assert_allowed(base)
        self.assert_denied(base + " --publish", "publish to GitHub")


if __name__ == "__main__":
    unittest.main()
