let
  commandName = "style-audit";
  description = "Comprehensive style compliance checking against project standards";
  allowedTools = "Read, Grep, Bash(eslint*), Bash(prettier*), Bash(black*), Bash(flake8*), Bash(rustfmt*), Bash(gofmt*), Bash(nix fmt*), Bash(nixfmt*), Bash(treefmt*)";
  argumentHint = "[path] [--fix] [--report] [--focus=naming|structure|imports|organization]";
  prompt = ''
    Audit the codebase for style violations and report or fix them based on options.

    **Workflow:**

    1. **Analyze Project Standards First**:
       - Read existing files to understand the project's established patterns
       - Check for style configuration files (.eslintrc, .prettierrc, pyproject.toml, etc.)
       - Identify the project's preferred naming conventions and patterns
       - Understand organizational structures and architectural decisions
       - Determine the project's style preferences for consistency

    2. **Language-Specific Style Audit**:
       - Run appropriate formatters and linters in check mode
       - Focus on naming, imports, spacing, and structural conventions
       - Record style violations with file:line references

    3. **Fixing (if --fix)**:
       - Apply formatters or auto-fixes where safe
       - Re-run checks to confirm fixes
       - Report any remaining issues

    **Output Format:**

    ```markdown
    ## Style Audit Results

    ### Summary
    - Files checked: X
    - Violations found: Y
    - Auto-fixed: Z

    ### Violations
    - `path/to/file:line` - [issue]

    ### Recommendations
    - [Recommendation 1]
    - [Recommendation 2]
    ```

    Prioritize consistency with existing style over personal preferences.
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
