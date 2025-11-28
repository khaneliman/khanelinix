{
  module-lint = ''
    ---
    allowed-tools: Read, Grep, Bash(eslint*), Bash(pylint*), Bash(flake8*), Bash(cargo clippy*)
    argument-hint: "[path] [--fix] [--strict] [--focus=structure|interfaces|docs]"
    description: Software module best practices and compliance checking
    ---

    Lint code modules for best practices compliance and report issues or fix them where possible.

    **Workflow:**

    1. **Module Structure Validation**:
       - Verify proper module structure and organization patterns
       - Check that imports and dependencies follow expected patterns
       - Ensure clear separation of concerns within modules
       - Validate appropriate use of framework/language-specific patterns

    2. **API/Interface Design Review**:
       - Check that all public interfaces are properly defined and typed
       - Verify that functions/methods have sensible defaults where applicable
       - Review documentation for clarity and completeness
       - Ensure consistent naming conventions across the module
       - Check for proper handling of dependencies and configurations

    3. **Logic and Implementation Audit**:
       - Review conditional logic and control flow for best practices
       - Check that error handling follows established patterns
       - Validate proper resource management and cleanup
       - Ensure proper handling of edge cases and boundary conditions

    4. **Documentation Quality Check**:
       - Identify missing or inadequate function/class documentation
       - Validate that example usage is correct and helpful
       - Review inline comments for clarity and accuracy
       - Check that complex logic has proper explanation

    5. **Integration Pattern Compliance**:
       - Verify proper dependency injection and module coupling
       - Check for appropriate configuration and environment handling
       - Review testing patterns and test coverage
       - Validate adherence to project architectural principles

    **Execution Strategy:**
    - Focus on [path] if specified, otherwise lint current directory
    - If --fix is specified, automatically correct issues that are safe to fix
    - If --strict is specified, apply more rigorous validation standards
    - If --focus is specified, concentrate on that specific aspect (structure, interfaces, docs)

    **Command Arguments:**
    - [path]: Module file or directory to lint (defaults to current directory)
    - --fix: Automatically fix issues that can be safely corrected
    - --strict: Apply stricter validation rules and best practices
    - --focus: Focus on specific quality aspect (structure, interfaces, docs)

    Provide specific, actionable feedback with file locations and suggested improvements.
  '';
}
