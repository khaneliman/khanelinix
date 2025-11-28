{
  deep-check = ''
    ---
    allowed-tools: Bash(npm*), Bash(cargo*), Bash(make*), Bash(python*), Bash(go*), Bash(node*), Read, Grep
    argument-hint: "[scope] [--with-builds] [--security] [--performance]"
    description: Comprehensive codebase analysis including unused code detection and optimization
    ---

    Perform thorough analysis of the project to identify issues, dead code, optimization opportunities, and maintenance concerns.

    **Workflow:**

    1. **Project Health Assessment**:
       - Identify and run available build/test/check commands (make test, npm test, cargo check, etc.)
       - Attempt builds of key project components to identify compilation/evaluation issues
       - Test project templates, examples, or sample configurations if they exist
       - Check cross-platform compatibility where applicable

    2. **Dead Code Detection - Find What's Unused**:
       - Search for unused imports across all source files
       - Identify functions, variables, classes, and modules that are defined but never referenced
       - Find orphaned files that aren't imported or included anywhere
       - Detect redundant or duplicate code patterns across the codebase

    3. **Dependency Analysis - Map Relationships**:
       - Create a dependency map showing how modules/components relate to each other
       - Identify any circular dependencies between components
       - Check package.json, Cargo.toml, requirements.txt, or similar for unused dependencies
       - If --performance is specified, analyze bundle sizes and build impacts

    4. **Quality Assessment - Measure Code Health**:
       - Assess code complexity and maintainability using available metrics
       - Check for proper documentation and comments
       - Identify performance bottlenecks if --performance is specified
       - If --security is specified, review security practices and potential vulnerabilities

    5. **Actionable Recommendations**:
       - Provide specific refactoring recommendations with file paths and line numbers
       - Suggest performance improvements with measurable impact
       - Recommend structural optimizations for better maintainability
       - Highlight maintenance issues that need immediate attention

    **Command Arguments:**
    - [scope]: Focus your analysis on specific areas (src, tests, docs, all)
    - --with-builds: Actually build/compile the project to test for build-time issues
    - --security: Include security analysis and vulnerability recommendations
    - --performance: Focus heavily on performance analysis and optimization opportunities

    Provide actionable insights with specific file references for comprehensive maintenance planning.
  '';
}
