{
  template-new = ''
    ---
    allowed-tools: Write, Read, Edit, Bash(mkdir*), Bash(cp*), Bash(chmod*), Bash(nix*), Grep, Task
    argument-hint: "<name> [--type=project|library|api|webapp] [--language=rust|go|node|python|nix] [--interactive] [--with-ci] [--with-docs]"
    description: Systematic development template creation following project patterns and best practices
    ---

    Create production-ready development templates that integrate with existing project infrastructure.

    ## **WORKFLOW OVERVIEW**

    This command follows a 4-phase systematic approach:
    1. **Discovery** - Analyze project structure and existing template patterns
    2. **Planning** - Design template specification and requirements
    3. **Generation** - Create comprehensive template with all components
    4. **Validation** - Test template functionality and integration

    ## **PHASE 1: PROJECT DISCOVERY AND PATTERN ANALYSIS**

    ### **Step 1.1: Project Context Analysis**
    ```
    ALWAYS START - Understand the target environment and existing patterns
    ```

    **Project structure analysis:**
    - Check if we're in a flake-based Nix project (templates/ directory expected)
    - Identify existing template patterns and organization
    - Analyze project's development infrastructure (CI/CD, tooling, patterns)
    - Determine integration requirements with project ecosystem

    **Template destination setup:**
    ```
    Template location determination:
      IF flake.nix present AND templates/ directory exists:
          Target: ./templates/<name>/
      ELSE IF traditional project:
          Target: ./<name>-template/
      ELSE:
          Target: ./templates/<name>/ (create templates/ if needed)
    ```

    ### **Step 1.2: Existing Template Pattern Analysis**
    **Systematic pattern discovery:**
    ```
    FOR existing templates in project:
        Analyze structure patterns:
          - Directory organization and naming conventions
          - flake.nix structure and output patterns
          - Development environment setup patterns
          - Build system configurations
          - Documentation and README structures
          - Welcome text and instruction patterns
    ```

    **Infrastructure integration analysis:**
    ```
    Check for project-wide patterns:
      - CI/CD pipeline templates and configurations
      - Development tooling and pre-commit setups
      - Documentation generation and styling
      - Testing framework preferences
      - Code quality and formatting standards
    ```

    ### **Step 1.3: Language Ecosystem Analysis**
    ```
    IF --language specified:
        Analyze language-specific requirements:
          - Package managers and dependency management
          - Build tools and compilation requirements
          - Testing frameworks and quality tools
          - Language-specific development environments
          - Runtime and deployment considerations
    ```

    ## **PHASE 2: TEMPLATE SPECIFICATION PLANNING**

    ### **Step 2.1: Template Requirements Assembly**
    **Core specifications:**
    ```
    Template name: <name> (required)
    Template type: --type (project|library|api|webapp) OR inferred from name
    Language: --language OR detected from project context
    Interactive mode: --interactive flag enables customization prompts
    CI integration: --with-ci flag includes pipeline configurations
    Documentation: --with-docs flag includes comprehensive docs setup
    ```

    **Type-specific requirements:**
    ```
    PROJECT template:
      - Complete application scaffold
      - Build system and dependency management
      - Testing and quality assurance setup
      - CI/CD pipeline integration
      - Development environment configuration
      - Deployment and distribution setup

    LIBRARY template:
      - Package/library structure
      - Distribution and publishing setup
      - API documentation generation
      - Version management
      - Testing and benchmarking
      - Example usage and integration guides

    API template:
      - Service/API framework setup
      - Database integration patterns
      - Authentication and authorization
      - API documentation (OpenAPI/Swagger)
      - Testing and validation
      - Containerization and deployment

    WEBAPP template:
      - Frontend framework and tooling
      - Asset management and bundling
      - Development server and hot reload
      - Testing (unit, integration, e2e)
      - Deployment and hosting setup
      - Performance and optimization tools
    ```

    ### **Step 2.2: Technology Stack Planning**
    **Language-specific stack assembly:**
    ```
    Based on --language, determine:
      - Primary development environment requirements
      - Package manager and dependency resolution
      - Build tools and compilation pipeline
      - Testing frameworks and quality tools
      - Development server and tooling
      - Production build and optimization
    ```

    **Integration requirements:**
    ```
    Determine integration needs:
      - Nix development shell configuration
      - Flake output structure and organization
      - Project-specific tooling and utilities
      - Pre-commit hooks and quality checks
      - IDE/editor configuration files
    ```

    ## **PHASE 3: SYSTEMATIC TEMPLATE GENERATION**

    ### **Step 3.1: Directory Structure Creation**
    ```
    Create template directory structure:
      1. Create base template directory: templates/<name>/
      2. Set up language-specific directory structure
      3. Create standard subdirectories (src/, tests/, docs/, etc.)
      4. Initialize configuration and metadata files
    ```

    ### **Step 3.2: Core Template Files Generation**
    **Flake configuration:**
    ```
    Generate flake.nix with:
      - Appropriate inputs for language/framework
      - Development shell with required tools
      - Build outputs for the template type
      - Template metadata and welcome text
      - Integration with project patterns
    ```

    **Build and dependency management:**
    ```
    Language-specific configurations:
      RUST: Cargo.toml, rust-toolchain, .cargo/config
      GO: go.mod, Makefile, .golangci.yml
      NODE: package.json, tsconfig.json, .nvmrc
      PYTHON: pyproject.toml, requirements.txt, setup.py
      NIX: default.nix, shell.nix, module structure
    ```

    **Development environment setup:**
    ```
    Create development infrastructure:
      - .envrc for direnv integration
      - .editorconfig for consistent formatting
      - .gitignore with language-specific exclusions
      - Pre-commit configuration and hooks
      - Development scripts and utilities
    ```

    ### **Step 3.3: Advanced Template Components**
    **Testing infrastructure:**
    ```
    Set up testing framework:
      - Unit test structure and examples
      - Integration test patterns
      - Performance/benchmark tests (if applicable)
      - Test configuration and scripts
      - CI/CD test pipeline integration
    ```

    **Documentation system:**
    ```
    IF --with-docs flag:
        Create documentation infrastructure:
          - README with comprehensive setup instructions
          - API documentation generation setup
          - User guides and tutorials structure
          - Contributing guidelines
          - Change log and release notes template
    ```

    **CI/CD integration:**
    ```
    IF --with-ci flag:
        Generate CI/CD configurations:
          - GitHub Actions / GitLab CI / etc.
          - Build, test, and deployment pipelines
          - Quality checks and automated reviews
          - Release automation and versioning
          - Security scanning and compliance
    ```

    ### **Step 3.4: Interactive Customization**
    ```
    IF --interactive flag:
        Prompt for customization:
          - Project metadata (author, description, license)
          - Specific tool preferences and configurations
          - Optional feature inclusions
          - Target deployment platforms
          - Integration preferences
    ```

    ## **PHASE 4: VALIDATION AND TESTING**

    ### **Step 4.1: Template Structure Validation**
    ```
    Validate template structure:
      1. Check flake.nix syntax: nix flake check
      2. Verify development shell: nix develop --command echo "test"
      3. Test template instantiation in temporary directory
      4. Validate build processes work correctly
    ```

    ### **Step 4.2: Functionality Testing**
    ```
    Comprehensive functionality tests:
      - Test all build commands and scripts
      - Verify development environment setup
      - Check testing framework functionality
      - Validate documentation generation
      - Test CI/CD pipeline configurations (if included)
    ```

    ### **Step 4.3: Integration Verification**
    ```
    Verify project integration:
      - Check template appears in flake outputs
      - Test template initialization from different locations
      - Verify integration with project development workflows
      - Check compatibility with existing project tooling
    ```

    ### **Step 4.4: Documentation and Welcome Message**
    ```
    Generate comprehensive documentation:
      - Template README with setup and usage instructions
      - Welcome message for flake template initialization
      - Example usage and common workflows
      - Troubleshooting guide and common issues
      - Links to relevant documentation and resources
    ```

    ## **TEMPLATE OUTPUT STRUCTURE**

    **Standard template organization:**
    ```
    templates/<name>/
    ├── flake.nix              # Template flake configuration
    ├── README.md              # Template documentation
    ├── .envrc                 # direnv configuration
    ├── .gitignore            # Language-specific gitignore
    ├── .editorconfig         # Editor configuration
    ├── src/                  # Source code structure
    ├── tests/                # Testing structure
    ├── docs/                 # Documentation (if --with-docs)
    ├── .github/workflows/    # CI/CD (if --with-ci)
    └── [language-specific files and directories]
    ```

    ## **ERROR HANDLING AND EDGE CASES**

    **Common issue handling:**
    ```
    - Template name conflicts with existing templates
    - Unsupported language/framework combinations
    - Missing project infrastructure for integration
    - Invalid template specifications or requirements
    - Template generation failures or incomplete setups
    ```

    **Recovery strategies:**
    ```
    - Offer alternative names for conflicting templates
    - Provide fallback configurations for unsupported setups
    - Guide users through manual integration steps
    - Validate all components before finalizing template
    - Provide rollback options for failed generations
    ```

    ## **USAGE EXAMPLES**

    ```bash
    # Create basic Rust project template
    /template-new rust-api --type=api --language=rust

    # Interactive webapp template with full features
    /template-new my-webapp --type=webapp --language=node --interactive --with-ci --with-docs

    # Simple library template
    /template-new utils-lib --type=library --language=python

    # Custom Nix module template
    /template-new nix-module --language=nix --with-docs
    ```

    **REMEMBER:** Create templates that provide a solid, production-ready foundation while integrating seamlessly with existing project patterns and development workflows.
  '';
}
