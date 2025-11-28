{
  option-migrate = ''
    ---
    allowed-tools: Read, Edit, MultiEdit, Grep
    argument-hint: "<old-key> <new-key> [--dry-run] [--with-aliases]"
    description: Help migrate configuration keys/options to new format across the project
    ---

    Safely migrate configuration keys/options to a new structure while preserving functionality.

    **Workflow:**

    1. **Usage Discovery - Find All Reference Points**:
       - Use grep/rg to find all usages of <old-option> throughout the codebase
       - Identify all configuration files that reference the old option/key
       - Find both definitions and references across all relevant files
       - Map out any related or dependent configurations that might also need migration

    2. **Migration Planning - Analyze Impact**:
       - Generate a comprehensive migration plan showing all files and lines that need changes
       - Identify potential conflicts or issues with the new structure
       - If --dry-run is specified, show exactly what changes would be made without applying them
       - Plan for backup and rollback procedures for complex migrations

    3. **Automated Migration Execution**:
       - Update configuration definitions to use the new <new-option> structure
       - Migrate all references from old to new configuration paths/keys
       - Update any documentation, comments, or examples that reference the old path
       - Preserve all functionality, defaults, and type definitions exactly

    4. **Backward Compatibility (if --with-aliases)**:
       - Create compatibility mappings that support old configuration paths
       - Ensure existing configurations continue to work without changes
       - Add deprecation warnings for the old configuration paths
       - Document the migration path for users

    5. **Validation and Verification**:
       - Verify that all references have been successfully updated
       - Run basic validation checks to ensure configurations still parse/load
       - Test that the migrated functionality works identically to before
       - Generate a summary report of all changes made

    **Command Arguments:**
    - <old-option>: Current configuration path/key that needs to be migrated
    - <new-option>: New configuration path/key structure
    - --dry-run: Preview all changes without applying them
    - --with-aliases: Create backward compatibility mappings for smooth transition

    Ensure zero-disruption migrations that preserve all existing functionality.
  '';
}
