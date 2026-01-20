let
  commandName = "module-lint";
  description = "Software module best practices and compliance checking";
  allowedTools = "Read, Grep, Bash(eslint*), Bash(pylint*), Bash(flake8*), Bash(cargo clippy*)";
  argumentHint = "[path] [--fix] [--strict] [--focus=structure|interfaces|docs]";
  prompt = ''
    Lint code modules for best practices compliance and report issues or fix them where possible.

    **Workflow:**

    1. **Module Structure Validation**:
       - Verify proper module structure and organization patterns
       - Check that imports and dependencies follow expected patterns
       - Ensure clear separation of concerns within modules
       - Validate appropriate use of framework/language-specific patterns

    2. **API/Interface Design Review**:
       - Check that all public interfaces are properly defined and typed
       - Ensure versioning and backwards compatibility where applicable
       - Validate error handling and return types

    3. **Documentation Review**:
       - Verify that public APIs are documented
       - Check for missing or outdated module documentation
       - Ensure usage examples are present for complex APIs

    4. **Linting and Fixes**:
       - Run appropriate linters if available (eslint, pylint, flake8, clippy)
       - Apply auto-fixes if --fix is provided
       - Report any remaining issues clearly

    **Output Format:**

    ```markdown
    ## Module Lint Results

    ### Summary
    - Issues found: X
    - Auto-fixed: Y
    - Manual fixes required: Z

    ### Issues
    - `path/to/file:line` - [issue]

    ### Recommendations
    - [Recommendation 1]
    - [Recommendation 2]
    ```

    Focus on actionable fixes and align with existing project conventions.
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
