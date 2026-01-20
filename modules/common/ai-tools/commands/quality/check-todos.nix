let
  commandName = "check-todos";
  description = "Scan codebase for incomplete implementations and TODOs that need completion";
  allowedTools = "Grep, Glob, Read, Edit, Write";
  argumentHint = "[directory-scope]";
  prompt = ''
    # Check for TODOs and Placeholders

    Systematically scans the codebase for incomplete implementations, placeholder code, and TODOs that need to be completed before considering code production-ready.

    ## Core Principles

    1. **Zero tolerance for placeholders** - All TODO, FIXME, HACK comments must be resolved
    2. **Complete implementations** - No partial or stubbed methods should remain
    3. **Production-ready code** - All placeholder values, mock data, and test code must be removed or properly implemented
    4. **Systematic scanning** - Use comprehensive search patterns to find all incomplete items
    5. **Actionable resolution** - Generate specific plans to complete each identified item

    ## Scanning Workflow

    Copy this checklist and track your progress:

    ```
    TODO Scan Progress:
    - [ ] Step 1: Run comprehensive search for all TODO patterns
    - [ ] Step 2: Search for code-based placeholders and exceptions
    - [ ] Step 3: Find test/mock code in production files
    - [ ] Step 4: Analyze context for each finding
    - [ ] Step 5: Categorize findings by priority
    - [ ] Step 6: Generate completion plan
    - [ ] Step 7: Implement fixes systematically
    - [ ] Step 8: Verify completion with follow-up scan
    ```

    ## Search Patterns

    ### Comment-Based TODOs

    - TODO
    - FIXME
    - HACK
    - XXX
    - NOTE
    - BUG
    - ISSUE

    ### Code-Based Placeholders

    - `throw new Error("TODO")`
    - `raise NotImplementedError`
    - `panic!("TODO")`
    - `assert(false)`
    - `unreachable!()`
    - `TODO()` functions

    ### Test/Mock Code

    - Fake data generators
    - Mock implementations
    - Temporary stub values
    - Test-only paths in production code

    ## Output Format

    ```markdown
    ## TODO Scan Results

    ### Summary
    - Total TODOs found: X
    - Critical (blocking): X
    - High Priority: X
    - Medium Priority: X
    - Low Priority: X

    ### Findings

    #### Critical
    - `path/to/file:line` - [Description of TODO]

    #### High Priority
    - `path/to/file:line` - [Description of TODO]

    #### Medium Priority
    - `path/to/file:line` - [Description of TODO]

    #### Low Priority
    - `path/to/file:line` - [Description of TODO]

    ### Completion Plan
    - [ ] [Action item 1]
    - [ ] [Action item 2]
    - [ ] [Action item 3]
    ```

    Focus on production code and ensure all placeholders are eliminated.
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
