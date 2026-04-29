let
  commandName = "commit-changes";
  description = "Systematically analyze, group, and commit changes following repository conventions";
  allowedTools = "Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git reset:*), Read, Grep";
  argumentHint = "[--all] [--amend] [--dry-run] [--interactive]";
  prompt = ''
    Create minimal, atomic commits where each commit is one complete logical
    change and leaves the project buildable.

    Use the `git-toolkit` skill in commit-message/workflow mode. Follow its
    atomic commit and commit CLI safety rules.

    Required workflow:

    1. Inspect `git status`, `git diff`, and recent `git log`.
    2. Group changes by hunk-level purpose, not by file or directory.
    3. Order groups by dependency so each commit stands alone.
    4. Present the commit plan before committing.
    5. Stage only the intended hunks/files for each commit.
    6. Review `git diff --cached` before every commit.
    7. Use the repository's commit convention and include a body for non-trivial
       changes.

    Do not bundle unrelated changes, mix formatting with behavior, or commit a
    reference before the referenced code exists.

    If `--dry-run` is provided, stop after the commit plan. If `--amend` or
    `--interactive` is provided, preserve the same atomicity rules and ask before
    rewriting history.
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
