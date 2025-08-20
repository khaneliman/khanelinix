{
  changelog = ''
    ---
    allowed-tools: Bash(git log:*), Bash(git diff:*), Edit, Read
    argument-hint: [version] [change-type] [message]
    description: Update CHANGELOG.md with new entry following conventional commit standards
    ---

    Parse the version, change type, and message from the input
    and update the CHANGELOG.md file accordingly following
    conventional commit standards.
  '';

  review = ''
    ---
    allowed-tools: Bash(git status:*), Bash(git diff:*), Read, Grep
    description: Analyze staged git changes and provide thorough code review
    ---

    Analyze the staged git changes and provide a thorough
    code review with suggestions for improvement, focusing on
    code quality, security, and maintainability.
  '';

  nix-check = ''
    ---
    allowed-tools: Bash(nix flake check:*), Bash(nix fmt), Read, Grep
    description: Check Nix configuration for issues and suggest optimizations
    ---

    Check the current Nix configuration for issues:
    - Run nix flake check
    - Validate syntax and formatting
    - Check for unused imports
    - Suggest optimizations
  '';

  commit-msg = ''
    ---
    allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*)
    description: Generate conventional commit message based on staged changes
    ---

    Generate a conventional commit message based on the
    staged changes, following the project's commit standards.
  '';

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
