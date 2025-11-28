{
  changelog = ''
    ---
    allowed-tools: Bash(git log:*), Bash(git diff:*), Bash(git tag:*), Edit, Read, Write
    argument-hint: "[version] [--auto] [--format=keepachangelog|conventional] [--since=tag|date]"
    description: Generate and maintain project changelog following established conventions and standards
    ---

    Generate and maintain project changelogs that follow established conventions.

    ## **WORKFLOW OVERVIEW**

    This command follows a 4-phase systematic approach:
    1. **Analysis** - Examine project changelog patterns and git history
    2. **Classification** - Categorize commits and changes by type and impact
    3. **Generation** - Create changelog entries following detected conventions
    4. **Integration** - Update existing changelog or create new one

    ## **PHASE 1: PROJECT AND CHANGELOG ANALYSIS**

    ### **Step 1.1: Existing Changelog Analysis**
    ```
    ALWAYS START - Understand current changelog structure and conventions
    ```

    **Changelog detection and analysis:**
    ```
    Check for existing changelog files:
      - CHANGELOG.md (most common)
      - HISTORY.md, CHANGES.md, NEWS.md
      - docs/changelog.md or similar
      - RELEASES.md or release notes

    IF changelog exists:
        Analyze format and conventions:
          - Keep a Changelog format (## [Version] - Date)
          - Conventional changelog (### Added, ### Changed, etc.)
          - Semantic versioning patterns (v1.2.3 vs 1.2.3)
          - Date formats (YYYY-MM-DD vs Month DD, YYYY)
          - Section organization and naming
          - Link formats and references
    ```

    ### **Step 1.2: Project Convention Detection**
    ```
    Analyze project patterns:
      - Git commit message conventions (from recent history)
      - Versioning scheme (semantic, calendar, custom)
      - Release tagging patterns (v1.0.0, 1.0.0, release-1.0.0)
      - Project metadata (package.json, Cargo.toml, pyproject.toml)
      - Contributing guidelines or documentation
    ```

    ### **Step 1.3: Change Scope Determination**
    ```
    Determine what changes to include:

    IF version specified:
        Generate entry for that specific version
        
    IF --since flag provided:
        Include changes since specified tag/date
        
    IF --auto flag:
        Automatically determine scope:
          - Since last tagged version
          - Since last changelog entry
          - All unreleased changes
          
    ELSE:
        Include all changes since last changelog update
    ```

    ## **PHASE 2: COMMIT ANALYSIS AND CLASSIFICATION**

    ### **Step 2.1: Git History Analysis**
    ```
    Systematic commit analysis:

    1. Get relevant commit range:
       git log --oneline --reverse <since>..<until>
       
    2. For each commit, extract:
       - Commit hash and date
       - Commit message and body
       - Changed files and impact
       - Author information
       - Related issues/PRs (if referenced)
    ```

    ### **Step 2.2: Conventional Commit Classification**
    ```
    Classify commits by type:

    ADDED (Features and enhancements):
      - feat: new features
      - enhancement: improvements to existing features
      
    CHANGED (Modifications to existing functionality):
      - refactor: code restructuring
      - perf: performance improvements
      - update: dependency updates, non-breaking changes
      
    FIXED (Bug fixes and corrections):
      - fix: bug fixes
      - security: security patches
      - hotfix: critical fixes
      
    DEPRECATED (Features marked for removal):
      - deprecate: deprecated functionality
      
    REMOVED (Deleted features):
      - remove: removed features
      - breaking: breaking changes
      
    SECURITY (Security-related changes):
      - security: security improvements
      
    INTERNAL (Development changes):
      - docs: documentation changes
      - test: test additions/changes
      - ci: CI/CD changes
      - build: build system changes
      - chore: maintenance tasks
    ```

    ### **Step 2.3: Impact Assessment**
    ```
    For each change, assess:
      - Breaking changes (MAJOR version impact)
      - New features (MINOR version impact)  
      - Bug fixes (PATCH version impact)
      - User-facing vs internal changes
      - Migration requirements or notes
    ```

    ## **PHASE 3: CHANGELOG ENTRY GENERATION**

    ### **Step 3.1: Version and Date Handling**
    ```
    Version determination:

    IF version provided as argument:
        Use specified version
        
    IF --auto flag:
        Determine next version based on changes:
          - Breaking changes → increment MAJOR
          - New features → increment MINOR  
          - Only fixes → increment PATCH
          
    ELSE:
        Use "Unreleased" as version placeholder

    Date handling:
        Use current date in detected format
        For unreleased: use "Unreleased" or current date
    ```

    ### **Step 3.2: Entry Formatting**
    ```
    Format based on detected convention:

    KEEP A CHANGELOG format:
    ## [Version] - YYYY-MM-DD
    ### Added
    - New feature descriptions
    ### Changed  
    - Changed functionality descriptions
    ### Fixed
    - Bug fix descriptions
    ### Removed
    - Removed feature descriptions

    CONVENTIONAL format:
    # Version (YYYY-MM-DD)
    ## Features
    - feat: new feature descriptions
    ## Bug Fixes  
    - fix: bug fix descriptions
    ## Performance
    - perf: performance improvements
    ```

    ### **Step 3.3: Content Enhancement**
    ```
    For each changelog entry:
      - Write clear, user-focused descriptions
      - Include migration notes for breaking changes
      - Add issue/PR references where available
      - Group related changes together
      - Use consistent language and tone
      - Highlight significant changes
    ```

    ## **PHASE 4: CHANGELOG INTEGRATION**

    ### **Step 4.1: File Update Strategy**
    ```
    Changelog file handling:

    IF CHANGELOG.md exists:
        Insert new entry at top (after title/intro)
        Preserve existing formatting and structure
        
    ELSE:
        Create new CHANGELOG.md with:
          - Appropriate title and introduction
          - Standard format based on project type
          - Links to versioning and contribution guidelines
    ```

    ### **Step 4.2: Content Integration**
    ```
    Integration process:
      1. Read existing changelog content
      2. Parse structure to find insertion point
      3. Format new entry to match existing style
      4. Insert new entry while preserving formatting
      5. Update any summary sections or indexes
      6. Validate final formatting and structure
    ```

    ### **Step 4.3: Validation and Quality Check**
    ```
    Quality assurance:
      - Verify all significant changes are included
      - Check formatting consistency
      - Validate links and references
      - Ensure version ordering is correct
      - Confirm date formats match conventions
      - Review for clarity and completeness
    ```

    ## **COMMAND FLAGS AND BEHAVIOR**

    **Flag-specific execution:**
    ```
    [version]: Generate entry for specific version (e.g., "1.2.0")
    --auto: Automatically determine version and scope from git history
    --format: Force specific format (keepachangelog, conventional)
    --since: Include changes since specific tag/date (e.g., --since=v1.0.0)
    No flags: Generate "Unreleased" entry with all changes since last update
    ```

    ## **OUTPUT EXAMPLES**

    **Keep a Changelog format:**
    ```markdown
    ## [1.2.0] - 2024-03-15
    ### Added
    - New user authentication system with OAuth2 support
    - Dark mode toggle in application settings
    ### Changed
    - Improved performance of data loading by 40%
    - Updated user interface with modern design system
    ### Fixed
    - Fixed memory leak in background processing
    - Resolved issue with file upload progress indicators
    ```

    **Conventional format:**
    ```markdown
    # 1.2.0 (2024-03-15)
    ## Features
    - **auth:** add OAuth2 integration for external providers
    - **ui:** implement dark mode toggle with user preferences
    ## Performance Improvements  
    - **data:** optimize query performance reducing load time by 40%
    ## Bug Fixes
    - **memory:** fix background process memory leak (#123)
    - **upload:** resolve file upload progress indicator issues
    ```

    ## **USAGE EXAMPLES**

    ```bash
    # Generate unreleased changes entry
    /changelog

    # Create entry for specific version  
    /changelog 1.2.0

    # Auto-generate next version based on changes
    /changelog --auto

    # Include changes since specific tag
    /changelog --since=v1.1.0 --auto

    # Force specific format
    /changelog 2.0.0 --format=keepachangelog
    ```

    **REMEMBER:** Create changelog entries that are user-focused, clearly organized, and follow established project conventions while providing valuable information for users and maintainers.
  '';
}
