{
  parse-sarif = ''
    ---
    allowed-tools: Bash, Read, Write, Grep, Glob
    argument-hint: "[sarif-file-path]"
    description: Parse and split large SARIF code analysis files for parallel development work
    ---

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

    # Group issues by rule type
    jq '.runs[0].results | group_by(.ruleId) | map({rule: .[0].ruleId, count: length}) | sort_by(-.count)' path/to/file.sarif

    # Get unique rule IDs
    jq '.runs[0].results | map(.ruleId) | unique' path/to/file.sarif

    # Analyze issues by file
    jq '.runs[0].results | map(.locations[0].physicalLocation.artifactLocation.uri) | group_by(.) | map({file: .[0], count: length}) | sort_by(-.count)' path/to/file.sarif
    ```

    ### Detailed Issue Extraction

    ```bash
    # Extract key information for all issues
    jq '.runs[0].results | map({
      ruleId,
      message: .message.text,
      file: .locations[0].physicalLocation.artifactLocation.uri,
      line: .locations[0].physicalLocation.region.startLine,
      column: .locations[0].physicalLocation.region.startColumn
    })' path/to/file.sarif
    ```

    ## File Splitting Strategies

    ### Strategy 1: Split by Rule Type

    Create separate files for each issue type to allow specialized expertise:

    ```bash
    # Get list of rule types
    RULES=$(jq -r '.runs[0].results | map(.ruleId) | unique | .[]' path/to/file.sarif)

    # Create file for each rule type
    for rule in $RULES; do
      filename="sarif-$(echo $rule | sed 's/\//-/g').json"
      jq --arg rule "$rule" '.runs[0].results | map(select(.ruleId == $rule))' path/to/file.sarif > "$filename"
      echo "Created $filename with $(jq length "$filename") issues"
    done
    ```

    ### Strategy 2: Split by Affected File

    Group issues by the files they affect for file-specific fixes:

    ```bash
    # Get list of affected files
    FILES=$(jq -r '.runs[0].results | map(.locations[0].physicalLocation.artifactLocation.uri) | unique | .[]' path/to/file.sarif)

    # Create directory for file-based splits
    mkdir -p sarif-by-file

    # Create file for each affected source file
    echo "$FILES" | while read -r file; do
      safe_filename=$(echo "$file" | sed 's/[^a-zA-Z0-9.]/-/g')
      output_file="sarif-by-file/issues-$safe_filename.json"
      jq --arg file "$file" '.runs[0].results | map(select(.locations[0].physicalLocation.artifactLocation.uri == $file))' path/to/file.sarif > "$output_file"
      echo "Created $output_file with $(jq length "$output_file") issues for $file"
    done
    ```

    ### Strategy 3: Split by Issue Count

    Create balanced chunks for parallel processing:

    ```bash
    # Create chunks of 10 issues each
    TOTAL=$(jq '.runs[0].results | length' path/to/file.sarif)
    CHUNK_SIZE=10
    CHUNKS=$(($TOTAL / $CHUNK_SIZE + 1))

    mkdir -p sarif-chunks

    for i in $(seq 0 $((CHUNKS-1))); do
      START=$((i * CHUNK_SIZE))
      END=$(((i + 1) * CHUNK_SIZE))

      jq --argjson start $START --argjson end $END '.runs[0].results | .[$start:$end]' path/to/file.sarif > "sarif-chunks/chunk-$(printf "%03d" $i).json"
      echo "Created chunk-$(printf "%03d" $i).json with issues $START to $((END-1))"
    done
    ```

    ## Summary Report Generation

    ### Issue Summary Report

    ```bash
    # Generate comprehensive summary
    jq -r '
    .runs[0] |
    "# SARIF Analysis Summary\n",
    "**Tool**: \(.tool.driver.name)",
    "**Version**: \(.tool.driver.version // "unknown")",
    "**Total Issues**: \(.results | length)",
    "",
    "## Issues by Rule Type",
    "",
    (.results | group_by(.ruleId) | map("- **\(.[0].ruleId)**: \(length) issues") | join("\n")),
    "",
    "## Issues by File (Top 10)",
    "",
    (.results | map(.locations[0].physicalLocation.artifactLocation.uri) | group_by(.) | map("- **\(.[0])**: \(length) issues") | sort | .[0:10] | join("\n"))
    ' path/to/file.sarif > sarif-summary.md
    ```

    ### Developer Assignment Report

    ```bash
    # Create developer task assignments
    jq -r '
    .runs[0].results |
    group_by(.ruleId) |
    map(
      "## Rule: \(.[0].ruleId) (\(length) issues)\n" +
      "**Recommended Skills**: " +
      (if .[0].ruleId | contains("log") then "Logging Security, Input Validation"
       elif .[0].ruleId | contains("sql") then "Database Security, SQL Injection"
       elif .[0].ruleId | contains("crypto") then "Cryptography, Security"
       else "General Security, Code Quality" end) + "\n" +
      "**Estimated Effort**: " +
      (if length < 5 then "1-2 hours"
       elif length < 15 then "Half day"
       else "1-2 days" end) + "\n" +
      "**Files Affected**: " +
      (map(.locations[0].physicalLocation.artifactLocation.uri) | unique | join(", ")) + "\n"
    ) | join("\n")
    ' path/to/file.sarif > developer-assignments.md
    ```

    ## Working with Specific Issue Types

    ### Common Security Issues

    **Log Forging (cs/log-forging):**
    - Unsafe logging practices that allow log injection
    - Requires adding input sanitization
    - Use structured logging instead of string concatenation

    **Sensitive Information Exposure:**
    - Data flow showing sensitive data being exposed
    - Requires proper data masking or encryption
    - Check entire data flow from source to sink

    **SQL Injection:**
    - Raw string concatenation in queries
    - Requires parameterized queries
    - Verify all database access points

    ### Extract Issues by Type

    ```bash
    # Extract specific issue type with context
    jq '.runs[0].results | map(select(.ruleId == "cs/log-forging")) | map({
      file: .locations[0].physicalLocation.artifactLocation.uri,
      line: .locations[0].physicalLocation.region.startLine,
      message: .message.text,
      codeSnippet: .locations[0].physicalLocation.contextRegion.snippet.text
    })' path/to/file.sarif > specific-issues.json
    ```

    ## Parallel Development Workflow

    ### 1. Initial Assessment

    ```bash
    # Quick analysis to understand scope
    echo "=== SARIF Analysis Report ==="
    echo "Total Issues: $(jq '.runs[0].results | length' path/to/file.sarif)"
    echo ""
    echo "Issues by Type:"
    jq -r '.runs[0].results | group_by(.ruleId) | map("  \(.[0].ruleId): \(length)") | join("\n")' path/to/file.sarif
    ```

    ### 2. Team Assignment

    Based on the analysis, assign developers:
    - **Security specialist**: Handle exposure and injection vulnerabilities
    - **Logging expert**: Address log-forging issues
    - **File owners**: Assign based on code ownership and expertise

    ### 3. Progress Tracking

    ```bash
    # Generate progress tracking template
    jq -r '
    "# SARIF Issues Progress Tracking\n",
    "## Overview",
    "- Total Issues: \(.runs[0].results | length)",
    "- Completed: 0",
    "- Remaining: \(.runs[0].results | length)\n",
    "## Issues by Rule Type\n",
    (.runs[0].results | group_by(.ruleId) | map("### \(.[0].ruleId) (\(length) issues)\n" + (map("- [ ] \(.locations[0].physicalLocation.artifactLocation.uri):\(.locations[0].physicalLocation.region.startLine)") | join("\n")) + "\n") | join("\n"))
    ' path/to/file.sarif > sarif-progress.md
    ```

    ## Quality Verification

    After making fixes, verify the changes:

    ```bash
    # Compare issue counts
    echo "Original issues: $(jq '.runs[0].results | length' original.sarif)"
    echo "Remaining issues: $(jq '.runs[0].results | length' updated.sarif)"

    # Check which issues were fixed
    jq --slurpfile original original.sarif --slurpfile updated updated.sarif -n '
    $original[0].runs[0].results as $orig |
    $updated[0].runs[0].results as $new |
    {
      original_count: ($orig | length),
      current_count: ($new | length),
      fixed_count: (($orig | length) - ($new | length))
    }
    '
    ```

    ## Implementation Checklist

    - [ ] **File validated**: SARIF file structure confirmed
    - [ ] **Analysis complete**: Issue types and counts identified
    - [ ] **Splitting strategy chosen**: Based on team size and expertise
    - [ ] **Developer assignments made**: Issues distributed appropriately
    - [ ] **Progress tracking setup**: Markdown checklist created
    - [ ] **Fix guidelines provided**: Specific patterns for each rule type
    - [ ] **Verification process defined**: Re-analysis and comparison method

    This command enables efficient processing of large SARIF files and facilitates coordinated team efforts to address security and code quality issues systematically.
  '';
}
