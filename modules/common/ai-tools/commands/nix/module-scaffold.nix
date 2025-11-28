{
  module-scaffold = ''
    ---
    allowed-tools: Write, Read, Edit, Grep, Bash(nix fmt), Task
    argument-hint: "<module-path> [--type=home|nixos|darwin] [--namespace] [--with-options] [--template=basic|advanced]"
    description: Generate new Nix module boilerplate following project conventions with comprehensive pattern analysis
    ---

    Generate Nix modules that seamlessly integrate with existing project patterns and conventions.

    ## **WORKFLOW OVERVIEW**

    This command follows a 4-phase systematic approach:
    1. **Discovery** - Analyze project structure and existing module patterns
    2. **Planning** - Determine module specifications and template requirements
    3. **Generation** - Create module following discovered conventions
    4. **Integration** - Validate and format the generated module

    ## **PHASE 1: PROJECT DISCOVERY AND PATTERN ANALYSIS**

    ### **Step 1.1: Project Context Detection**
    ```
    ALWAYS START - Understand the project structure and conventions
    ```

    **Project type detection:**
    - Check if we're in khanelinix repository (look for specific directory structure)
    - Identify if it's a flake-based project (flake.nix present)
    - Determine if it's NixOS, Home Manager, or Darwin focused

    **Module type inference from path:**
    ```
    IF path contains "modules/home/" OR "home-manager/":
        Default type = "home"
    ELSE IF path contains "modules/nixos/" OR "nixos/":
        Default type = "nixos"  
    ELSE IF path contains "modules/darwin/" OR "darwin/":
        Default type = "darwin"
    ELSE:
        Use --type flag or prompt for clarification
    ```

    ### **Step 1.2: Existing Module Pattern Analysis**
    **Systematic pattern discovery:**
    ```
    FOR the determined module type:
        Find 3-5 representative existing modules in similar paths
        Analyze each module for:
          - Function signature patterns
          - Library usage conventions (inherit vs inline)
          - Option namespace patterns
          - Conditional logic patterns (mkIf usage)
          - Let block placement and scoping
          - Configuration structure and organization
          - Documentation and comment styles
    ```

    **Pattern documentation:**
    ```
    Record discovered patterns:
      - Common function signature: { config, lib, pkgs, ... }: vs variations
      - Namespace pattern: namespace.moduleName.option vs other patterns
      - Library usage: inherit (lib) list vs inline lib.function usage
      - Config structure: immediate config vs let-based config
      - Option types: commonly used types and validation patterns
      - Documentation: option descriptions and example patterns
    ```

    ### **Step 1.3: Project-Specific Convention Analysis**
    ```
    IF khanelinix project detected:
        Launch Task with Dotfiles Expert: "Provide khanelinix module scaffolding patterns including namespace conventions, option organization, library usage, and template structures for [MODULE_TYPE] modules"
    ELSE:
        Use discovered patterns from existing module analysis
        Check for project-specific configuration files or documentation
    ```

    ## **PHASE 2: MODULE SPECIFICATION PLANNING**

    ### **Step 2.1: Module Specification Assembly**
    **Determine module specifications:**
    ```
    Module path: <module-path> (provided)
    Module type: --type flag OR inferred from path OR analyzed from project
    Namespace: --namespace flag OR discovered pattern OR project default
    Template: --template flag OR "basic" default
    Options detail: --with-options flag determines comprehensive vs minimal options
    ```

    ### **Step 2.2: Template Content Planning**
    **Basic template content:**
    ```
    - Simple enable option (bool type)
    - Minimal config block with mkIf conditional
    - Essential imports only
    - Basic documentation
    - Following discovered lib usage patterns
    ```

    **Advanced template content:**
    ```
    - Comprehensive option set with multiple types
    - Complex config with multiple conditionals
    - Proper imports and dependencies
    - Detailed documentation and examples
    - Advanced patterns like submodules or custom types
    ```

    ### **Step 2.3: Validation of Specifications**
    ```
    Verify specifications make sense:
      - Module path is valid and doesn't conflict with existing files
      - Namespace follows project conventions
      - Template complexity matches intended use
      - Module type aligns with path location
    ```

    ## **PHASE 3: SYSTEMATIC MODULE GENERATION**

    ### **Step 3.1: Directory and File Setup**
    ```
    1. Ensure parent directories exist:
       mkdir -p $(dirname <module-path>)

    2. Check for existing file conflicts:
       IF file exists: confirm overwrite OR abort

    3. Prepare for module creation with discovered patterns
    ```

    ### **Step 3.2: Module Content Generation**
    **Function signature generation:**
    ```
    Use discovered pattern, typically:
    { config, lib, pkgs, ... }:
    OR
    { config, lib, pkgs, options, ... }:  # if options used

    Apply project-specific variations found in pattern analysis
    ```

    **Library usage application:**
    ```
    Based on discovered patterns:

    IF project uses inherit pattern:
        let
          inherit (lib) mkIf mkOption mkEnableOption types;
        in

    ELSE IF project uses inline pattern:
        Use lib.mkIf, lib.mkOption, etc. throughout
        
    ELSE (mixed usage based on frequency):
        Apply mixed pattern per project analysis
    ```

    **Options generation:**
    ```
    Basic template options:
      enable = mkEnableOption "description";
      
    Advanced template options:
      enable = mkEnableOption "description";
      package = mkOption { type = types.package; default = pkgs.default; };
      settings = mkOption { type = types.attrs; default = {}; };
      extraConfig = mkOption { type = types.lines; default = ""; };

    Apply discovered namespace pattern:
      options.[namespace].[module-name] = { ... };
    ```

    **Config block generation:**
    ```
    Basic template:
    config = lib.mkIf cfg.enable {
      # Basic configuration
    };

    Advanced template:
    config = lib.mkIf cfg.enable {
      # Comprehensive configuration with multiple sections
      # Following discovered organizational patterns
    };
    ```

    ### **Step 3.3: Documentation and Comments**
    **Include appropriate documentation:**
    ```
    IF --with-options flag:
        Add comprehensive option descriptions
        Include usage examples in comments
        Add common configuration patterns as comments
        
    ALWAYS:
        Add module purpose comment at top
        Include basic usage example
        Follow project documentation style
    ```

    ## **PHASE 4: INTEGRATION AND VALIDATION**

    ### **Step 4.1: Module File Creation**
    ```
    Write the generated module to <module-path>
    Ensure proper file permissions and ownership
    ```

    ### **Step 4.2: Formatting and Style Application**
    ```
    Run: nix fmt <module-path>
    This applies project formatting standards (treefmt/nixfmt)
    ```

    ### **Step 4.3: Validation and Testing**
    ```
    1. Syntax validation:
       nix-instantiate --parse <module-path>
       
    2. Basic evaluation test:
       nix eval --file <module-path>
       
    3. Integration verification:
       Check that module can be imported without errors
    ```

    ### **Step 4.4: Usage Guidance**
    ```
    Provide next steps:
      - How to import the module
      - Basic configuration examples
      - Where to add the module to project imports
      - Common options to configure
    ```

    ## **TEMPLATE EXAMPLES**

    **Basic Template Structure:**
    ```nix
    { config, lib, pkgs, ... }:
    let
      cfg = config.[namespace].[module-name];
    in {
      options.[namespace].[module-name] = {
        enable = lib.mkEnableOption "[description]";
      };
      
      config = lib.mkIf cfg.enable {
        # Basic configuration here
      };
    }
    ```

    **Advanced Template Structure:**
    ```nix
    { config, lib, pkgs, ... }:
    let
      inherit (lib) mkIf mkOption mkEnableOption types;
      cfg = config.[namespace].[module-name];
    in {
      options.[namespace].[module-name] = {
        enable = mkEnableOption "[description]";
        package = mkOption {
          type = types.package;
          default = pkgs.[package];
          description = "Package to use";
        };
        settings = mkOption {
          type = types.attrs;
          default = {};
          description = "Configuration settings";
        };
      };
      
      config = mkIf cfg.enable {
        # Comprehensive configuration
      };
    }
    ```

    ## **ERROR HANDLING AND EDGE CASES**

    **Handle common issues:**
    ```
    - Path conflicts with existing files
    - Invalid module paths or names
    - Missing project context for pattern detection
    - Namespace conflicts with existing options
    - Template complexity mismatches with intended use
    ```

    **Recovery strategies:**
    ```
    - Offer alternative paths for conflicts
    - Provide fallback patterns when project analysis fails
    - Validate generated modules before completion
    - Offer to regenerate with different specifications
    ```

    ## **USAGE EXAMPLES**

    ```bash
    # Generate basic home manager module
    /module-scaffold modules/home/programs/example/default.nix

    # Generate advanced NixOS module with comprehensive options
    /module-scaffold modules/nixos/services/myservice.nix --template=advanced --with-options

    # Generate Darwin module with custom namespace
    /module-scaffold modules/darwin/homebrew/custom.nix --namespace=myproject --type=darwin
    ```

    **REMEMBER:** Always prioritize consistency with existing project patterns while ensuring the generated module is functional, well-documented, and follows established conventions.
  '';
}
