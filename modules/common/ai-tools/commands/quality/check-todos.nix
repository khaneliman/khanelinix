{
  check-todos = ''
    ---
    allowed-tools: Grep, Glob, Read, Edit, Write
    argument-hint: "[directory-scope]"
    description: Scan codebase for incomplete implementations and TODOs that need completion
    ---

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

    Search for common TODO comment patterns:
    - TODO
    - FIXME
    - HACK
    - BUG
    - PLACEHOLDER
    - XXX
    - TEMP
    - TEMPORARY
    - NOT IMPLEMENTED
    - INCOMPLETE

    ### Code-Based Placeholders

    Look for incomplete implementations:
    - NotImplementedException
    - throw new NotImplementedException
    - NotSupportedException
    - throw new NotSupportedException
    - return default
    - return null
    - string.Empty (when used as placeholder)
    - Guid.Empty (when used as placeholder)
    - DateTime.MinValue (when used as placeholder)
    - panic!("not implemented") (Rust)
    - unimplemented!() (Rust)
    - raise NotImplementedError (Python)

    ### Test and Mock Code

    Find test/mock code that shouldn't be in production:
    - UseMockData
    - MockData
    - Test data
    - Sample data
    - Example data
    - Hardcoded values that should be configurable
    - Console.WriteLine / console.log (debug code)
    - System.Diagnostics.Debug
    - print() / println!() statements (outside of intentional logging)

    ## Scanning Process

    ### Step 1: Run Comprehensive Search

    Use Grep tool to scan for all patterns:

    **Search 1: Comment-based TODOs**
    ```bash
    # Pattern to search
    TODO|FIXME|HACK|BUG|PLACEHOLDER|XXX|TEMP|NOT IMPLEMENTED|INCOMPLETE
    ```

    **Search 2: Code-based placeholders**
    ```bash
    # Patterns to search
    NotImplementedException|NotSupportedException|throw new
    return default|return null
    unimplemented!|panic!.*not implemented
    raise NotImplementedError
    ```

    **Search 3: Test/mock code**
    ```bash
    # Patterns to search
    Mock|Test|Sample|Example|Console\.WriteLine|console\.log
    UseMockData|MockData|print\(|println!
    ```

    ### Step 2: Analyze Context

    For each finding:
    1. Read the surrounding code to understand context
    2. Determine why it was left incomplete
    3. Assess the complexity of completing it
    4. Identify any dependencies needed for completion
    5. Determine the impact on functionality if left incomplete

    ### Step 3: Categorize by Priority

    **Priority 1 (Critical - Blocks functionality):**
    - NotImplementedException in main code paths
    - Missing validation that could cause security issues
    - Incomplete database queries or HTTP client calls
    - Missing error handling in critical paths

    **Priority 2 (High - Affects user experience):**
    - Placeholder error messages
    - Incomplete data transformations
    - Missing configuration values
    - Incomplete API responses

    **Priority 3 (Medium - Technical debt):**
    - TODO comments with implementation notes
    - Incomplete logging or diagnostics
    - Non-critical validation rules
    - Performance optimization placeholders

    **Priority 4 (Low - Documentation/style):**
    - TODO comments about code documentation
    - Style or refactoring TODOs
    - Non-functional improvements

    ## Resolution Guidelines

    ### For Each Identified Item

    1. **Understand the requirement** - What functionality was intended?
    2. **Check original source** - How was this implemented originally (if migration)?
    3. **Implement properly** - Follow project patterns and conventions
    4. **Add appropriate tests** - If this is critical functionality
    5. **Update documentation** - If this affects the API or configuration

    ### Common Resolution Patterns

    **Pattern 1: NotImplementedException → Proper implementation**
    - Check original source for required logic
    - Follow project patterns for the implementation layer
    - Add structured logging with appropriate log levels
    - Include proper error handling

    **Pattern 2: Placeholder validation → Proper validation rules**
    - Check original validation logic if migrating
    - Use project's validation framework
    - Include proper error messages matching original behavior
    - Add tests for validation rules

    **Pattern 3: Mock/test data → Production implementation**
    - Remove or move mock data to test projects only
    - Use proper data access patterns from project
    - Use configuration settings with appropriate defaults
    - Ensure no test data leaks into production

    **Pattern 4: Incomplete configuration → Proper settings**
    - Create proper settings/config classes
    - Include appropriate default values
    - Register configuration properly in app startup
    - Update config files with environment-specific values

    ## Output Format

    ### Scan Report Template

    ```markdown
    ## TODO and Placeholder Scan Results

    **Scan Date**: [Date]
    **Files Scanned**: [Number of files checked]
    **Issues Found**: [Total count]

    ### 🚨 Critical Issues (Priority 1)

    1. **NotImplementedException in [Service/Method]**
       - **File**: `[file_path:line_number]`
       - **Context**: [What functionality is missing]
       - **Impact**: [How this affects the system]
       - **Resolution**: [What needs to be implemented]

    ### ⚠️ High Priority Issues (Priority 2)

    1. **Placeholder [Description]**
       - **File**: `[file_path:line_number]`
       - **Current**: `[current placeholder code]`
       - **Required**: [What should be implemented instead]

    ### 📋 Medium Priority Issues (Priority 3)

    1. **TODO: [Description]**
       - **File**: `[file_path:line_number]`
       - **Comment**: "[Full TODO comment]"
       - **Resolution**: [Action needed]

    ### 📝 Low Priority Issues (Priority 4)

    [List of documentation and style TODOs]

    ### 🔨 Action Plan

    #### Phase 1: Critical Fixes
    1. **[Issue description]**
       - Files to modify: `[file1]`, `[file2]`
       - Implementation approach: [Brief description]
       - Estimated complexity: [Simple/Medium/Complex]

    #### Phase 2: High Priority
    [Continue with systematic action plan]

    ### ✅ Verification Steps

    After implementing fixes:
    1. Re-run TODO scan to verify all items resolved
    2. Run build to ensure no compilation errors
    3. Run tests to verify functionality
    4. Run linters/formatters
    5. Test critical paths manually
    6. Verify no new TODOs or placeholders introduced
    ```

    ## Quality Standards

    - **Zero TODOs in production code** - All placeholder comments must be resolved
    - **Complete implementations** - No stub methods or NotImplementedException in main code paths
    - **Production-ready configuration** - All placeholder values replaced with proper settings
    - **Proper error handling** - No missing exception handling in critical paths
    - **Clean codebase** - No debugging code, test data, or temporary implementations

    Remember: The goal is to ensure the codebase is production-ready with no incomplete implementations that could cause runtime failures or degraded user experience.
  '';
}
