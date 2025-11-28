{
  nix-refactor = ''
    ---
    allowed-tools: Read, Edit, MultiEdit, Grep, Bash(nix fmt), Task
    argument-hint: "[path] [--style-only] [--fix-let-blocks] [--fix-lib-usage] [--fix-options] [--fix-modules]"
    description: Automatically fix Nix code style violations and refactor patterns according to project conventions
    ---

    Analyze and improve Nix code while preserving functionality and respecting project conventions.

    ## **WORKFLOW OVERVIEW**

    This command follows a systematic 4-phase approach:
    1. **Discovery** - Understand project patterns and analyze target code
    2. **Analysis** - Identify violations and improvement opportunities
    3. **Refactoring** - Apply fixes in priority order based on flags
    4. **Validation** - Ensure changes work and format consistently

    ## **PHASE 1: DISCOVERY AND CONTEXT**

    ### **Step 1.1: Project Context Detection**
    ```
    ALWAYS START HERE - Determine project type and gather patterns
    ```

    **For khanelinix repository detection:**
    - Check if current directory contains `flake.nix` with khanelinix-specific content
    - Look for `modules/` directory with `common/`, `nixos/`, `darwin/`, `home/` subdirs
    - Check for `CLAUDE.md` file indicating khanelinix project

    **Actions based on detection:**
    ```
    IF khanelinix detected:
        Launch Task with Dotfiles Expert: "Provide comprehensive khanelinix patterns for Nix refactoring including library usage, module structure, option namespacing, and coding conventions"
    ELSE:
        Read 3-5 representative .nix files to understand local patterns
        Look for lib usage patterns, module structures, naming conventions
    ```

    ### **Step 1.2: Target Analysis**
    **Read target files systematically:**
    ```
    IF path is directory:
        Use Grep to find all .nix files
        Read files matching the focus flags or all if no flags
    ELSE:
        Read the specific file provided
    ```

    **Document current patterns found:**
    - Library usage: `with lib;` vs `inherit (lib)` vs inline `lib.`
    - Let block placement and scoping
    - Module parameter organization
    - Option definition patterns
    - Conditional logic patterns (if-then-else vs mkIf)

    ## **PHASE 2: SYSTEMATIC ANALYSIS**

    ### **Step 2.1: Violation Detection**
    **Create analysis checklist for each file:**

    **Library Usage Analysis:**
    ```
    □ Count lib function usages (1-2 = inline, 3+ = inherit)
    □ Identify `with lib;` usage (generally discouraged)
    □ Check for project-specific lib utilities
    □ Note inconsistencies with project patterns
    ```

    **Module Structure Analysis:**
    ```
    □ Check imports/options/config organization
    □ Analyze parameter destructuring patterns
    □ Review let block placement (should be close to usage)
    □ Identify dead/unused variables
    ```

    **Conditional Logic Analysis:**
    ```
    □ Find if-then-else that could be mkIf/optionals
    □ Identify missing mkIf for conditional config blocks
    □ Check for unsafe attribute access
    □ Look for opportunities to use mkMerge
    ```

    **Options and Configuration Analysis:**
    ```
    □ Verify option namespacing follows project patterns
    □ Check option type definitions and defaults
    □ Analyze mkDefault vs literal defaults usage
    □ Review option descriptions and examples
    ```

    ### **Step 2.2: Priority Classification**
    **Classify each finding:**
    ```
    CRITICAL: Syntax errors, banned patterns, broken functionality
    HIGH: Major deviations from project conventions
    MEDIUM: General Nix best practice improvements
    LOW: Style and formatting consistency
    ```

    ## **PHASE 3: SYSTEMATIC REFACTORING**

    ### **Step 3.1: Critical Fixes First**
    ```
    Address in order:
    1. Syntax errors and evaluation failures
    2. Banned patterns (like `with lib;` if project forbids)
    3. Functionality-breaking issues
    ```

    ### **Step 3.2: Apply Flag-Specific Fixes**

    **--style-only flag:**
    ```
    □ Fix basic formatting and indentation
    □ Consistent attribute ordering
    □ String and list formatting
    □ Import organization
    SKIP: Logic changes, library usage, module restructuring
    ```

    **--fix-lib-usage flag:**
    ```
    □ Replace `with lib;` with appropriate patterns
    □ Convert single usage to inline `lib.function`
    □ Convert 3+ usage to `inherit (lib) func1 func2 func3;`
    □ Integrate project-specific lib utilities
    □ Maintain consistent patterns across similar files
    ```

    **--fix-let-blocks flag:**
    ```
    □ Move let bindings closer to usage points
    □ Remove unused variables from let blocks
    □ Split large let blocks into focused scopes
    □ Optimize let block evaluation performance
    □ Maintain readability while reducing scope
    ```

    **--fix-options flag:**
    ```
    □ Apply project option namespacing (e.g., khanelinix.*)
    □ Fix option type definitions and validation
    □ Improve option descriptions and examples
    □ Consistent default value patterns (mkDefault usage)
    □ Proper option organization and grouping
    ```

    **--fix-modules flag:**
    ```
    □ Standardize module parameter destructuring
    □ Organize imports/options/config sections consistently
    □ Apply project-specific module organization patterns
    □ Fix module composition and reuse patterns
    □ Ensure proper separation of concerns
    ```

    **No flags (comprehensive):**
    ```
    Apply ALL above fixes in logical order:
    1. Critical fixes
    2. Library usage optimization
    3. Module structure improvements
    4. Options and configuration fixes
    5. Let block optimization
    6. Style and formatting
    ```

    ### **Step 3.3: Detailed Refactoring Patterns**

    **Library Usage Transformations:**
    ```nix
    # BEFORE: with lib; (discouraged pattern)
    { config, lib, pkgs, ... }: with lib; {
      options.example = mkOption { type = types.bool; };
      config = mkIf config.example {
        services.foo = mkIf config.foo { enable = true; };
        services.bar = mkIf config.bar { enable = true; };
        environment.systemPackages = optional config.example pkgs.git;
      };
    }

    # AFTER: Mixed approach - count each function individually
    { config, lib, pkgs, ... }:
    let
      inherit (lib) mkIf;  # Used 3 times = inherit
    in {
      options.example = lib.mkOption { type = lib.types.bool; };  # Used once = inline
      config = mkIf config.example {
        services.foo = mkIf config.foo { enable = true; };
        services.bar = mkIf config.bar { enable = true; };
        environment.systemPackages = lib.optional config.example pkgs.git;  # Used once = inline
      };
    }
    ```

    **Conditional Logic Improvements:**
    ```nix
    # BEFORE: if-then-else
    config = if cfg.enable then {
      services.example.enable = true;
      environment.systemPackages = [ pkgs.example ];
    } else {};

    # AFTER: mkIf
    config = lib.mkIf cfg.enable {
      services.example.enable = true;
      environment.systemPackages = [ pkgs.example ];
    };
    ```

    **Let Block Optimization:**
    ```
    BEFORE: distant let block with unused variables
    let
      configFile = writeText "config" cfg.configText;
      pkg = pkgs.example;
      unused = "never used";
    in {
      options = { ... };
      config = {
        systemd.services.example.serviceConfig.ExecStart = "...";
      };
    }

    AFTER: scoped let block, unused variables removed
    {
      options = { ... };
      config = let
        configFile = writeText "config" cfg.configText;
        pkg = pkgs.example;
      in {
        systemd.services.example.serviceConfig.ExecStart = "...";
      };
    }
    ```

    ## **PHASE 4: VALIDATION AND FORMATTING**

    ### **Step 4.1: Functionality Verification**
    ```
    FOR each modified file:
        Run: nix-instantiate --parse <file>
        Check for syntax errors
        IF file defines packages/modules:
            Run: nix eval --file <file> (basic evaluation test)
    ```

    ### **Step 4.2: Formatting Application**
    ```
    Run: nix fmt
    This applies treefmt with nixfmt, deadnix, statix for consistent formatting
    ```

    ### **Step 4.3: Final Validation**
    ```
    FOR each modified file:
        Re-read to verify changes applied correctly
        Check that original functionality is preserved
        Ensure formatting is consistent with project style
    ```

    ## **COMMAND EXECUTION EXAMPLES**

    ```bash
    # Refactor specific file with comprehensive fixes
    /nix-refactor modules/home/programs/git/default.nix

    # Fix only library usage in directory
    /nix-refactor modules/nixos/ --fix-lib-usage

    # Style-only formatting for all files
    /nix-refactor . --style-only

    # Comprehensive module structure and options fixes
    /nix-refactor modules/ --fix-modules --fix-options
    ```

    ## **ERROR HANDLING AND RECOVERY**

    **If refactoring fails:**
    1. **Document the failure** - what pattern couldn't be applied and why
    2. **Preserve original** - ensure no partial changes break functionality
    3. **Report conflicts** - explain when project patterns conflict with best practices
    4. **Suggest alternatives** - provide manual fix recommendations when automation fails

    **Quality assurance:**
    - Always test syntax after changes
    - Preserve all original functionality
    - Maintain code readability and maintainability
    - Follow project conventions over generic patterns
    - Document any deviations or compromises made

    **REMEMBER:** The goal is systematic, reliable improvement while respecting project patterns and preserving functionality.
  '';
}
