let
  commandName = "option-migrate";
  description = "Help migrate configuration keys/options to new format across the project";
  allowedTools = "Read, Edit, MultiEdit, Grep";
  argumentHint = "<old-key> <new-key> [--dry-run] [--with-aliases]";
  prompt = ''
    Safely migrate configuration keys/options to a new structure while preserving functionality.

    **Workflow:**

    1. **Usage Discovery - Find All Reference Points**:
       - Use grep/rg to find all usages of <old-option> throughout the codebase
       - Identify all configuration files that reference the old option/key
       - Find both definitions and references across all relevant files
       - Map out any related or dependent configurations that might also need migration

    2. **Migration Planning - Analyze Impact**:
       - Generate a comprehensive migration plan showing all files and lines that need changes
       - Identify ordering dependencies (definitions before usage)
       - Determine if aliases or compatibility layers are needed

    3. **Implementation - Apply Changes**:
       - Update option definitions to the new key
       - Update all references and documentation
       - Add alias options if --with-aliases is specified
       - Ensure all changes are consistent

    4. **Validation**:
       - Review changes for correctness
       - Run relevant build or evaluation checks if possible

    **Output Format:**

    ```markdown
    ## Option Migration Plan

    ### Summary
    - Old key: `<old-key>`
    - New key: `<new-key>`
    - Files impacted: X

    ### Planned Changes
    - `path/to/file:line` - update option usage

    ### Notes
    - [Any migration risks or warnings]
    ```

    **Command Arguments:**
    - `<old-key>`: Existing option/key to migrate
    - `<new-key>`: New option/key to use
    - `--dry-run`: Show changes without applying
    - `--with-aliases`: Add alias options for backward compatibility

    Ensure a safe migration path and avoid breaking changes.
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
