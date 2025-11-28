{
  dependency-audit = ''
    ---
    allowed-tools: Bash(npm audit*), Bash(npm ls*), Bash(pip-audit*), Bash(cargo audit*), Bash(bundle audit*), Read, Grep
    argument-hint: "[--unused] [--conflicts] [--updates] [--security] [--report]"
    description: Check and optimize project dependencies and package management
    ---

    Analyze project dependencies to identify optimization opportunities, security concerns, and maintenance issues.

    **Workflow:**

    1. **Unused Dependency Detection - Find Dead Weight**:
       - Parse package manifests (package.json, requirements.txt, Cargo.toml, etc.) to identify all declared dependencies
       - Search the codebase to find which dependencies are actually imported/used
       - Identify packages that are declared but never referenced in the code
       - Check for import statements that bring in unused functionality

    2. **Dependency Conflict Analysis - Identify Issues**:
       - Check for version conflicts between different dependencies
       - Identify cases where multiple packages provide similar functionality
       - Look for overlapping functionality that could cause conflicts
       - Analyze build-time vs runtime dependency mismatches

    3. **Update Opportunity Analysis - Find Improvements**:
       - Check which dependencies have newer versions available
       - Identify packages that have known security updates
       - Look for optimization opportunities in package selection
       - Check for deprecated packages that should be replaced

    4. **Security Assessment (if --security)**:
       - Check dependencies against known vulnerability databases (npm audit, pip-audit, etc.)
       - Validate that dependency sources are from trusted, official repositories
       - Review any packages from non-standard or third-party sources
       - Assess overall supply chain security posture

    5. **Optimization Recommendations - Suggest Improvements**:
       - Identify opportunities to consolidate similar dependencies
       - Find over-specified dependencies that could use lighter alternatives
       - Recommend package alternatives that reduce bundle/build sizes
       - Suggest structural improvements for dependency management

    **Analysis Focus Based on Arguments:**
    - --unused: Focus specifically on finding and reporting unused dependencies
    - --conflicts: Deep-dive into dependency conflict analysis
    - --updates: Concentrate on available updates and migration paths
    - --security: Emphasize security analysis and vulnerability assessment
    - --report: Generate comprehensive report covering all aspects

    **Command Arguments:**
    - --unused: Focus analysis on finding unused dependencies
    - --conflicts: Analyze and report on dependency conflicts
    - --updates: Check for available updates and upgrade opportunities
    - --security: Focus on security analysis and vulnerability assessment
    - --report: Generate comprehensive dependency report with all findings

    Provide actionable recommendations with specific commands and file references.
  '';
}
