{
  add-and-format = ''
    ---
    allowed-tools: Bash(git*), Bash(prettier*), Bash(black*), Bash(rustfmt*), Bash(gofmt*), Bash(eslint*), Bash(pylint*), Bash(nix fmt*), Bash(nixfmt*), Bash(treefmt*), Read, Grep
    argument-hint: "[files...] [--all] [--check]"
    description: Smart git add with automatic formatting and style checking for files
    ---

    Intelligently add files to git staging with formatting and validation.

    **Workflow:**

    1. **File Discovery - Find What Needs Adding**:
       - Use `git status` to identify new/modified files that need to be added
       - Include related configuration files (.toml, .yaml, .json, .md) in the same directories
       - Check .gitignore to ensure you don't stage build artifacts or temporary files
       - If specific files are provided as arguments, focus only on those

    2. **Pre-add Processing - Format Before Staging**:
       - Detect available formatters in the project (prettier, black, rustfmt, gofmt, etc.)
       - Run appropriate formatters on files being added
       - Check for basic syntax errors using available linters or language tools
       - Read files to validate basic structure and check for obvious issues
       - Do NOT stage files that have syntax errors

    3. **Smart Staging - Add Files Logically**:
       - Stage files in logical groups (e.g., all files in a feature/module together)
       - Use `git add <file>` for each validated file
       - Preserve any existing staged changes - do not unstage anything that was already staged
       - If --check is specified, show what you would do but don't actually stage anything

    4. **Verification and Reporting**:
       - After staging, run `git status` to show what was staged
       - Report any files that were skipped due to errors
       - If available, run basic pre-commit hooks to validate staged changes

    **Command Arguments:**
    - [files...]: If provided, only process these specific files
    - --all: Process all modified/new files with formatting
    - --check: Dry run mode - show what would be done without making changes

    Follow project conventions and ensure all staged files are properly formatted.
  '';
}
