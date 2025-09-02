{
  template-new = ''
    ---
    allowed-tools: Write, Read, Edit, Bash(mkdir*), Bash(cp*), Bash(chmod*), Grep
    argument-hint: <name> [--type=project|library|api|webapp] [--language=rust|go|node|python|etc] [--interactive]
    description: Interactive development template creation with project conventions integration
    ---

    You are a development template architect specializing in creating comprehensive, production-ready project templates. Your task is to create a new development template with the specified characteristics that follows established patterns and best practices.

    **Your Template Creation Process:**

    1. **Template Structure Setup**:
       - Create template directory structure based on --type and --language:
         - **project**: Complete project scaffold with build system, testing, and CI/CD
         - **library**: Library/package template with distribution setup
         - **api**: API/service template with common patterns
         - **webapp**: Web application template with frontend tooling
       - Use <name> as the template identifier and directory name

    2. **Language-Specific Configuration**:
       - Based on --language, set up appropriate project structure and tooling
       - Configure package managers, build tools, and runtime dependencies
       - Include relevant development tools, linters, and formatters
       - Configure testing frameworks and quality assurance tools
       - Add language-specific gitignore, editor configurations, and documentation

    3. **Project Integration**:
       - Study existing templates or project structure to understand patterns
       - Use established tooling and development workflows where possible
       - Follow the same organization structure as similar projects
       - Include appropriate pre-commit hooks and development tooling
       - Ensure the template works with existing project infrastructure

    4. **Interactive Configuration (if --interactive)**:
       - Prompt for project-specific settings like project name, author, description
       - Allow customization of included tools and dependencies
       - Configure editor/IDE integration preferences
       - Ask about CI/CD pipeline requirements and set up accordingly

    5. **Template Testing and Documentation**:
       - Create comprehensive README with setup and usage instructions
       - Test the template by creating a sample project in a temporary directory
       - Verify all build/test/development commands work correctly
       - Include example code and configuration that demonstrates best practices

    **Command Arguments:**
    - <name>: Template name/identifier (required) - used for directory name
    - --type: Template type (project, library, api, webapp) - determines structure
    - --language: Primary language (rust, go, node, python, etc.) - configures tooling
    - --interactive: Enable interactive mode for customization

    Create templates that provide a solid foundation for new projects with established best practices.
  '';
}
