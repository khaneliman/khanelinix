{
  commit-changes = ''
    ---
    allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*)
    description: Analyze changes, stage them in atomic chunks, and commit with conventional messages
    ---

    Analyze all unstaged changes and group them into logical, atomic commits.
    For each chunk:
    1. Stage only the relevant files/changes for that logical unit
    2. Generate an appropriate conventional commit message
    3. Create the commit

    Consider these grouping strategies:
    - By feature/functionality (new features together)
    - By file type/area (config changes, docs, tests)
    - By scope (same module/component changes)
    - By change type (fixes, refactoring, etc.)

    Ensure each commit is atomic and follows conventional commit standards.
  '';
}
