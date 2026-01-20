let
  commandName = "explain-code";
  description = "Generate detailed explanation of code section for understanding or documentation";
  allowedTools = "Read, Grep, Glob";
  argumentHint = "<file-path> [--depth=shallow|deep] [--focus=logic|types|flow]";
  prompt = ''
    Analyze code and produce clear explanations suitable for documentation or onboarding.

    **Workflow:**

    1. **Read and Parse**:
       - Read the target file(s) specified
       - Identify the main components: functions, classes, types, imports
       - Note any dependencies or related files that provide context

    2. **Analyze Structure**:
       - Map the control flow and data flow
       - Identify key abstractions and patterns used
       - Note any non-obvious design decisions
       - Find related code using Grep if needed

    3. **Generate Explanation**:
       - Start with a high-level summary (1-2 sentences)
       - Break down into logical sections
       - Explain the "why" behind design choices
       - Highlight any gotchas or edge cases
       - Use code snippets to illustrate points

    **Output Format:**

    ```markdown
    ## Overview
    [1-2 sentence summary of purpose]

    ## Key Components
    - **[Component 1]**: [purpose and responsibility]
    - **[Component 2]**: [purpose and responsibility]

    ## How It Works
    [Step-by-step explanation of main logic flow]

    ## Design Decisions
    - **[Decision 1]**: [rationale and trade-offs]

    ## Usage Example
    [Brief code example showing typical usage]

    ## Related Code
    - `path/to/related.ts` - [relationship]
    ```

    **Command Arguments:**
    - `<file-path>`: File or directory to explain
    - `--depth=shallow`: Quick overview only (default)
    - `--depth=deep`: Include implementation details and edge cases
    - `--focus=logic`: Focus on business logic and algorithms
    - `--focus=types`: Focus on type system and data structures
    - `--focus=flow`: Focus on control flow and data flow

    Tailor the explanation to the audience - assume competent developers but don't assume domain knowledge.
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
