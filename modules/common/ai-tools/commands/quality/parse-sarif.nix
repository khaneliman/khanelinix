let
  commandName = "parse-sarif";
  description = "Parse and split large SARIF code analysis files for parallel development work";
  allowedTools = "Bash, Read, Write, Grep, Glob";
  argumentHint = "[sarif-file-path]";
  prompt = ''
    # Parse SARIF Code Analysis Results

    Processes large SARIF (Static Analysis Results Interchange Format) files from code inspection tools like CodeQL, Roslyn analyzers, or other static analysis tools. Analyzes structure, categorizes issues, and splits them into manageable chunks for parallel developer work.

    ## Overview

    SARIF files contain structured security and code quality findings but can become very large (90K+ lines) with complex nested structures. This command uses `jq` to efficiently parse and organize these files without loading them entirely into memory.

    ## Core Capabilities

    1. **Structure Analysis** - Understand SARIF file layout and metadata
    2. **Issue Categorization** - Group by rule type, severity, and affected files
    3. **File Splitting** - Create focused subsets for individual developers
    4. **Summary Reporting** - Generate readable reports and statistics
    5. **Parallel Work Distribution** - Organize issues for team assignment

    ## SARIF Analysis Workflow

    Copy this checklist when processing SARIF files:

    ```
    SARIF Analysis Progress:
    - [ ] Step 1: Check file size and validate structure
    - [ ] Step 2: Analyze issue types and distribution
    - [ ] Step 3: Choose splitting strategy (by rule/file/count)
    - [ ] Step 4: Generate split files or chunks
    - [ ] Step 5: Create summary report
    - [ ] Step 6: Generate developer assignments
    - [ ] Step 7: Setup progress tracking
    ```

    ## SARIF File Structure

    SARIF 2.1.0 files typically contain:

    ```json
    {
      "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
      "version": "2.1.0",
      "runs": [
        {
          "tool": { /* analysis tool info */ },
          "results": [ /* array of issues */ ],
          "artifacts": [ /* source files analyzed */ ]
        }
      ]
    }
    ```

    Each result contains:
    - `ruleId`: Issue type (e.g., "cs/log-forging")
    - `message`: Description of the issue
    - `locations`: File path and line number
    - `codeFlows`: Data flow information for complex issues

    ## Analysis Commands

    ### Initial File Inspection

    ```bash
    # Check SARIF file size and basic structure
    wc -l path/to/file.sarif
    jq '{version, schema: ."$schema", runs: (.runs | length)}' path/to/file.sarif

    # Get overview of first run
    jq '.runs[0] | {tool: .tool.driver.name, results: (.results | length), artifacts: (.artifacts | length)}' path/to/file.sarif
    ```

    ### Issue Analysis and Categorization

    ```bash
    # Count total issues
    jq '.runs[0].results | length' path/to/file.sarif

    # List issue types
    jq -r '.runs[0].results[].ruleId' path/to/file.sarif | sort | uniq -c
    ```

    ### Splitting Strategies

    1. **By Rule Type** - Group issues by ruleId for specialized review
    2. **By File Path** - Group issues by affected files
    3. **By Severity** - Group critical issues separately
    4. **By Count** - Split into equal-sized chunks for team distribution

    ## Output Format

    ```markdown
    ## SARIF Analysis Results

    ### Summary
    - Total issues: X
    - Files affected: Y
    - Rule types: Z

    ### Top Rule Types
    - `ruleId` - X issues

    ### Split Files
    - `sarif-chunk-1.json` - X issues (rules: A, B)
    - `sarif-chunk-2.json` - X issues (rules: C, D)

    ### Recommendations
    - [Next steps]
    ```

    Focus on practical splitting and actionable summaries.
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
