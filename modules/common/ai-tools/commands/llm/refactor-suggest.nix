let
  commandName = "refactor-suggest";
  description = "Analyze code and suggest refactoring improvements with specific recommendations";
  allowedTools = "Read, Grep, Glob";
  argumentHint = "<file-path> [--focus=complexity|duplication|naming|structure]";
  prompt = ''
    Analyze code and provide actionable refactoring suggestions that improve quality.

    **Workflow:**

    1. **Code Assessment**:
       - Read the target file(s)
       - Identify code smells and anti-patterns
       - Measure complexity (nesting depth, function length)
       - Find duplication and similar patterns

    2. **Issue Identification**:
       - Long functions that should be split
       - Deep nesting that should be flattened
       - Duplicate code that should be extracted
       - Poor naming that reduces readability
       - Tight coupling that limits flexibility

    3. **Recommendation Generation**:
       - Prioritize suggestions by impact
       - Provide specific, actionable recommendations
       - Include before/after examples
       - Explain the benefit of each change

    **Code Smells to Look For:**

    | Smell | Indicator | Refactoring |
    |-------|-----------|-------------|
    | Long Function | >30 lines | Extract Method |
    | Deep Nesting | >3 levels | Early Return, Extract |
    | Duplication | Similar code blocks | Extract Function |
    | God Object | Too many responsibilities | Split Class |
    | Feature Envy | Accessing other object's data | Move Method |
    | Magic Numbers | Unexplained literals | Extract Constant |
    | Long Parameter List | >4 parameters | Parameter Object |

    **Output Format:**

    ```markdown
    # Refactoring Suggestions for [file]

    ## Summary
    - [X] high priority issues
    - [Y] medium priority issues
    - [Z] low priority issues

    ## High Priority

    ### 1. [Issue Title]
    **Location**: `file.ts:42-78`
    **Problem**: [Description of the issue]
    **Suggestion**: [What to do]

    **Before**:
    ```[language]
    [Current code]
    ```

    **After**:
    ```[language]
    [Suggested code]
    ```

    **Benefit**: [Why this improves the code]

    ## Medium Priority
    ...
    ```

    **Command Arguments:**
    - `<file-path>`: File or directory to analyze
    - `--focus=complexity`: Focus on reducing complexity
    - `--focus=duplication`: Focus on DRY violations
    - `--focus=naming`: Focus on naming improvements
    - `--focus=structure`: Focus on architectural issues

    Suggest improvements that are practical and provide real value, not just stylistic preferences.
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
