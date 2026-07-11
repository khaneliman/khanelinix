# Pull Request Feedback

Use when inspecting or addressing existing review comments on a pull request.
Use [pr-review.md](pr-review.md) when authoring a new review.

## Workflow

1. Verify authentication and resolve target pull request. With no target, use
   pull request for current branch; outside matching branch, stop or use target
   explicitly supplied by user.
2. For current-branch pull request, fetch comments with
   `python "<path-to-skill>/scripts/fetch_comments.py"` when bundled script is
   available. Script accepts no target argument. For explicit number or URL, use
   GitHub read tools instead.
3. Read root and changed-path instructions plus contributor guidance.
4. Group actionable, resolved, stale, duplicate, and informational threads.
5. Present actionable items with file/range, request, evidence, and likely fix.
6. Edit only feedback user selected or explicitly asked to address.
7. Run focused validation and report each thread as fixed, declined with reason,
   or blocked.

Do not resolve threads, submit reviews, push, or publish replies unless user
explicitly requests that GitHub write.
