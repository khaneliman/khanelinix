# Pull Request Babysitting

Use to keep watching an open pull request after it is posted and to respond to
new reviews, bot comments, and check results until it merges, closes, or the
user stops the watch. Each wake runs one pass. [pr-feedback.md](pr-feedback.md)
owns thread triage and reply mechanics, [ci-fix.md](ci-fix.md) owns check
diagnosis, and [Contributor Conversation](pr-review.md#contributor-conversation)
owns reply tone.

## Authority

Starting a watch authorizes these actions on every pass without asking again:

- read the pull request, its threads, comments, reviews, and checks
- edit and commit fixes locally on the PR branch, with focused validation
- add reply drafts to the current actor's pending review

Pushing, publishing a reply, resolving a thread, submitting the review,
rebasing, and merging each need a separate request. The user proofreads the
drafts and pushes the commits together, so no posted reply points at code that
reviewers cannot see yet.

## Start

1. Resolve the target and head SHA with `scripts/pr_snapshot.py`. Stop if the
   pull request is merged or closed.
2. Arm the host's wake mechanism from [Wake Mechanisms](#wake-mechanisms) before
   the first pass, so feedback posted during the pass still wakes you.
3. Run one pass over all existing feedback.

## Pass

1. Refresh the snapshot: head SHA, state, mergeability, and review decision.
   Commit only in a checkout on the PR head branch that contains the current
   remote head. If the remote moved ahead and the checkout is clean,
   fast-forward; otherwise report the divergence and make no commits.
2. Collect feedback you have not answered yet:
   - review threads from `scripts/review_threads.py inspect`
   - finished or failing checks from `scripts/inspect_pr_checks.py`
   - a merge conflict with the base branch
   - top-level comments and review summaries, with bodies trimmed so a long bot
     walkthrough does not flood context:

     ```bash
     gh pr view NUMBER --repo OWNER/REPO --json comments,reviews --jq '
       [(.comments[] | {kind: "comment", author: .author.login,
           at: .createdAt, url, body: .body[:240]}),
        (.reviews[] | select(.body != "") | {kind: "review",
           author: .author.login, at: .submittedAt, state,
           body: .body[:240]})] | sort_by(.at)'
     ```

   Use earlier pass reports and the pending review from
   `scripts/review_draft.py inspect` to skip items you already drafted for.
   Pending replies do not always appear in thread listings.

3. Sort every item into one bucket:
   - **Fix:** a verified defect or requested change within the PR's scope.
   - **Answer:** a question or a request for clarification.
   - **Decline:** a claim that the code, documentation, or a test shows to be
     wrong.
   - **Skip:** summaries, acknowledgments, duplicates, and bot output that needs
     no reply.

   Verify every bot and linter claim against the code before acting on it. Draft
   a reply to a bot only when its unresolved thread blocks merging, for example
   under required conversation resolution; list the other bot comments in the
   report. Ask the user instead of choosing when a fix needs a product decision,
   contradicts another reviewer, or grows past the PR's scope, and before
   resolving a merge conflict.

4. Implement each Fix with pr-feedback step 7 or ci-fix, then commit it locally
   under the repository's commit conventions.
5. Draft one reply per item that needs one:
   - **Fix:** say what changed. Leave out commit SHAs, since local commits can
     change before the user pushes.
   - **Answer:** answer the question directly.
   - **Decline:** give the evidence that settles it in a sentence or two.

   Add thread replies with `scripts/review_threads.py reply --apply` and no
   `--publish`. Put replies to top-level comments in the pending review summary
   with a link to each comment. That helper creates a pending review without a
   summary, and GitHub can reject a summary added later, so create the pending
   review with its summary through `scripts/review_draft.py create` before
   adding thread replies. If a summaryless pending review already exists,
   include the top-level reply in the report for the user to post.

6. Report what is new since the last report: commits made, drafts waiting in the
   pending review, skipped items, and decisions needed. Do not repeat a handoff
   that is still waiting on the user. End the turn and wait for the next wake.

## Handoff and Stop

Hand back to the user when a pass leaves drafts, local commits, or a decision
for them. Release any hold the host keeps on the session so it reaches the user,
and notify them when the host supports it. When the user returns after pushing
or submitting the review, re-arm the watch and run a pass.

Stop watching when the pull request merges or closes, when it is approved with
required checks passing and no unanswered feedback, or when the user says to
stop. After a merge, follow the closeout in [pr-merge.md](pr-merge.md).

## Wake Mechanisms

Use the host's own wake mechanism, listed below. Run one mechanism at a time; a
poll loop beside an event watcher answers the same feedback twice.

Leave built-in PR automation off for this mode unless the user asks for it. That
includes Claude Code cloud Auto-fix (`/autofix-pr`), Claude Desktop's "Auto-fix
CI & address comments", `@codex` or `@claude` mention workflows, and agent
GitHub Actions. These follow their own rules instead of this mode's. Cloud
Auto-fix, for example, pushes fixes and posts thread replies under the user's
account without a proofread.

### T3 Code

Call `watch_pull_request` from the `t3-code` MCP server. T3 checks every two
minutes and wakes the thread when a check fails, required checks pass, someone
else comments or reviews, or the branch conflicts. Only feedback posted after
the call wakes you, so arm first and then handle what already exists. Call
`unwatch_pull_request` before each handoff so the thread returns to the user's
inbox. The watch ends on its own at merge or close. A subagent cannot watch; its
parent thread owns the pull request.

### Claude Code, local CLI or Desktop session

Run a self-paced `/loop` whose prompt asks for this mode, such as
`/loop babysit PR 123 with github-toolkit`. It wakes through `ScheduleWakeup`
after one minute to one hour, with the agent picking each delay. For faster
reaction, run a `Monitor` script that polls `gh` and prints one line per new
comment or finished check. A Monitor lasts at most 30 minutes, so re-arm it when
it expires. Every option is scoped to the session: loops expire after seven
days, and `--resume` restores neither a self-paced loop nor a Monitor. Send
`PushNotification` at handoff. See the
[scheduled tasks docs](https://code.claude.com/docs/en/scheduled-tasks).

### Codex in the ChatGPT desktop app

Attach a scheduled task to the current chat at a minute-based interval, so each
run returns to the same chat with its context. Run it in the project's local
checkout rather than a new worktree, so commits land on the PR branch. Runs are
unattended and may skip approvals, which leaves this mode's
[Authority](#authority) limits as the only guard. ChatGPT's GitHub event
triggers exist only on web and mobile, which cannot reach the local checkout.
See the
[scheduled tasks docs](https://learn.chatgpt.com/docs/automations?surface=app).

### Codex CLI, Gemini CLI, OpenCode, and pi

None has a built-in scheduler. An external timer can start each pass: cron
running `codex exec`, a prompt sent to an `opencode serve` session, or a pi
extension that calls `pi.sendMessage` with `triggerTurn: true`. A fresh run has
no earlier reports, so it relies on the pending review and PR history to skip
handled items.

### Any host without a wake mechanism

Run one pass and say in the report that nothing is watching the PR. A foreground
sleep loop blocks the session and hides that gap.
