let
  commandName = "dependency-audit";
  description = "Check and optimize project dependencies and package management";
  allowedTools = "Bash(npm audit*), Bash(npm ls*), Bash(pip-audit*), Bash(cargo audit*), Bash(bundle audit*), Read, Grep";
  argumentHint = "[--unused] [--conflicts] [--updates] [--security] [--report]";
  prompt = ''
    Analyze project dependencies to identify optimization opportunities, security concerns, and maintenance issues.

    **Workflow:**

    1. **Unused Dependency Detection - Find Dead Weight**:
       - Parse package manifests (package.json, requirements.txt, Cargo.toml, etc.) to identify all declared dependencies
       - Search the codebase to find which dependencies are actually imported/used
       - Identify packages that are declared but never referenced in the code
       - Check for import statements that bring in unused functionality

    2. **Dependency Conflict Analysis - Identify Issues**:
       - Check for version conflicts between different dependencies
       - Identify duplicate dependencies or overlapping functionality
       - Look for outdated or deprecated packages

    3. **Security Audit - Check Vulnerabilities**:
       - Run appropriate audit tools (npm audit, pip-audit, cargo audit, bundle audit)
       - Identify known vulnerabilities and severity levels
       - Suggest patches or upgrades for critical issues

    4. **Optimization Opportunities - Trim and Improve**:
       - Suggest removing unused dependencies
       - Recommend version upgrades where safe
       - Highlight packages that can be consolidated
       - Identify heavy dependencies with lighter alternatives

    **Output Format:**

    ```markdown
    ## Dependency Audit Results

    ### Summary
    - Total dependencies: X
    - Unused dependencies: Y
    - Vulnerabilities: Z (Critical: A, High: B)

    ### Unused Dependencies
    - `package-name` - [reason]

    ### Vulnerabilities
    - `package-name` (Severity: High) - [fix]

    ### Upgrade Opportunities
    - `package-name` -> `new-version` - [benefit]

    ### Recommendations
    - [Action item 1]
    - [Action item 2]
    ```

    Prioritize security fixes and remove unused dependencies where possible.
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
