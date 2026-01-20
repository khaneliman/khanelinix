let
  commandName = "generate-tests";
  description = "Analyze code and generate test cases covering key functionality and edge cases";
  allowedTools = "Read, Grep, Glob, Write, Edit";
  argumentHint = "<file-path> [--framework=jest|pytest|cargo|xunit] [--coverage=basic|comprehensive]";
  prompt = ''
    Analyze code and generate comprehensive, idiomatic test cases.

    **Workflow:**

    1. **Code Analysis**:
       - Read the target file(s)
       - Identify functions, methods, and classes to test
       - Understand input types, return types, and side effects
       - Note dependencies that may need mocking

    2. **Test Case Design**:
       - Identify happy path scenarios
       - Design edge case tests (empty inputs, nulls, boundaries)
       - Plan error condition tests
       - Consider integration test scenarios if applicable

    3. **Test Structure**:
       - Follow project's existing test patterns if present
       - Group tests logically (by function, by behavior)
       - Use descriptive test names that explain the scenario
       - Include setup/teardown as needed

    4. **Test Implementation**:
       - Write tests using the appropriate framework
       - Include assertions for expected outcomes
       - Add comments explaining non-obvious test logic
       - Ensure tests are independent and deterministic

    **Test Categories:**

    | Category | Description |
    |----------|-------------|
    | Happy Path | Expected inputs/outputs |
    | Edge Cases | Boundaries, nulls, empties |
    | Error Cases | Invalid input, exceptions |
    | Integration | Interactions with dependencies |

    **Output Format:**

    ```markdown
    # Test Plan for [file]

    ## Summary
    - [X] tests generated
    - [Y] edge cases covered

    ## Tests

    ### [Test Group 1]
    ```[language]
    [Test code]
    ```

    ### [Test Group 2]
    ```[language]
    [Test code]
    ```

    ## Notes
    - [Any setup or mocking considerations]
    ```

    **Command Arguments:**
    - `<file-path>`: File or directory to test
    - `--framework=jest`: JavaScript/TypeScript (default)
    - `--framework=pytest`: Python
    - `--framework=cargo`: Rust
    - `--framework=xunit`: .NET
    - `--coverage=basic`: Core behaviors (default)
    - `--coverage=comprehensive`: Include edge cases and error paths

    Generate tests that are realistic, maintainable, and aligned with project style.
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
