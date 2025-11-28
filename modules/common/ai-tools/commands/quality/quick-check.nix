{
  quick-check = ''
    ---
    allowed-tools: Bash(git*), Bash(eslint*), Bash(tsc*), Bash(python*), Bash(cargo check*), Bash(npm*), Bash(prettier*), Bash(nix fmt*), Bash(nixfmt*), Bash(treefmt*), Read, Grep
    argument-hint: "[path] [--fix] [--verbose]"
    description: Fast syntax, build, and format validation for immediate feedback
    ---

    Perform fast, essential checks that catch common issues during active development.

    **Workflow:**

    1. **Syntax Validation - Catch Parse Errors Fast**:
       - Run language-specific syntax checkers (eslint --max-warnings 0, python -m py_compile, tsc --noEmit, etc.)
       - Look for common issues like missing imports, undefined variables, syntax errors
       - Check for obvious function call problems and malformed expressions
       - Skip expensive compilation/builds - focus on parse-level validation

    2. **Format Checking - Verify Style Consistency**:
       - Run available formatters in check mode (prettier --check, black --check, rustfmt --check)
       - Identify files that have formatting inconsistencies
       - Look for obvious style violations based on project configuration
       - Check basic naming convention compliance

    3. **Basic Build Test - Quick Validation**:
       - Run quick build/test commands without full compilation (npm run type-check, cargo check, etc.)
       - Verify that key components parse and validate correctly
       - Check that configurations and schemas are properly structured
       - Test critical functionality without expensive integration tests

    4. **Git-Aware Efficiency**:
       - Use `git status` to identify modified and staged files
       - Focus validation efforts on changed files for speed
       - Report validation status alongside git status information
       - Provide git-workflow-friendly output

    **Execution Strategy:**
    - If [path] is specified, limit checks to that directory or file
    - If --fix is specified, automatically correct issues that are safe to fix
    - If --verbose is specified, show detailed output for each check performed
    - Otherwise, provide concise feedback focusing on actionable issues

    **Command Arguments:**
    - [path]: Directory or file to check (defaults to current directory)
    - --fix: Automatically fix issues that can be safely corrected
    - --verbose: Show detailed output for all validation steps

    Prioritize speed and actionable feedback for active development workflows.
  '';
}
