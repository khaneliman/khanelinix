{
  extract-interface = ''
    ---
    allowed-tools: Read, Grep, Glob, Write
    argument-hint: "<file-path> [--output=file] [--style=types|interface|abstract]"
    description: Extract interface, types, or abstract definitions from implementation code
    ---

    Extract clean interfaces and type definitions from implementation code.

    **Workflow:**

    1. **Implementation Analysis**:
       - Read the source implementation
       - Identify public methods and properties
       - Determine input and output types
       - Note optional vs required members

    2. **Interface Design**:
       - Extract public API surface
       - Remove implementation details
       - Generalize where appropriate
       - Consider existing type patterns in codebase

    3. **Type Refinement**:
       - Use precise types (not `any` or `object`)
       - Add generics where beneficial
       - Document type constraints
       - Consider discriminated unions for variants

    4. **Output Generation**:
       - Generate clean interface/type definitions
       - Include JSDoc/documentation comments
       - Follow project naming conventions
       - Suggest file location if creating new file

    **Extraction Patterns:**

    - **TypeScript Interface**:
      ```typescript
      export interface IServiceName {
        methodName(param: ParamType): ReturnType;
        readonly propertyName: PropertyType;
      }
      ```

    - **TypeScript Types**:
      ```typescript
      export type ServiceConfig = {
        option1: string;
        option2?: number;
      };

      export type ServiceResult<T> = {
        data: T;
        error?: Error;
      };
      ```

    - **Rust Trait**:
      ```rust
      pub trait ServiceTrait {
          fn method_name(&self, param: ParamType) -> ReturnType;
      }
      ```

    - **Python Protocol**:
      ```python
      from typing import Protocol

      class ServiceProtocol(Protocol):
          def method_name(self, param: ParamType) -> ReturnType: ...
      ```

    **Output Format:**

    ```markdown
    # Extracted Interface for [ClassName]

    ## Interface Definition
    ```[language]
    [Generated interface code]
    ```

    ## Supporting Types
    ```[language]
    [Related type definitions]
    ```

    ## Usage Example
    ```[language]
    [How to use the interface]
    ```

    ## Notes
    - [Any important considerations]
    ```

    **Command Arguments:**
    - `<file-path>`: File containing implementation
    - `--output=file`: Write interface to specified file
    - `--style=types`: Generate type aliases
    - `--style=interface`: Generate interface (default)
    - `--style=abstract`: Generate abstract class

    Extract interfaces that are stable, minimal, and represent the essential contract.
  '';
}
