let
  commandName = "commit-changes";
in
{
  ${commandName} = {
    inherit
      commandName
      ;

    description = "Systematically analyze, group, and commit changes following repository conventions";
    allowedTools = "Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git reset:*), Read, Grep";
    argumentHint = "[--all] [--amend] [--dry-run] [--interactive]";
    prompt = ''
      Create commits at the smallest committable scope. Each commit should be
      the narrowest change that stands on its own, leaves the project buildable,
      and tells one useful history fact.

      Use the `git-toolkit` skill in commit-message/workflow mode. Follow its
      atomic commit and commit CLI safety rules.

      Required workflow:

      1. Inspect `git status`, `git diff`, and recent `git log`.
      2. Split by independently buildable purpose, not by request, feature name,
         file, or directory.
      3. Name the target of every commit: component, dependency,
         configuration surface, command, generated artifact, or integration
         point.
      4. Split same-kind changes by independently revertible target. Different
         components, dependencies, upstream projects, configuration surfaces,
         commands, or generated artifacts are separate commits unless one cannot
         evaluate or make sense without the other.
      5. Separate setup, enablement, configuration, generated output, cleanup,
         formatting, tests, and documentation when each can stand alone.
      6. Order groups by dependency so each commit stands alone.
      7. Present the commit plan before committing.
      8. Stage only the intended hunks/files for each commit.
      9. Review `git diff --cached` before every commit.
      10. Use the repository's commit convention and always include a body
         explaining why the commit exists.

      Do not bundle unrelated changes, mix formatting with behavior, or commit a
      reference before the referenced code exists. Do not bundle related changes
      only because they support the same feature or tool. Do not collapse
      multiple setup changes into one "setup" commit when their upstreams,
      dependencies, rollback paths, or verification differ.

      If `--dry-run` is provided, stop after the commit plan. If `--amend` or
      `--interactive` is provided, preserve the same atomicity rules and ask before
      rewriting history.
    '';

  };
}
