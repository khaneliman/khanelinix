{
  find-usages = ''
    ---
    allowed-tools: Grep, Read, Glob
    argument-hint: "<symbol> [--type=function|type|variable|class] [--exclude=pattern] [--regex]"
    description: Find all usages of a function, type, variable, or class across the codebase
    ---

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

    ## Files Affected
    | File | Usage Count |
    |------|-------------|
    | `path/to/file1.ts` | 5 |
    ```

    **Command Arguments:**
    - `<symbol>`: Name of function, type, variable, or class to find
    - `--type=function`: Filter to function calls only
    - `--type=type`: Filter to type annotations only
    - `--type=variable`: Filter to variable references only
    - `--type=class`: Filter to class instantiations only
    - `--exclude=pattern`: Exclude files matching pattern (e.g., `*.test.ts`)
    - `--regex`: Treat symbol as regex pattern for complex searches (e.g., `handle.*Error`)

    **Advanced Search Examples:**
    - `--regex` for patterns: `find-usages "handle.*Error" --regex`
    - Multiple word symbols: `find-usages "MyClass.method"`
    - Destructured imports: Will find `import { symbol }` patterns

    Be thorough - missing usages can lead to breaking changes during refactoring.
  '';
}
