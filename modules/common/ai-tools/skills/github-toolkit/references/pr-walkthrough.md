# Pull Request Walkthrough

Explain the change. Use [pr-review.md](pr-review.md) for a review verdict.

## Ground the Change

1. Run
   `python "<path-to-skill>/scripts/pr_snapshot.py" --repo OWNER/REPO --pr NUMBER_OR_URL`.
   Record base/head SHAs, state, and draft status. Read the PR body, linked
   requirements, and changed code at those revisions.
2. Check `completeness.files` and `completeness.commits`; expand snapshot limits
   or name coverage gaps. Draft or closed PRs can still be explained.
3. Use the available `how` skill only when material subsystem context is
   missing. Otherwise inspect the needed code directly; this mode owns the
   walkthrough.

## Order and Deliver

Start with the problem and resulting behavior. Choose the changed interface or
orchestration that best explains the feature, then trace dependencies into
implementation and verification. Order by responsibilities, not filenames.

Explain connections between change groups. Link to commit-pinned files and
lines; generate any requested excerpts from the recorded revisions rather than
reconstructing patches. Identify omitted areas and distinguish observed check
results from checks actually run. Name material unknowns.

Return in chat unless another destination was requested. Follow the toolkit's
Shared Rules for publication. When updating a PR description, preserve unrelated
author context and read back the resulting body.
