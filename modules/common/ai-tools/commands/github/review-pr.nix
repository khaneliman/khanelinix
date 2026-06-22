let
  commandName = "review-pr";
  description = "Review a GitHub pull request and create pending review feedback";
  allowedTools = "Bash(gh auth status:*), Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh pr checks:*), Bash(gh api:*), Bash(git remote:*), Bash(git status:*), Bash(git log:*), Bash(rg:*), Read, Grep, Glob";
  argumentHint = "<pr-number|pr-url|branch>";
  prompt = ''
    Review PR and create a pending GitHub review. Target is command arguments or
    invoking user message: $ARGUMENTS.

    If target is a number, use current repo. If it is a URL, use that owner/repo.
    If blank, infer the PR for the current branch.

    Use `github-toolkit` in pr-review mode. Use `git-toolkit` workflow and
    commit-message mode for branch, commit, and history hygiene. For changed
    code, load matching language/domain skills before judging implementation
    quality, for example `writing-nix`, `lua-toolkit`, `frontend-design`,
    `security-toolkit`, `mcp-builder`, or `nix-toolkit`.

    Hard rules:
    - Pending review means a GitHub review left unsubmitted for user inspection.
      Do not call `submitPullRequestReview` or send review events.
    - Add `<!-- ai-tools:review-pr -->` to the pending review body. If an
      existing review contains this marker, stop instead of duplicating feedback.
    - If there are no validated findings, do not create a pending review; report
      no issues found.

    Workflow:
    1. Resolve PR metadata, status, base/head SHA, commits, changed files, and
       checks. Stop if closed, draft, or clearly generated/dependency-only with
       no reviewable code.
    2. Read repository guidance: `CONTRIBUTING.md`, PR template, root and
       changed-path `AGENTS.md`/`CLAUDE.md`, and directly relevant docs.
    3. Review only diff plus necessary local context. Check contribution
       compliance, docs/tests expectations, licensing/secrets, and atomic Git
       history.
    4. Report only high-confidence defects or policy violations. No style
       opinions, speculative risks, duplicates, or pre-existing issues.
    5. Create one pending GitHub review containing the concise body and inline
       comments. Use GitHub API mechanics from `github-toolkit`; use GraphQL for
       multi-line ranges or suggestion blocks. Do not use `gh pr review` because
       it submits immediately.
    6. Verify the pending review exists and comment ranges are anchored
       correctly. If pending review creation fails, print the exact draft review
       instead.

    Output concise result:
    - Pending review status or fallback reason.
    - Findings: file:line, severity, evidence, fix.
    - Contribution/docs gaps: cite exact guideline path or URL.
    - GitHub UI next step for user to inspect and submit/discard.

    Do not submit the pending review, approve, request changes, push, or edit
    files. Leave final publication to the user in GitHub UI.
  '';

in
{
  ${commandName} = {
    inherit
      commandName
      description
      allowedTools
      argumentHint
      prompt
      ;
  };
}
