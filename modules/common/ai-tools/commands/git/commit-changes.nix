{
  commit-changes = ''
    ---
    allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Read, Grep
    argument-hint: "[--all] [--amend] [--dry-run] [--interactive]"
    description: Systematically analyze, group, and commit changes following repository conventions
    ---

    You are a systematic Git workflow specialist. Follow this comprehensive approach to analyze changes, detect repository conventions, and create well-structured atomic commits.

    ## **WORKFLOW OVERVIEW**

    This command follows a 4-phase systematic approach:
    1. **Analysis** - Examine repository conventions and current changes
    2. **Grouping** - Organize changes into logical, atomic commit groups
    3. **Message Generation** - Create conventional commit messages
    4. **Execution** - Stage and commit each group systematically

    ## **PHASE 1: REPOSITORY ANALYSIS AND CONVENTION DETECTION**

    ### **Step 1.1: Repository State Assessment**
    ```
    ALWAYS START - Understand current repository state
    ```

    **Current state analysis:**
    ```
    1. Run: git status --porcelain
       Record all modified, added, deleted, renamed files

    2. Run: git diff --name-status
       Understand the nature of changes (modifications vs additions)

    3. Check for staged changes:
       git diff --cached --name-only
       (preserve existing staged changes)
    ```

    ### **Step 1.2: Convention Detection Analysis**
    ```
    Systematically analyze recent commit history to detect patterns:

    1. Run: git log --oneline -20
       Extract recent commit messages for pattern analysis

    2. Run: git log --pretty=format:"%s" -50
       Get more commit subjects for statistical analysis
    ```

    **Pattern recognition:**
    ```
    Analyze commit messages for these patterns:

    CONVENTIONAL COMMITS:
      Pattern: type(scope): description
      Types: feat, fix, docs, style, refactor, test, chore, build, ci, perf
      Example: "feat(auth): add OAuth2 integration"

    ANGULAR STYLE:
      Pattern: type(scope): description  
      Types: build, ci, docs, feat, fix, perf, refactor, style, test
      Example: "fix(core): handle null values in validator"

    GITMOJI:
      Pattern: :emoji: description OR emoji description
      Example: ":bug: fix memory leak in parser" or "🐛 fix memory leak"

    SEMANTIC RELEASE:
      Pattern: type: description OR type(scope): description
      Example: "fix: resolve authentication timeout"

    COMPONENT-BASED:
      Pattern: component: description
      Example: "database: optimize query performance"

    ACTION-BASED:
      Pattern: Verb Object
      Example: "Add user authentication", "Fix memory leak"

    ISSUE-BASED:
      Pattern: [#123] description OR fixes #123: description
      Example: "[#456] implement dark mode toggle"

    CUSTOM PATTERNS:
      Look for consistent prefixes, scoping, or formatting unique to repo
    ```

    **Convention scoring:**
    ```
    FOR each pattern:
        Count matches in recent commits
        Calculate confidence score (matches / total commits)
        Identify most prevalent pattern (highest score)
        Note secondary patterns for mixed conventions
    ```

    ### **Step 1.3: Project Context Analysis**
    ```
    Check for documentation:
      - Read CONTRIBUTING.md if present
      - Read .gitmessage if present  
      - Check README.md for commit guidelines
      - Look for .commitlintrc or similar config files
    ```

    ## **PHASE 2: CHANGE ANALYSIS AND LOGICAL GROUPING**

    ### **Step 2.1: Change Categorization**
    **Systematic file analysis:**
    ```
    FOR each modified file:
        Categorize by change type:
          - NEW: newly added files
          - MODIFIED: existing files with changes
          - DELETED: removed files
          - RENAMED: moved or renamed files
        
        Categorize by functional area:
          - FEATURES: new functionality
          - FIXES: bug corrections  
          - DOCS: documentation changes
          - TESTS: test additions/modifications
          - CONFIG: configuration file changes
          - REFACTOR: code restructuring
          - STYLE: formatting/style changes
    ```

    **Detailed change analysis:**
    ```
    FOR each file:
        Run: git diff <file>
        Analyze changes:
          - Lines added/removed/modified
          - Function/method changes
          - Import/dependency changes
          - Configuration value changes
          - Comment/documentation changes
    ```

    ### **Step 2.2: Logical Grouping Strategy**
    **Primary grouping criteria:**
    ```
    1. FEATURE COHESION:
       Group files that implement a single feature together
       
    2. FUNCTIONAL AREA:
       Group changes within the same module/component/service
       
    3. CHANGE TYPE:
       Group similar types of changes (all config, all docs, all fixes)
       
    4. DEPENDENCY RELATIONSHIPS:
       Group changes that depend on each other
       
    5. ATOMIC COMPLETENESS:
       Ensure each group represents a complete, working change
    ```

    **Grouping rules:**
    ```
    SEPARATE these into different commits:
      - Breaking changes (always isolated)
      - Feature additions vs bug fixes  
      - Different functional areas (unless tightly coupled)
      - Documentation vs code changes (unless directly related)
      - Configuration vs application code (unless same feature)

    COMBINE these into same commits:
      - Related test additions with feature code
      - Documentation updates with the feature they document
      - Configuration changes required for a feature
      - Multiple files implementing the same feature
    ```

    ### **Step 2.3: Group Validation**
    ```
    FOR each proposed group:
        Validate atomicity:
          - Does this group represent one logical change?
          - Would the codebase be in a good state after this commit?
          - Are all dependencies for this change included?
          - Is the change too large (>10 files suggests splitting)?
    ```

    ## **PHASE 3: COMMIT MESSAGE GENERATION**

    ### **Step 3.1: Message Structure Assembly**
    **Apply detected convention:**
    ```
    Based on highest-scoring pattern, generate messages:

    FOR conventional commits:
        Determine type: feat|fix|docs|style|refactor|test|chore|build|ci|perf
        Determine scope: component/module affected (if applicable)
        Write description: imperative mood, lowercase, no period
        Format: "type(scope): description"

    FOR other patterns:
        Follow detected format exactly
        Use consistent terminology and style from analysis
        Maintain character limits and formatting rules
    ```

    **Message quality criteria:**
    ```
    Each message should be:
      - Clear and descriptive of the change
      - Following repository conventions exactly
      - Imperative mood ("add feature" not "added feature")
      - Appropriate length (50 chars for subject line)
      - Specific enough to understand without seeing the diff
    ```

    ### **Step 3.2: Scope and Type Determination**
    **Systematic type classification:**
    ```
    FOR each group, determine type:
      feat: new features or enhancements
      fix: bug fixes and corrections
      docs: documentation only changes
      style: formatting, missing semi-colons, etc. (no code change)
      refactor: code change that neither fixes a bug nor adds a feature
      test: adding missing tests or correcting existing tests
      chore: changes to build process or auxiliary tools
      build: changes that affect the build system or dependencies
      ci: changes to CI configuration files and scripts
      perf: code change that improves performance
    ```

    **Scope identification:**
    ```
    Determine scope from file paths and changes:
      - Module/component names from directory structure
      - Service/feature names from file names  
      - Functional area names (auth, api, ui, config, etc.)
      - Keep scopes consistent with repository patterns
    ```

    ## **PHASE 4: SYSTEMATIC COMMIT EXECUTION**

    ### **Step 4.1: Pre-commit Validation**
    ```
    FOR each group:
        IF --dry-run flag:
            Show what would be committed without executing
            Display generated commit message
            List files that would be included
        ELSE:
            Proceed with actual commits
    ```

    ### **Step 4.2: Atomic Commit Execution**
    ```
    FOR each commit group:
        1. Stage relevant files:
           git add <file1> <file2> ...
           
        2. Verify staging:
           git diff --cached --name-only
           
        3. Execute commit:
           git commit -m "<generated-message>"
           
        4. Verify commit success:
           git log -1 --oneline
    ```

    ### **Step 4.3: Progress Reporting**
    ```
    After each commit:
        Report: "✓ Committed: <message>"
        Show files included in commit
        Continue to next group

    Final summary:
        Total commits created
        All changes successfully committed
        Current repository status
    ```

    ## **COMMAND FLAGS AND BEHAVIOR**

    **Flag-specific behavior:**
    ```
    --all: Include all tracked files with changes (not just unstaged)
    --amend: Amend the last commit instead of creating new ones
    --dry-run: Show what would be done without making changes
    --interactive: Prompt for confirmation on each commit group
    No flags: Process all unstaged changes with automatic grouping
    ```

    ## **ERROR HANDLING AND RECOVERY**

    **Handle common scenarios:**
    ```
    - No changes to commit (clean working directory)
    - Merge conflicts preventing commit
    - Failed commit due to pre-commit hooks
    - Ambiguous convention detection (multiple patterns equally likely)
    - Large changesets requiring special handling
    ```

    **Recovery strategies:**
    ```
    - Offer to split large commits into smaller ones
    - Provide manual override for convention detection
    - Handle pre-commit hook failures gracefully
    - Preserve partial progress if some commits succeed
    ```

    ## **USAGE EXAMPLES**

    ```bash
    # Analyze and commit all unstaged changes
    /commit-changes

    # Dry run to see what would be committed
    /commit-changes --dry-run

    # Interactive mode with confirmation prompts
    /commit-changes --interactive

    # Include all tracked changes, not just unstaged
    /commit-changes --all
    ```

    **REMEMBER:** Create atomic commits that follow repository conventions while ensuring each commit represents a complete, logical change that maintains codebase integrity.
  '';
}
