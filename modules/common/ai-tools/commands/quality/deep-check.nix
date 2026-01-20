let
  commandName = "deep-check";
  description = "Comprehensive codebase analysis including unused code detection and optimization";
  allowedTools = "Bash(npm*), Bash(cargo*), Bash(make*), Bash(python*), Bash(go*), Bash(node*), Read, Grep";
  argumentHint = "[scope] [--with-builds] [--security] [--performance]";
  prompt = ''
    Perform thorough analysis of the project to identify issues, dead code, optimization opportunities, and maintenance concerns.

    **Workflow:**

    1. **Project Health Assessment**:
       - Identify and run available build/test/check commands (make test, npm test, cargo check, etc.)
       - Attempt builds of key project components to identify compilation/evaluation issues
       - Test project templates, examples, or sample configurations if they exist
       - Check cross-platform compatibility where applicable

    2. **Dead Code Detection - Find What's Unused**:
       - Search for unused imports across all source files
       - Identify unreferenced functions, classes, or modules
       - Flag old configuration options or deprecated flags
       - Detect dead branches (if/else paths never taken)

    3. **Architecture Review - Evaluate Structure**:
       - Assess module boundaries and coupling
       - Identify overly complex or tangled areas
       - Check for duplicated logic across the codebase
       - Review configuration layering and override patterns

    4. **Performance & Optimization**:
       - Identify slow build or runtime paths
       - Highlight large dependencies or redundant work
       - Suggest caching or memoization opportunities
       - Flag expensive operations inside loops

    5. **Security & Compliance**:
       - Check for obvious secret exposure or unsafe defaults
       - Identify missing input validation or error handling
       - Ensure permissions or access rules are explicit

    **Output Format:**

    ```markdown
    ## Deep Check Results

    ### Summary
    - Critical issues: X
    - Warnings: Y
    - Suggestions: Z

    ### Critical Issues
    - `path/to/file:line` - [issue]

    ### Warnings
    - `path/to/file:line` - [issue]

    ### Suggestions
    - `path/to/file:line` - [issue]

    ### Recommended Actions
    - [Action item 1]
    - [Action item 2]
    ```

    Be practical and prioritize issues by impact.
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
