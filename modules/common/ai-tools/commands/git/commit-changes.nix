let
  commandName = "commit-changes";
  description = "Systematically analyze, group, and commit changes following repository conventions";
  allowedTools = "Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git reset:*), Read, Grep";
  argumentHint = "[--all] [--amend] [--dry-run] [--interactive]";
  prompt = ''
    Create **minimal, atomic commits** where each represents a single logical change. The goal is a git log that tells the story of how the codebase evolved through discrete, understandable enhancements.

    ## **CORE PHILOSOPHY**

    **CRITICAL PRINCIPLE: Smallest COMPLETE Logical Change Per Commit**

    - Each commit must be a **buildable, runnable state** - no broken builds in history
    - Each commit should be ONE logical enhancement that could stand alone
    - A "feature" spanning multiple files may be MULTIPLE commits if it has distinct logical components
    - Never bundle unrelated changes just because they're in the same file or directory
    - The git log should read like a changelog of discrete improvements
    - Someone reading `git log --oneline` should understand WHAT changed and WHY

    **THE BUILDABILITY RULE:**
    - Every commit MUST compile/build successfully
    - Every commit MUST pass basic validation (e.g., `nix flake check`)
    - If change A depends on change B, they go in the SAME commit or B comes FIRST
    - Never commit a reference to something that doesn't exist yet
    - Think: "Can someone check out THIS commit and have a working system?"

    **Why this matters:**
    - `git bisect` requires every commit to be testable
    - Cherry-picking any commit should work
    - Reverting any commit should leave a working state
    - Code review at any commit should be possible

    **ANTI-PATTERNS TO AVOID:**
    - Committing a function call before committing the function definition
    - Committing an import before the imported module exists
    - Committing an option usage before the option is defined
    - "Add module X" when module X has 5 different independent components
    - Staging entire files when only some hunks are related to the current commit
    - Grouping by directory structure instead of logical function
    - Combining formatting fixes with functional changes
    - Bundling multiple bug fixes into one commit

    ## **WORKFLOW OVERVIEW**

    1. **Analysis** - Examine changes at the HUNK level, not file level
    2. **Decomposition** - Split changes into smallest logical units
    3. **Selective Staging** - Stage individual lines/hunks with `git add -p`
    4. **Atomic Commits** - One logical change per commit

    ## **PHASE 1: GRANULAR CHANGE ANALYSIS**

    ### **Step 1.1: Hunk-Level Examination**
    ```bash
    # See all changes with context
    git diff

    # For each file, examine individual hunks
    git diff -U5 <file>  # More context lines for understanding

    # Identify logical boundaries within each file
    ```

    **For each hunk, ask:**
    - What single thing does this hunk accomplish?
    - Is this hunk independent of other hunks in the same file?
    - Could this hunk be committed alone and leave the codebase working?
    - Does this hunk belong with hunks in OTHER files?

    ### **Step 1.2: Change Decomposition**
    ```
    FOR each modified file:
        FOR each hunk in file:
            Identify the PURPOSE of this specific change:
              - Is it a bug fix?
              - Is it a new feature component?
              - Is it a refactor?
              - Is it documentation?
              - Is it formatting/style?
    ```

    ### **Step 1.3: Cross-File Grouping**
    - Group related hunks across different files
    - Ensure each group represents ONE logical change
    - Identify dependencies between groups

    ## **PHASE 2: STAGING STRATEGY**

    ### **Step 2.1: Create Staging Plan**
    - List each logical change group
    - Order groups by dependency (if any)
    - Plan staging sequence

    ### **Step 2.2: Selective Staging**
    ```bash
    # Stage specific hunks
    git add -p

    # Stage specific files
    git add path/to/file

    # Stage specific lines (advanced)
    git add -e
    ```

    ### **Step 2.3: Verify Staging**
    - Check `git status` after staging each group
    - Review staged diff with `git diff --cached`
    - Ensure no unrelated changes are staged

    ## **PHASE 3: COMMIT CREATION**

    ### **Step 3.1: Commit Message**
    - Follow conventional commit format
    - Describe WHY the change is needed
    - Keep subject line under 72 characters
    - Do NOT put `\n` inside a normal quoted `git commit -m` string and expect a newline; git takes that text literally
    - Prefer `git commit -F <file>` or `git commit -F-` for longer messages
    - If using `-m`, prefer multiple `-m` flags for separate paragraphs
    - Literal newlines inside a quoted shell string are valid
    - In bash/zsh, ANSI-C quoting like `$'line one\nline two'` interprets escapes, but `-F` or multiple `-m` flags are less error-prone

    ### **Step 3.1a: Safe CLI Patterns**
    ```bash
    # Good: separate paragraphs with multiple -m flags
    git commit \
      -m "docs(ai-tools): clarify git commit newlines" \
      -m "Document that normal quoted \\n stays literal in git commit bodies.

    Prefer -F or multiple -m flags for longer messages."

    # Good: include literal newlines inside the quoted body
    git commit -m "subject" -m "first line
    second line

    third paragraph"

    # Good: use ANSI-C quoting when shell escapes are intentional
    git commit -m "subject" -m $'first line\nsecond line\n\nthird paragraph'

    # Safest for long messages
    git commit -F- <<'EOF'
    docs(ai-tools): clarify git commit newlines

    Document that normal quoted \n stays literal in git commit bodies.

    Prefer -F or multiple -m flags for longer messages.
    EOF
    ```

    **Rule of thumb:**
    - `"\n"` in normal shell quotes is usually literal
    - `$'...\n...'` interprets escapes in bash/zsh
    - For commit messages, `-F` or multiple `-m` flags are the least error-prone

    ### **Step 3.2: Validate Commit**
    - Ensure commit builds/tests pass
    - Confirm commit contains only intended changes

    ## **Output Format:**

    ```markdown
    ## Commit Plan
    - **Commit 1:** [Description]
    - **Commit 2:** [Description]

    ## Staging Commands
    ```bash
    git add <files>
    ```

    ## Commit Messages
    - `feat: add ...`
    - `fix: correct ...`

    ## Notes
    - [Any warnings or considerations]
    ```

    Provide a clear, minimal commit plan and ask for confirmation before committing.
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
