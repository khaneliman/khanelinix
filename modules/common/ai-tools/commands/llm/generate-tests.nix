{
  generate-tests = ''
    ---
    allowed-tools: Read, Grep, Glob, Write, Edit
    argument-hint: "<file-path> [--framework=jest|pytest|cargo|xunit] [--coverage=basic|comprehensive]"
    description: Analyze code and generate test cases covering key functionality and edge cases
    ---

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
    | Unit | Single function/method in isolation |
    | Integration | Multiple components working together |
    | Edge Cases | Boundary conditions, empty/null inputs |
    | Error Handling | Expected errors are thrown/returned |
    | Regression | Specific bug prevention |

    **Framework Patterns:**

    - **Jest (TypeScript/JavaScript)**:
      ```typescript
      describe('functionName', () => {
        it('should do X when Y', () => {
          expect(result).toBe(expected);
        });

        // For async functions
        it('should do X when Y (async)', async () => {
          const result = await asyncFunction();
          expect(result).toBe(expected);
        });
      });
      ```

    - **pytest (Python)**:
      ```python
      def test_function_does_x_when_y():
          assert result == expected

      # For async functions
      @pytest.mark.asyncio
      async def test_async_function_does_x_when_y():
          result = await async_function()
          assert result == expected
      ```

    - **Cargo (Rust)**:
      ```rust
      #[test]
      fn test_function_does_x_when_y() {
          assert_eq!(result, expected);
      }

      // For async functions (requires tokio test runtime)
      #[tokio::test]
      async fn test_async_function_does_x_when_y() {
          let result = async_function().await;
          assert_eq!(result, expected);
      }
      ```

    **Command Arguments:**
    - `<file-path>`: File containing code to test
    - `--framework=jest|pytest|cargo|xunit`: Testing framework to use
    - `--coverage=basic`: Essential happy path tests only
    - `--coverage=comprehensive`: Include edge cases, errors, and integration

    Generate tests that are maintainable, readable, and actually catch bugs.
  '';
}
