{
  commit-msg = ''
    ---
    allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*)
    argument-hint: "[--type=feat|fix|docs|...] [--scope=component] [--breaking]"
    description: Generate conventional commit message based on staged changes
    ---

    Generate a conventional commit message for the staged changes.

    **Workflow:**

    1. **Analyze Staged Changes**:
       - Run `git diff --cached --stat` to see files changed
       - Run `git diff --cached` to examine actual changes
       - Run `git log --oneline -5` to understand recent commit style
       - Identify the nature of changes (new code, modifications, deletions)

    2. **Determine Commit Type**:

       | Type | When to Use |
       |------|-------------|
       | `feat` | New feature or capability added |
       | `fix` | Bug fix |
       | `docs` | Documentation only changes |
       | `style` | Formatting, no code change |
       | `refactor` | Code change that neither fixes nor adds |
       | `perf` | Performance improvement |
       | `test` | Adding or fixing tests |
       | `build` | Build system or dependencies |
       | `ci` | CI configuration |
       | `chore` | Maintenance tasks |
       | `revert` | Reverting previous commit |

    3. **Determine Scope**:
       - Extract from file paths (e.g., `src/auth/` → `auth`)
       - Use component or module name
       - Omit if changes span many areas

    4. **Detect Breaking Changes**:
       - Look for API changes, removed functions, renamed exports
       - Check for schema changes, config format changes
       - Flag with `!` after type or `BREAKING CHANGE:` in footer

    5. **Generate Message**:
       - Subject: imperative, lowercase, no period, ≤72 chars
       - Body: explain WHY not WHAT (optional for small changes)
       - Footer: breaking changes, issue refs (optional)

    **Format:**

    ```
    <type>(<scope>): <subject>

    [optional body - explain motivation/context]

    [optional footer - BREAKING CHANGE:, Fixes #123]
    ```

    **Good Examples:**

    ```
    feat(auth): add OAuth2 support for GitHub login

    fix(api): handle null response from payment gateway

    refactor(utils): simplify date formatting logic

    feat(db)!: change user schema to support multi-tenancy

    BREAKING CHANGE: User.org_id is now required

    docs: update API reference for v2 endpoints
    ```

    **Bad Examples (Avoid):**

    ```
    # Too vague
    fix: fixed bug

    # Not imperative
    feat: added new feature

    # Too long, has period
    fix(authentication-service): this fixes the bug where users cannot login when their session expires.

    # Describes WHAT not WHY
    refactor: changed function name from foo to bar
    ```

    **Issue References:**

    ```
    feat(auth): add password reset flow

    Implements the forgot password feature with email verification.

    Closes #42
    Refs #38
    ```

    **Output Format:**

    Present the generated commit message in a code block, then explain your reasoning:
    - Why you chose this type
    - Why this scope (or why omitted)
    - What the key changes are

    Ask the user if they want to modify anything before committing.
  '';
}
