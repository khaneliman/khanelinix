{
  gather-context = ''
    ---
    allowed-tools: Read, Grep, Glob, Bash(git log:*)
    argument-hint: "<topic> [--scope=file|module|feature] [--format=markdown|json]"
    description: Build comprehensive context for a module or feature to use in prompts or documentation
    ---

    Compile comprehensive information about a codebase area for use in prompts, documentation, or onboarding.

    **Workflow:**

    1. **Identify Scope**:
       - Determine what the topic/feature encompasses
       - Find entry points and main files
       - Map the boundaries of the context

    2. **Gather Core Information**:
       - Read main implementation files
       - Find type definitions and interfaces
       - Identify configuration and constants
       - Collect relevant tests for behavior documentation

    3. **Map Relationships**:
       - Find imports and dependencies
       - Identify consumers of this code
       - Note integration points with other modules
       - Check git history for recent changes

    4. **Compile Context Package**:
       - Summarize purpose and responsibilities
       - List key files with brief descriptions
       - Document public API/interface
       - Include relevant code snippets
       - Note assumptions and constraints

    **Output Format (Markdown):**

    ```markdown
    # Context: [Topic Name]

    ## Purpose
    [What this code does and why it exists]

    ## Key Files
    | File | Purpose |
    |------|---------|
    | `path/to/main.ts` | Main implementation |

    ## Public Interface
    [Key functions, types, and their signatures]

    ## Dependencies
    - **Internal**: [list of internal dependencies]
    - **External**: [list of external packages]

    ## Consumers
    [What other code uses this]

    ## Recent Changes
    [Summary of recent git history]

    ## Code Snippets
    [Relevant excerpts with context]
    ```

    **Command Arguments:**
    - `<topic>`: Feature name, module path, or search term
    - `--scope=file`: Single file context
    - `--scope=module`: Module/directory context (default)
    - `--scope=feature`: Cross-cutting feature context
    - `--format=markdown`: Human-readable output (default)
    - `--format=json`: Structured output for programmatic use

    Gather enough context to fully understand the feature without overwhelming with irrelevant details.
  '';
}
