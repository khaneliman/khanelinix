from __future__ import annotations

import unittest

from support import grants, intent


class PromptIntentTests(unittest.TestCase):
    """Phrasings come from the user's own recent prompts."""

    def granted(self, text: str) -> set[str]:
        return intent(text)[0]

    def test_requests_grant_the_matching_action(self) -> None:
        cases = {
            "commit and push to main": {grants.PUSH},
            "Then push commit": {grants.PUSH},
            "push it": {grants.PUSH},
            "Yes, create my own version of the PR please.": {
                grants.PUBLISH,
                grants.PUSH,
            },
            "please create a branch/commit/pr": {grants.PUBLISH, grants.PUSH},
            "alright, force push and create draft PR's": {
                grants.FORCE_PUSH,
                grants.PUSH,
                grants.PUBLISH,
            },
            "lets close and delete font config pr. then fix the others and push "
            "updated branches to the pr": {grants.PUBLISH, grants.DELETE, grants.PUSH},
            "merge #9927 once CI is green": {grants.MERGE},
            "post a draft PR for this": {grants.PUBLISH},
            "publish the draft PR": {grants.PUBLISH},
            "submit a draft PR": {grants.PUBLISH, grants.PUSH},
            "post the review": {grants.PUBLISH},
            "Alright, I think we can merge this and update the tracker": {grants.MERGE},
            "alright, we can resolve the threads and merge": {
                grants.PUBLISH,
                grants.MERGE,
            },
            "Alright, we can rebase merge that then rebase all the dependent PR's": {
                grants.MERGE
            },
            "can we `nh os switch` and make sure it works": {grants.ACTIVATE},
            "Update my local overlay and switch configuration": {grants.ACTIVATE},
            "Then activate new system config so harnesses get the new instructions": {
                grants.ACTIVATE
            },
            "approve it": {grants.APPROVE},
        }
        for text, expected in cases.items():
            with self.subTest(text=text):
                self.assertEqual(self.granted(text), expected)

    def test_pending_review_requests_stay_drafts(self) -> None:
        cases = (
            "alright. lets post a pending review that i can review/edit in the UI before submitting.",
            "can you post a inline code suggestion review about the findings. leave pending, i'll submit",
            "can we submit a pending review with a code suggestion",
            "For fast follow ups can we post a pending review for each",
        )
        for text in cases:
            with self.subTest(text=text):
                granted = self.granted(text)
                self.assertIn(grants.REVIEW_DRAFT, granted)
                self.assertNotIn(grants.PUBLISH, granted)

    def test_negations_and_status_questions_do_not_grant(self) -> None:
        cases = {
            "Let's add it locally, but don't push. i'd like to review it afterwards": grants.PUSH,
            "are both of them review/merge ready?": grants.MERGE,
            "can we double check if the PR is ready to merge now": grants.MERGE,
            "resolve the merge conflicts in flake.lock": grants.MERGE,
            "make sure the PR description matches the template": grants.PUBLISH,
            "draft the PR description locally so I can edit it": grants.PUBLISH,
            "what does the post-merge hook do?": grants.PUBLISH,
            "fix the failing test": grants.PUBLISH,
        }
        for text, key in cases.items():
            with self.subTest(text=text):
                self.assertNotIn(key, self.granted(text))

    def test_questions_complaints_and_mentions_do_not_grant(self) -> None:
        for text in (
            "Why did you push that branch?",
            "Do not publish anything. Review the merge logic.",
            "Can you explain how to publish a release?",
            "did you merge it?",
            "should we push this?",
            "the push failed with a 403",
            "I read the blog post about merging",
            "merge the two helper functions",
            "switch the default shell to fish",
            "rebuild and tell me if it evaluates",
            "git switch main then run the tests",
            "run nixos-rebuild build to check it evaluates",
            "the publish job fails on CI; fix it",
            "submit the form values through the test harness",
        ):
            with self.subTest(text=text):
                self.assertEqual(self.granted(text), set())

    def test_negated_action_is_revoked(self) -> None:
        granted, revoked = intent("create the PR without pushing")
        self.assertIn(grants.PUBLISH, granted)
        self.assertNotIn(grants.PUSH, granted)
        self.assertIn(grants.PUSH, revoked)


if __name__ == "__main__":
    unittest.main()
