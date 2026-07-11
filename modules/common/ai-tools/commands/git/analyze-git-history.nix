let
  commandName = "analyze-git-history";
in
{
  ${commandName} = {
    inherit
      commandName
      ;

    description = "Deep analysis of git history to find patterns, regressions, or understand code evolution";
    allowedTools = "Bash(git log:*), Bash(git blame:*), Bash(git show:*), Bash(git diff:*), Read, Grep";
    argumentHint = "[path] [--since=date] [--author=name] [--search=string]";
    prompt = ''
      Analyze git history for code evolution, bug origin, ownership, or change
      patterns. Filters come from `$ARGUMENTS`; with no arguments, use the current
      repository and no path, author, or date filter.

      Workflow:
      1. Identify target paths, symbols, search terms, author, and time range.
      2. Use `git log --oneline --graph --decorate --all` for shape, then narrow
         with pathspecs, `--since`, `--author`, `-S`, `-G`, or `--grep`.
      3. Inspect evidence with `git show`, `git log -p`, `git blame`, and focused
         `git diff` comparisons.
      4. Separate confirmed history from inference.

      Return a read-only report with target/range, summary, key commits with
      hashes, evidence-backed findings, confirmed facts versus inference, and
      only the next checks needed to close remaining uncertainty.
    '';
  };
}
