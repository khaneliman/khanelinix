let
  commandName = "nix-refactor";
  description = "Automatically fix Nix code style violations and refactor patterns according to project conventions";
  allowedTools = "Read, Edit, MultiEdit, Grep, Bash(nix fmt), Task";
  argumentHint = "[path] [--style-only] [--fix-let-blocks] [--fix-lib-usage] [--fix-options] [--fix-modules]";
  prompt = ''
    Analyze and improve Nix code while preserving functionality and respecting project conventions.

    ## **WORKFLOW OVERVIEW**

    This command follows a systematic 4-phase approach:
    1. **Discovery** - Understand project patterns and analyze target code
    2. **Analysis** - Identify violations and improvement opportunities
    3. **Refactoring** - Apply fixes in priority order based on flags
    4. **Validation** - Ensure changes work and format consistently

    ## **PHASE 1: DISCOVERY AND CONTEXT**

    ### **Step 1.1: Project Pattern Analysis**
    - Read existing Nix modules to identify style conventions
    - Check for project-specific rules (AGENTS.md, CLAUDE.md)
    - Identify common helper functions and patterns

    ### **Step 1.2: Target Analysis**
    - Identify the file(s) to refactor
    - Determine current style violations
    - Map out dependencies and imports

    ## **PHASE 2: VIOLATION IDENTIFICATION**

    ### **Step 2.1: Style Violations**
    - Detect `with lib;` usage
    - Identify long lines or dense attribute sets
    - Check for inconsistent formatting

    ### **Step 2.2: Structural Issues**
    - Detect nested option groups
    - Find repeated patterns that should be abstracted
    - Identify ambiguous or inconsistent naming

    ## **PHASE 3: REFACTORING**

    ### **Step 3.1: Apply Fixes**
    - Use `--style-only` for formatting-only changes
    - Use `--fix-let-blocks` for local bindings cleanup
    - Use `--fix-lib-usage` to remove `with lib;`
    - Use `--fix-options` to align option naming
    - Use `--fix-modules` to align module structure

    ## **PHASE 4: VALIDATION**

    - Run `nix fmt` after changes
    - Run `nix flake check` if appropriate

    **Command Arguments:**
    - `[path]`: File or directory to refactor
    - `--style-only`: Only fix formatting
    - `--fix-let-blocks`: Normalize let bindings
    - `--fix-lib-usage`: Remove `with lib;` patterns
    - `--fix-options`: Normalize option definitions
    - `--fix-modules`: Normalize module structure

    Prefer minimal, safe changes and verify each refactor.
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
