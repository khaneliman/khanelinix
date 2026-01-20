let
  commandName = "module-scaffold";
  description = "Generate new Nix module boilerplate following project conventions with comprehensive pattern analysis";
  allowedTools = "Write, Read, Edit, Grep, Bash(nix fmt), Task";
  argumentHint = "<module-path> [--type=home|nixos|darwin] [--namespace] [--with-options] [--template=basic|advanced]";
  prompt = ''
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

    ## **PHASE 2: REQUIREMENTS GATHERING AND PLANNING**

    ### **Step 2.1: Module Specification**
    - Determine module purpose and scope
    - Identify relevant existing modules for pattern matching
    - Decide on option hierarchy and naming
    - Plan configuration structure

    ### **Step 2.2: Option Design**
    - Use `khanelinix.*` namespace
    - Follow existing naming conventions
    - Include enable option by default
    - Add extra options as needed

    ## **PHASE 3: MODULE GENERATION**

    ### **Step 3.1: Template Selection**
    - Use basic template for simple modules
    - Use advanced template for complex configurations

    ### **Step 3.2: File Creation**
    - Create module file at specified path
    - Implement options section
    - Implement config section with `mkIf`

    ### **Step 3.3: Formatting and Validation**
    - Run `nix fmt`
    - Check module imports if needed

    ## **PHASE 4: INTEGRATION**

    - Suggest any necessary imports to wire the module in
    - Provide next steps (tests, rebuild commands)

    **Command Arguments:**
    - `<module-path>`: Path to new module file
    - `--type=home`: Generate Home Manager module
    - `--type=nixos`: Generate NixOS module
    - `--type=darwin`: Generate Darwin module
    - `--namespace`: Add option namespace (default: khanelinix)
    - `--with-options`: Generate additional options beyond enable
    - `--template=basic`: Basic module template
    - `--template=advanced`: Advanced module template

    Follow project conventions and keep modules minimal.
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
