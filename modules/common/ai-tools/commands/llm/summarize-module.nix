let
  commandName = "summarize-module";
  description = "Generate concise summary of module's purpose, API, and usage patterns";
  allowedTools = "Read, Grep, Glob";
  argumentHint = "<module-path> [--include-private] [--with-examples]";
  prompt = ''
    Produce concise, actionable summaries of code modules.

    **Workflow:**

    1. **Module Discovery**:
       - Read the main module file(s)
       - Identify exports and public API
       - Find types, interfaces, and constants
       - Check for README or existing docs

    2. **API Extraction**:
       - List all exported functions with signatures
       - Document exported types and interfaces
       - Note configuration options and defaults
       - Identify factory functions and constructors

    3. **Pattern Recognition**:
       - Identify common usage patterns
       - Find example usages in tests or docs
       - Note required vs optional parameters
       - Document return types and error conditions

    4. **Generate Summary**:
       - One-paragraph module description
       - Quick reference API table
       - Usage examples
       - Common gotchas or notes

    **Output Format:**

    ```markdown
    # [Module Name]

    > [One-line description]

    ## Quick Start
    ```[language]
    [Minimal usage example]
    ```

    ## API Reference

    ### Functions
    | Function | Description |
    |----------|-------------|
    | `functionName(args)` | What it does |

    ### Types
    | Type | Description |
    |------|-------------|
    | `TypeName` | What it represents |

    ## Examples

    ### [Use Case 1]
    ```[language]
    [Example code]
    ```

    ## Notes
    - [Important consideration 1]
    - [Important consideration 2]
    ```

    **Command Arguments:**
    - `<module-path>`: Path to module file or directory
    - `--include-private`: Include non-exported/internal items
    - `--with-examples`: Include more detailed usage examples

    Focus on what developers need to USE the module, not how it's implemented internally.
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
