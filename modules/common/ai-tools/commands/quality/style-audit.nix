{
  style-audit = ''
    ---
    allowed-tools: Read, Grep, Bash(eslint*), Bash(prettier*), Bash(black*), Bash(flake8*), Bash(rustfmt*), Bash(gofmt*), Bash(nix fmt*), Bash(nixfmt*), Bash(treefmt*)
    argument-hint: "[path] [--fix] [--report] [--focus=naming|structure|imports|organization]"
    description: Comprehensive style compliance checking against project standards
    ---

    Audit the codebase for style violations and report or fix them based on options.

    **Workflow:**

    1. **Analyze Project Standards First**:
       - Read existing files to understand the project's established patterns
       - Check for style configuration files (.eslintrc, .prettierrc, pyproject.toml, etc.)
       - Identify the project's preferred naming conventions and patterns
       - Understand organizational structures and architectural decisions
       - Determine the project's style preferences for consistency

    2. **Language-Specific Style Audit**:
       - Apply language-appropriate linting and formatting rules
       - Check for consistent import/require statement organization
       - Verify proper use of language-specific patterns and idioms
       - Validate adherence to established style guides (PEP 8, Google Style Guide, etc.)

    3. **Code Structure Analysis**:
       - Identify overly complex functions or classes that should be simplified
       - Find code blocks that could be better organized or refactored
       - Look for inconsistent patterns across similar code sections
       - Check for proper separation of concerns and modularity

    4. **Naming Convention Verification**:
       - Verify variables, functions, classes follow project conventions
       - Check that files and directories use consistent naming patterns
       - Validate that API endpoints, database fields, etc. follow consistent patterns
       - Ensure naming is descriptive and follows established conventions

    5. **Project Organization Assessment**:
       - Review file/directory structure and organization
       - Check that imports/dependencies are organized logically
       - Verify proper separation of concerns within the codebase
       - Assess overall architectural organization patterns

    6. **Best Practices Review**:
       - Find areas where established best practices aren't being followed
       - Check for proper error handling patterns
       - Validate adherence to language/framework-specific principles
       - Identify opportunities for better abstraction and code reuse

    **Execution Based on Arguments:**
    - If --fix is specified: Automatically correct violations where safe to do so
    - If --report is specified: Generate a detailed compliance report with file:line references
    - If --focus is specified: Concentrate only on that aspect (naming, structure, imports, etc.)
    - Use [path] to limit scope to specific directory or file

    **Command Arguments:**
    - [path]: Directory or file to audit (defaults to current directory)
    - --fix: Automatically fix violations that can be safely corrected
    - --report: Generate detailed compliance report with specific locations
    - --focus: Focus on specific style aspect (naming, structure, imports, organization)

    Provide actionable feedback with specific file locations and suggested improvements.
  '';
}
