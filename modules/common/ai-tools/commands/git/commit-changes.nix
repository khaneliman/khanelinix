{
  commit-changes = ''
    ---
    allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Read, Grep
    description: Analyze changes, group them logically, and commit following repository conventions
    ---

    You are an expert software developer with deep understanding of version control best practices. Analyze all unstaged changes, group them into logical atomic commits, and create commits that follow the repository's specific conventions.

    WORKFLOW:
    1. First, analyze the repository's commit convention by examining recent git log entries
    2. Check for any CONTRIBUTING.md or similar files that define commit standards
    3. Identify and group all unstaged changes into logical, atomic units
    4. For each group, stage the relevant changes and create a commit message following the detected convention

    GROUPING STRATEGIES:
    - By feature/functionality (related new features together)
    - By component/module (same area of codebase)
    - By change type (fixes, refactoring, docs, etc.)
    - By file type when logical (config changes, tests)
    - Keep breaking changes separate
    - Ensure each group is atomic and self-contained

    CONVENTION DETECTION:
    Analyze recent commits to detect patterns like:
    - Conventional Commits: "type(scope): description" (feat, fix, docs, style, refactor, test, chore)
    - Angular Style: "type(scope): description" with specific types (build, ci, docs, feat, fix, perf, refactor, style, test)
    - Tim Pope Style: "Capitalized imperative subject" (50 chars max, no period)
    - Gitmoji: ":emoji: description" or "emoji description"
    - Semantic Release: "type: description" or "type(scope): description"
    - Component-based: "component: description" (e.g., "auth: fix login validation")
    - Action-based: "verb object" (e.g., "Add user authentication", "Fix memory leak")
    - Issue-based: "[#123] description" or "fixes #123: description"
    - Karma Style: "type(scope): description" with specific formatting rules
    - JSHint Style: "description (fixes #123)" with issue references at end
    - Atom Style: ":emoji: description" with Unicode emoji
    - Commitizen: Structured conventional commits with detailed formatting
    - Custom prefixes: Consistent use of prefixes like "WIP:", "HOTFIX:", "FEATURE:"
    - Scope patterns: Specific scoping conventions unique to the repository

    COMMIT MESSAGE GENERATION:
    For each group, generate a message that:
    - Follows the detected repository convention exactly
    - Uses appropriate type (feat, fix, docs, style, refactor, etc.)
    - Includes relevant scope when applicable
    - Describes the change clearly and concisely
    - Uses imperative mood and proper case
    - Stays within length limits (50 chars for subject)

    Create separate commits for each logical group, ensuring all changes are committed atomically while following the repository's established patterns.
  '';
}
