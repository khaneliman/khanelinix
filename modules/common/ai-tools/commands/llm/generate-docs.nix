{
  generate-docs = ''
    ---
    allowed-tools: Read, Grep, Glob, Write, Edit
    argument-hint: "<file-path> [--format=jsdoc|docstring|rustdoc|xmldoc] [--level=public|all]"
    description: Generate documentation comments for code based on implementation analysis
    ---

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
       * @example
       * const result = myFunction('input');
       */
      ```

    - **Python Docstring**:
      ```python
      """Brief description of what the function does.

      Args:
          param_name: Description of the parameter.

      Returns:
          Description of return value.

      Raises:
          ErrorType: When error condition occurs.

      Example:
          >>> my_function('input')
          'output'
      """
      ```

    - **Rustdoc**:
      ```rust
      /// Brief description of what the function does.
      ///
      /// # Arguments
      ///
      /// * `param_name` - Description of the parameter
      ///
      /// # Returns
      ///
      /// Description of return value
      ///
      /// # Examples
      ///
      /// ```
      /// let result = my_function("input");
      /// ```
      ```

    - **XML Doc (C#)**:
      ```csharp
      /// <summary>
      /// Brief description of what the function does.
      /// </summary>
      /// <param name="paramName">Description of the parameter.</param>
      /// <returns>Description of return value.</returns>
      /// <exception cref="ErrorType">When error condition occurs.</exception>
      ```

    **Command Arguments:**
    - `<file-path>`: File to document
    - `--format=jsdoc|docstring|rustdoc|xmldoc`: Documentation format
    - `--level=public`: Only document public/exported items (default)
    - `--level=all`: Document all items including private

    Write documentation that helps developers USE the code, not just repeat what it does.
  '';
}
