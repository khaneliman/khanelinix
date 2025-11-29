{
  git-history = ''
    ---
    allowed-tools: Bash(git log:*), Bash(git blame:*), Bash(git show:*), Bash(git diff:*), Read, Grep
    argument-hint: "[path] [--since=date] [--author=name] [--search=string]"
    description: Deep analysis of git history to find patterns, regressions, or understand code evolution
    ---

    Analyze git history to understand code evolution, find when bugs were introduced, and trace the origins of changes.

    **Workflow:**

    1. **Understand the Request**:
       - Clarify what the user wants to find (bug origin, code evolution, author contributions)
       - Identify relevant files, functions, or patterns to search for
       - Determine appropriate time range if applicable

    2. **Initial Reconnaissance**:
       - Use `git log --oneline` to get overview of recent history
       - Check branch structure with `git log --oneline --graph --all`
       - Identify relevant commits with appropriate filters

    3. **Deep Analysis**:
       - Use `git log -S "string"` for pickaxe search (when string was added/removed)
       - Use `git log -G "regex"` for pattern-based search
       - Use `git blame` to trace specific line origins
       - Use `git show` to examine specific commits in detail

    4. **Synthesis**:
       - Summarize findings with commit hashes and dates
       - Identify patterns (frequent changes, problem areas, key contributors)
       - Provide actionable insights based on history analysis

    **Command Arguments:**
    - `[path]`: Focus analysis on specific file or directory
    - `--since=date`: Limit to commits after date (e.g., "2024-01-01", "3 months ago")
    - `--author=name`: Filter by author name or email
    - `--search=string`: Search for commits containing this string (pickaxe)

    **Useful Commands:**

    ```bash
    # File history with renames
    git log --follow -p -- path/to/file

    # Who changed what lines
    git blame -L 10,30 file.txt

    # Find when string was added
    git log -S "functionName" --oneline

    # Commits by author in time range
    git log --author="name" --since="2024-01-01" --oneline
    ```

    Present findings clearly with commit hashes, dates, and relevant context.
  '';
}
