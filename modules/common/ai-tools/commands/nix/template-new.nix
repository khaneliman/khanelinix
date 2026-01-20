let
  commandName = "template-new";
  description = "Systematic development template creation following project patterns and best practices";
  allowedTools = "Write, Read, Edit, Bash(mkdir*), Bash(cp*), Bash(chmod*), Bash(nix*), Grep, Task";
  argumentHint = "<name> [--type=project|library|api|webapp] [--language=rust|go|node|python|nix] [--interactive] [--with-ci] [--with-docs]";
  prompt = ''
    Create production-ready development templates that integrate with existing project infrastructure.

    ## **WORKFLOW OVERVIEW**

    This command follows a 4-phase systematic approach:
    1. **Discovery** - Analyze project structure and existing template patterns
    2. **Planning** - Design template specification and requirements
    3. **Generation** - Create comprehensive template with all components
    4. **Validation** - Test template functionality and integration

    ## **PHASE 1: PROJECT DISCOVERY AND PATTERN ANALYSIS**

    ### **Step 1.1: Template Pattern Review**
    - Identify existing templates in the repository
    - Note common structure, files, and conventions
    - Determine build system and tooling patterns

    ### **Step 1.2: Requirements Gathering**
    - Determine target project type and language
    - Identify required dependencies and tooling
    - Decide on CI, docs, and testing scaffolding

    ## **PHASE 2: TEMPLATE DESIGN**

    ### **Step 2.1: Template Layout**
    - Define directory structure
    - Identify core files and configs
    - Decide on language-specific tooling

    ### **Step 2.2: Automation Setup**
    - Integrate with existing Nix flake templates
    - Add CI and formatting hooks if requested

    ## **PHASE 3: TEMPLATE GENERATION**

    - Scaffold directories and core files
    - Populate boilerplate and configuration
    - Ensure file permissions and executables are correct

    ## **PHASE 4: VALIDATION**

    - Test template generation
    - Validate flake or build configuration
    - Ensure README or docs exist if requested

    **Command Arguments:**
    - `<name>`: Template name or project name
    - `--type=project`: Standard app template (default)
    - `--type=library`: Library-focused template
    - `--type=api`: API service template
    - `--type=webapp`: Web application template
    - `--language=rust`: Rust template
    - `--language=go`: Go template
    - `--language=node`: Node.js template
    - `--language=python`: Python template
    - `--language=nix`: Nix module template
    - `--interactive`: Ask for confirmation at each step
    - `--with-ci`: Include CI scaffolding
    - `--with-docs`: Include README/docs boilerplate

    Ensure templates follow repository conventions and integrate with Nix tooling.
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
