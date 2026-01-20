let
  commandName = "find-usages";
  description = "Find all usages of a function, type, variable, or class across the codebase";
  allowedTools = "Grep, Read, Glob";
  argumentHint = "<symbol> [--type=function|type|variable|class] [--exclude=pattern] [--regex]";
  prompt = ''
    Comprehensively find and categorize all usages of a given symbol.

    **Workflow:**

    1. **Symbol Identification**:
       - Determine the exact symbol name and type
       - Find the definition location
       - Identify export/import patterns
       - Note any aliases or re-exports

    2. **Usage Search**:
       - Search for direct references with Grep
       - Search for import statements
       - Look for destructured usage
       - Check for dynamic references (if applicable)

    3. **Categorization**:
       - Group usages by type: imports, calls, type annotations, etc.
       - Sort by file/module
       - Identify patterns in how it's used
       - Note any unusual or potentially problematic usages

    4. **Report Generation**:
       - Summary statistics (total usages, files affected)
       - Categorized list of usages with file:line references
       - Insights about usage patterns
       - Potential refactoring implications

    **Output Format:**

    ```markdown
    # Usages of `[symbol]`

    **Definition**: `path/to/definition.ts:42`
    **Total Usages**: X across Y files

    ## By Category

    ### Imports (N)
    - `path/to/file1.ts:1` - `import { symbol } from '...'`

    ### Function Calls (N)
    - `path/to/file2.ts:25` - `symbol(args)`
    - `path/to/file3.ts:100` - `await symbol()`

    ### Type Annotations (N)
    - `path/to/types.ts:10` - `const x: SymbolType = ...`

    ## Usage Patterns
    - [Pattern 1]: [description and examples]
    - [Pattern 2]: [description and examples]

    ## Related Code
    - `path/to/related.ts` - [relationship]
    ```

    **Command Arguments:**
    - `<symbol>`: Function, type, variable, or class name
    - `--type`: Limit search to specific symbol type (function, type, variable, class)
    - `--exclude`: File or directory pattern to exclude
    - `--regex`: Treat symbol as regex pattern

    Include file paths with line numbers. Group results by category.
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
