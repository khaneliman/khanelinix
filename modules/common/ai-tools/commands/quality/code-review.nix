let
  commandName = "code-review";
in
{
  ${commandName} = {
    inherit
      commandName
      ;

    description = "Code review a pull request";
    allowedTools = "Bash(gh issue view:*), Bash(gh search:*), Bash(gh issue list:*), Bash(gh pr diff:*), Bash(gh pr view:*), Bash(gh pr list:*), Read, Grep";
    prompt = ''
      Provide a high-signal code review for the given pull request.

      Use the `github-toolkit` skill in PR review mode and follow its high-signal
      review policy.

      Required workflow:

      1. Resolve the PR title, description, changed files, and full commit SHA.
      2. Stop without reviewing if the PR is closed, draft, automated/trivial, or
         already has a Claude review comment.
      3. Find applicable `AGENTS.md` or `CLAUDE.md` files for changed paths.
      4. Review only the diff and directly relevant local context.
      5. Flag only validated, high-confidence issues:
         - syntax/type/compile failures
         - definite logic errors in changed code
         - clear security or data-loss defects
         - clear instruction-file violations scoped to the changed file
      6. Filter out pre-existing issues, style opinions, speculative risks, linter
         findings, and duplicates.
      7. Return findings in review format. Do not post GitHub comments from this
         command; use an explicit GitHub write workflow when requested.

      Use committable suggestion blocks only when the suggestion fully fixes the
      issue. If no issues are found, return the standard no-issues summary from
      `github-toolkit`.
    '';
  };
}
