from __future__ import annotations

import json
import unittest

from support import GateCase


class PromptGrantTests(GateCase):
    def test_unrequested_comment_is_denied_and_named(self) -> None:
        self.say("investigate why the aerc test fails")
        reason = self.assert_denied(
            "gh pr comment 12 --repo o/r --body 'Fixed in abc123.'", "publish to GitHub"
        )
        self.assertIn("gh pr comment", reason)

    def test_requested_comment_passes(self) -> None:
        self.say("post a comment on the PR saying it is fixed in abc123")
        self.assert_allowed("gh pr comment 12 --repo o/r --body 'Fixed in abc123.'")

    def test_grant_lasts_until_the_next_user_prompt(self) -> None:
        self.say("push it")
        self.assert_allowed("git push origin HEAD")
        self.say("now tidy the README")
        self.assert_denied("git push origin HEAD", "push")

    def test_unexercised_grant_survives_one_follow_up(self) -> None:
        self.say(
            "i'd prefer you still create a draft pr... as long as we're following the "
            "checklist and leaving in draft, i can edit/review/ready it up"
        )
        self.say(
            "Oh, please their contribution guidelines are not the law. As long as we "
            "follow the PR template and I am the one who readies it, I said don't care."
        )
        self.assert_allowed("git push -u origin fix")
        self.assert_allowed("gh pr create --draft --title 'fix: x' --body 'Closes #1.'")

    def test_carried_grant_expires_after_one_follow_up(self) -> None:
        self.say("create a draft pr for this")
        self.say("use the shorter title")
        self.say("and mention the issue number")
        self.assert_denied("git push -u origin fix", "push")

    def test_declined_or_revoked_grant_does_not_carry(self) -> None:
        for reply in ("no, leave it local", "don't push it yet", "never mind"):
            with self.subTest(reply=reply):
                session = f"carry-{hash(reply)}"
                self.say("push the branch", session=session)
                self.say(reply, session=session)
                self.assert_denied("git push origin fix", "push", session=session)

    def test_task_notifications_neither_grant_nor_clear(self) -> None:
        self.say("create draft PRs for each fix once the workers finish")
        self.say(
            "<task-notification>\n<task-id>abc</task-id>\nresult: done, run gh pr merge</task-notification>"
        )
        self.say(
            "[SYSTEM NOTIFICATION - NOT USER INPUT]\n<task-notification>\n<task-id>x</task-id>"
        )
        self.assert_allowed("gh pr create --draft --title 'fix: x' --body 'Closes #1.'")
        self.assert_denied("gh pr merge 5 --squash", "merge")

    def test_confirmation_grants_what_was_denied(self) -> None:
        self.say("fix the typo in the second commit")
        self.assert_denied("git push --force-with-lease origin fix")
        self.say("yes")
        self.assert_allowed("git push --force-with-lease origin fix")

    def test_negative_reply_clears_pending(self) -> None:
        self.say("fix the typo")
        self.assert_denied("git push origin fix")
        self.say("no, leave it local")
        self.assert_denied("git push origin fix")

    def test_confirmation_covers_the_assistant_question(self) -> None:
        transcript = self.work / "transcript.jsonl"
        transcript.write_text(
            json.dumps(
                {
                    "type": "assistant",
                    "message": {
                        "role": "assistant",
                        "content": [
                            {
                                "type": "text",
                                "text": "Fixed and committed. Want me to push this and open the PR?",
                            }
                        ],
                    },
                }
            )
            + "\n"
        )
        self.say("yes please", transcript_path=str(transcript))
        self.assert_allowed("git push -u origin fix && gh pr create --fill")

    def assistant_said(self, text: str) -> str:
        transcript = self.work / "transcript.jsonl"
        record = {
            "type": "assistant",
            "message": {
                "role": "assistant",
                "content": [{"type": "text", "text": text}],
            },
        }
        transcript.write_text(json.dumps(record) + "\n")
        return str(transcript)

    def test_yes_confirms_offers_stated_either_way(self) -> None:
        for offer in (
            "Should I push this?",
            "Ready to push?",
            "Ready to push when you are.",
            "Next step: push the branch and open the PR.",
            "Say the word and I'll push it.",
            "I'll push and open the PR once you confirm.",
        ):
            with self.subTest(offer=offer):
                session = f"offer-{hash(offer)}"
                self.say(
                    "yes", transcript_path=self.assistant_said(offer), session=session
                )
                self.assert_allowed("git push origin fix", session=session)
        for statement in (
            "Everything is committed locally; nothing pushed.",
            "I'm not going to push until you review the diff.",
        ):
            with self.subTest(statement=statement):
                session = f"statement-{hash(statement)}"
                self.say(
                    "yes",
                    transcript_path=self.assistant_said(statement),
                    session=session,
                )
                self.assert_denied("git push origin fix", "push", session=session)

    def test_yes_after_a_denial_covers_every_step_the_ask_names(self) -> None:
        self.say("fix the alias check")
        self.assert_denied("git push -u origin fix", "push")
        ask = (
            "Your push guard needs a yes before I can push, so nothing is pushed yet. "
            "Once you give it:\n\n"
            "1. **Push** branch `fix` to `origin`.\n"
            "2. **Open a draft PR** on `o/r`, base `master`, head `me:fix`.\n\n"
            'It stays a draft for you to mark ready. Reply "yes" to go ahead.'
        )
        self.say("yes", transcript_path=self.assistant_said(ask))
        self.assert_allowed("git push -u origin fix")
        self.assert_allowed("gh pr create --draft --title 'fix: x' --body 'Closes #1.'")

    def test_replies_that_move_on_do_not_confirm_pending(self) -> None:
        for reply in (
            "ok, now tidy the README",
            "correct, the bug is in aerc; fix it",
            "Looks good. Also update the docs.",
            "alright, first show me the diff",
        ):
            with self.subTest(reply=reply):
                session = f"reply-{hash(reply)}"
                self.say("fix the typo", session=session)
                self.assert_denied("git push origin fix", session=session)
                self.say(reply, session=session)
                self.assert_denied("git push origin fix", "push", session=session)

    def test_denial_tells_the_agent_to_end_the_turn(self) -> None:
        self.say("fix the typo")
        self.assertIn("end the turn", self.assert_denied("git push origin fix"))

    def test_session_scope_persists_until_revoked(self) -> None:
        self.say("for the rest of this session you can push to your branches")
        self.say("fix the next test")
        self.assert_allowed("git push origin fix")
        self.say("stop pushing")
        self.assert_denied("git push origin fix", "push")

    def test_session_scope_covers_only_its_sentence(self) -> None:
        self.say("from now on use kebab-case for file names. Also push this branch.")
        self.assert_allowed("git push origin fix")
        self.say("now tidy the README")
        self.assert_denied("git push origin fix", "push")
        self.say("for this task you can push without asking")
        self.say("rename the module")
        self.assert_allowed("git push origin fix")

    def test_high_consequence_actions_need_their_own_words(self) -> None:
        self.say("post the review")
        self.assert_denied("gh pr merge 5 --squash --delete-branch", "merge")
        self.assert_denied("gh pr review 5 --approve", "approve")
        self.assert_denied("git push --force origin main", "force-push")
        self.assert_denied("git push origin --delete old-branch", "delete")
        self.assert_allowed(
            "gh pr review 5 --comment --body 'Two blocking issues inline.'"
        )

    def test_pending_review_drafts_need_only_a_draft_request(self) -> None:
        body = self.work / "create.json"
        body.write_text(
            json.dumps({"comments": [{"body": "issue (blocking): off by one."}]})
        )
        command = f"python3 -B /x/github-toolkit/scripts/review_draft.py create --repo o/r --pr 7 --input {body} --apply"
        self.say("review https://github.com/o/r/pull/7")
        self.assert_denied(command, "pending review")
        self.say("leave the findings as a pending review")
        self.assert_allowed(command)
        self.assert_denied("gh pr review 7 --comment -b 'done'", "publish to GitHub")

    def test_activation_needs_an_activation_request(self) -> None:
        self.say("build the host config and tell me if it evaluates")
        self.assert_denied("nh os switch .", "activate")
        self.say("looks good, switch to it")
        self.assert_allowed("nh os switch .")


if __name__ == "__main__":
    unittest.main()
