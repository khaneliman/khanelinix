let
  commandName = "git-history";
  description = "Deep analysis of git history to find patterns, regressions, or understand code evolution";
  allowedTools = "Bash(git log:*), Bash(git blame:*), Bash(git show:*), Bash(git diff:*), Read, Grep";
  argumentHint = "[path] [--since=date] [--author=name] [--search=string]";
  prompt = ''
    Analyze git history to understand code evolution, find when bugs were introduced, and trace the origins of changes.

    **Workflow:**

    1. **Understand the Request**:
       - Clarify what the user wants to find (bug origin, code evolution, author contributions)
       - Identify relevant files, functions, or patterns to search for
       - Determine appropriate time range if applicable

    2. **Initial Reconnaissance**:
       - Use `git log --oneline` to get overview of recent history
       - Check branch structure with `git log --oneline --graph --all`

    3. **Deep Investigation**:
       - Use `git log -p` to review changes over time
       - Use `git blame` for line-by-line history
       - Use `git show` to inspect specific commits
       - Use `git diff` to compare revisions

    4. **Pattern Analysis**:
       - Identify trends, regressions, or repeated changes
       - Note contributors and intent from commit messages
       - Summarize key turning points in the history

    **Output Format:**

    ```markdown
    ## Git History Summary

    ### Overview
    [High-level summary]

    ### Key Commits
    - `commit-hash` - [summary]
    - `commit-hash` - [summary]

    ### Findings
    - [Finding 1]
    - [Finding 2]

    ### Recommendations
    - [Suggested follow-ups]
    ```

    Focus on actionable insights and cite relevant commits with hashes.
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
