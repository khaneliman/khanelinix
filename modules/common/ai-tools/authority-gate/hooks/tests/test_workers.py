from __future__ import annotations

import unittest

from support import GateCase


class WorkerBoundaryTests(GateCase):
    def test_workers_cannot_publish_or_change_history(self) -> None:
        self.say("create the PR and push")
        for command in (
            "gh pr comment 1 --body hi",
            "git push origin fix",
            "git commit -m 'fix(x): y'",
            "git stash",
            "git checkout -- file.nix",
            "git reset --hard HEAD~1",
            "jj squash --into @-",
            "jj git push",
            "for pr in 1 2; do gh pr comment $pr --body x; done",
            "nh os switch .",
        ):
            with self.subTest(command=command):
                self.assert_denied(
                    command, "Workers", agent_id="child", agent_type="implementer"
                )

    def test_workers_keep_read_only_git(self) -> None:
        for command in (
            "git status --short",
            "git diff HEAD~1",
            "git stash list",
            "git log --oneline -5",
            "jj log -r @",
            "git worktree add ../scratch HEAD",
            "gh pr view 1",
        ):
            with self.subTest(command=command):
                self.assertIsNone(self.run_tool(command, agent_id="child"), command)


if __name__ == "__main__":
    unittest.main()
