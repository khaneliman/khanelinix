{
  nix-check = ''
    ---
    allowed-tools: Bash(nix flake check:*), Bash(nix fmt), Bash(nix eval*), Bash(nix build*), Read, Grep, Task
    argument-hint: "[path] [--build] [--eval] [--format] [--full]"
    description: Comprehensive Nix code validation and formatting with detailed error reporting
    ---

    Validate Nix code, identify issues, and provide actionable improvements.

    ## **WORKFLOW OVERVIEW**

    This command provides 4-tier validation:
    1. **Syntax & Parse** - Basic Nix syntax validation
    2. **Evaluation** - Check that expressions evaluate correctly
    3. **Build Testing** - Verify outputs can be built
    4. **Quality Analysis** - Optimization and best practice recommendations

    ## **PHASE 1: PROJECT ANALYSIS**

    ### **Step 1.1: Context Detection**
    ```
    ALWAYS START - Determine Nix project type and scope
    ```

    **Project type detection:**
    - Check for `flake.nix` in current directory (flake-based project)
    - Check for `shell.nix` or `default.nix` (traditional Nix project)
    - Look for NixOS configuration patterns (`configuration.nix`, `/etc/nixos/`)
    - Check for Home Manager patterns (`home.nix`, `.config/home-manager/`)

    **Scope determination:**
    ```
    IF path specified:
        Focus validation on specific file/directory
    ELSE IF flake detected:
        Validate entire flake and its outputs
    ELSE:
        Validate current directory and common Nix files
    ```

    ### **Step 1.2: Available Tools Detection**
    **Check available validation tools:**
    ```
    □ nix flake check (for flakes)
    □ nix-instantiate (for traditional projects)
    □ nix eval (for expression testing)
    □ nix fmt / treefmt (for formatting)
    □ statix, deadnix (if available via shell)
    ```

    ## **PHASE 2: SYSTEMATIC VALIDATION**

    ### **Step 2.1: Syntax Validation**
    **Parse-level validation:**
    ```
    FOR each .nix file in scope:
        Run: nix-instantiate --parse <file>
        Record syntax errors with line numbers
        Check for common parse issues:
          - Missing semicolons in attribute sets
          - Unbalanced parentheses/brackets
          - Invalid attribute names
          - String interpolation errors
    ```

    **Immediate feedback:**
    - Stop validation if critical syntax errors found
    - Report exact error locations with context
    - Suggest common fixes for typical syntax issues

    ### **Step 2.2: Evaluation Testing**
    **Expression evaluation validation:**
    ```
    IF --eval flag OR --full flag:
        FOR each file/expression:
            Test basic evaluation: nix eval --file <file>
            Check for evaluation errors:
              - Undefined variables
              - Missing imports
              - Type errors
              - Infinite recursion
            Record evaluation failures with context
    ```

    **Flake-specific evaluation:**
    ```
    IF flake.nix present:
        Run: nix flake check --no-build
        Validate flake schema and metadata
        Check input resolution
        Test output attribute accessibility
    ```

    ### **Step 2.3: Build Validation**
    **Build-time validation:**
    ```
    IF --build flag OR --full flag:
        FOR flake outputs:
            Test: nix build .#<output> --dry-run
            Record buildability issues
        FOR traditional projects:
            Test: nix-build --dry-run
            Check derivation validity
    ```

    **Build issue analysis:**
    ```
    Categorize build problems:
      - Missing dependencies
      - Platform compatibility issues
      - Configuration errors
      - Resource availability problems
    ```

    ## **PHASE 3: QUALITY ANALYSIS**

    ### **Step 3.1: Code Quality Assessment**
    **Static analysis patterns:**
    ```
    FOR each .nix file:
        Check for anti-patterns:
          - Use of `with` statements
          - Hardcoded paths and values
          - Missing error handling
          - Inefficient attribute access
          - Unused imports and variables
    ```

    **Project-specific patterns:**
    ```
    IF khanelinix project detected:
        Launch Task with Nix Expert: "Analyze this Nix code for khanelinix compliance and optimization opportunities"
    ELSE:
        Apply general Nix best practices analysis
    ```

    ### **Step 3.2: Formatting Validation**
    ```
    IF --format flag OR --full flag:
        Run available formatters:
          - nix fmt (if treefmt configured)
          - nixfmt (if available)
        Report formatting inconsistencies
        IF format issues found AND no --check flag:
            Offer to auto-fix formatting
    ```

    ### **Step 3.3: Optimization Opportunities**
    **Performance analysis:**
    ```
    Identify optimization opportunities:
      - Lazy evaluation improvements
      - Attribute access optimization
      - Import organization
      - Function call efficiency
      - Memory usage patterns
    ```

    ## **PHASE 4: REPORTING AND RECOMMENDATIONS**

    ### **Step 4.1: Issue Classification**
    **Categorize all findings:**
    ```
    CRITICAL: Syntax errors preventing evaluation
    HIGH: Evaluation errors breaking functionality
    MEDIUM: Build issues or significant anti-patterns
    LOW: Style issues and minor optimizations
    INFO: Suggestions and best practices
    ```

    ### **Step 4.2: Actionable Report Generation**
    **For each issue found:**
    ```
    Report format:
    [SEVERITY] File:Line - Issue Description

    Problem: Detailed explanation of the issue
    Impact: Why this matters (performance, maintainability, correctness)
    Solution: Specific steps to fix the issue
    Example: Code snippet showing the fix (if applicable)
    ```

    ### **Step 4.3: Summary and Next Steps**
    ```
    Provide summary:
      - Total files checked
      - Issues found by category
      - Critical issues requiring immediate attention
      - Recommended next steps
      - Commands to run for fixes
    ```

    ## **COMMAND FLAGS AND BEHAVIOR**

    **Flag-specific execution:**
    ```
    --build: Include build testing and derivation validation
    --eval: Include comprehensive evaluation testing
    --format: Focus on formatting validation and auto-fix offers
    --full: Run all validation phases (syntax + eval + build + quality)
    No flags: Run syntax + basic evaluation + quality analysis
    ```

    ## **ERROR HANDLING AND RECOVERY**

    **Graceful failure handling:**
    ```
    FOR each validation failure:
        - Continue checking other files/aspects
        - Provide detailed error context
        - Suggest recovery strategies
        - Offer to isolate problems for debugging
    ```

    **Progress reporting:**
    ```
    Show progress for long-running operations:
      - File-by-file validation status
      - Current phase and estimated completion
      - Summary of issues found so far
    ```

    ## **USAGE EXAMPLES**

    ```bash
    # Quick syntax and quality check
    /nix-check

    # Comprehensive validation with builds
    /nix-check --full

    # Check specific module with formatting
    /nix-check modules/home/programs/git --format

    # Evaluation-focused testing
    /nix-check flake.nix --eval
    ```

    **REMEMBER:** Provide clear, actionable feedback that helps developers improve their Nix code quality while ensuring functionality and maintainability.
  '';
}
