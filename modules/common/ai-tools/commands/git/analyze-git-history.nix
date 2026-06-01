let
  commandName = "analyze-git-history";
  description = "Deep analysis of git history to find patterns, regressions, or understand code evolution";
  allowedTools = "Bash(git log:*), Bash(git blame:*), Bash(git show:*), Bash(git diff:*), Read, Grep";
  argumentHint = "[path] [--since=date] [--author=name] [--search=string]";
  prompt = ''
    Analyze git history for code evolution, bug origin, ownership, or change
    patterns.

    Workflow:
    1. Identify target paths, symbols, search terms, author, and time range.
    2. Use `git log --oneline --graph --decorate --all` for shape, then narrow
       with pathspecs, `--since`, `--author`, `-S`, `-G`, or `--grep`.
    3. Inspect evidence with `git show`, `git log -p`, `git blame`, and focused
       `git diff` comparisons.
    4. Separate confirmed history from inference.

    Output: summary, key commits with hashes, evidence-backed findings, and
    recommended next checks or fixes.
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
