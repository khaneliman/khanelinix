let
  commandName = "generate-docs";
  description = "Generate documentation comments for code based on implementation analysis";
  allowedTools = "Read, Grep, Glob, Write, Edit";
  argumentHint = "<file-path> [--format=jsdoc|docstring|rustdoc|xmldoc] [--level=public|all]";
  prompt = ''
    Analyze code and generate clear, useful documentation comments.

    **Workflow:**

    1. **Code Analysis**:
       - Read and understand the code's purpose
       - Identify parameters, return values, and side effects
       - Note any exceptions or error conditions
       - Find usage examples in tests or other code

    2. **Documentation Design**:
       - Write clear, concise descriptions
       - Document all parameters with types and descriptions
       - Document return values and their meaning
       - Note any preconditions or postconditions

    3. **Format Application**:
       - Use the correct documentation format for the language
       - Follow project conventions if present
       - Include code examples where helpful
       - Add cross-references to related code

    **Format Examples:**

    - **JSDoc (TypeScript/JavaScript)**:
      ```typescript
      /**
       * Brief description of what the function does.
       *
       * @param paramName - Description of the parameter
       * @returns Description of return value
       * @throws {ErrorType} When error condition occurs
       */
      function example(paramName: string): ReturnType {
        ...
      }
      ```

    - **Python Docstring**:
      ```python
      def example(param_name: str) -> ReturnType:
          """
          Brief description.

          Args:
              param_name: Description of the parameter.

          Returns:
              Description of return value.
          """
      ```

    - **Rust Doc Comments**:
      ```rust
      /// Brief description.
      ///
      /// # Arguments
      /// * `param_name` - Description of the parameter
      ///
      /// # Returns
      /// Description of return value
      pub fn example(param_name: String) -> ReturnType {
          ...
      }
      ```

    **Output Format:**

    ```markdown
    # Documentation Update

    ## Summary
    - [X] functions documented
    - [Y] parameters covered

    ## Changes Made
    - `path/to/file.ts:42` - Added JSDoc for `functionName`

    ## Notes
    - [Any special considerations]
    ```

    **Command Arguments:**
    - `<file-path>`: File or directory to document
    - `--format=jsdoc`: JSDoc (default)
    - `--format=docstring`: Python docstrings
    - `--format=rustdoc`: Rust doc comments
    - `--format=xmldoc`: XML documentation (C#)
    - `--level=public`: Public API only (default)
    - `--level=all`: Include internal functions

    Document what the code does and how to use it, not how it is implemented.
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
