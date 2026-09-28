from __future__ import annotations

import os
import unittest
from unittest import mock

from support import GateCase, grants, hook


class LauncherGrantTests(GateCase):
    def test_launcher_grants_work_without_a_session(self) -> None:
        payload = {
            "tool_name": "Bash",
            "tool_input": {"command": "git push origin fix"},
        }
        with mock.patch.dict(os.environ, {grants.GRANTS_ENV: "push"}):
            self.assertIsNone(hook.handle("codex", "pre-tool", payload, self.root))
        self.assertIsNotNone(hook.handle("codex", "pre-tool", payload, self.root))

    def test_launcher_grants_allow_scheduled_work(self) -> None:
        with mock.patch.dict(os.environ, {grants.GRANTS_ENV: "publish, push"}):
            self.assert_allowed(
                "git push origin updates/vim && gh pr create --draft --fill"
            )
            self.assert_allowed("nixpkgs-review pr 12 --post-result")
            self.assert_denied("gh pr merge 12", "merge")

    def test_agents_pass_on_only_grants_they_hold(self) -> None:
        launch = (
            f"systemd-run --user --setenv={grants.GRANTS_ENV}=publish,push ./run.sh"
        )
        self.say("run the plugin update in the background")
        self.assert_denied(launch, "launched job")
        self.say("run the plugin update and open draft PRs with the results")
        self.assert_allowed(launch)
        self.assert_denied(f"{grants.GRANTS_ENV}=merge codex exec 'merge it'", "merge")
        self.assert_denied(f'export {grants.GRANTS_ENV}="$GRANTS"; ./run.sh', "literal")

    def test_file_writes_that_set_grants_are_checked(self) -> None:
        script = f"#!/usr/bin/env bash\nexport {grants.GRANTS_ENV}='publish push'\ncodex exec -"
        payload = {
            "session_id": "one",
            "tool_name": "Write",
            "tool_input": {"file_path": str(self.work / "run.sh"), "content": script},
        }
        self.say("prepare the update job")
        self.assertIsNotNone(hook.handle("claude", "pre-tool", payload, self.root))
        self.say("run the update job and create the PRs")
        self.assertIsNone(hook.handle("claude", "pre-tool", payload, self.root))
        plain = {**payload, "tool_input": {"file_path": "x", "content": "echo hi"}}
        self.assertIsNone(hook.handle("claude", "pre-tool", plain, self.root))


if __name__ == "__main__":
    unittest.main()
