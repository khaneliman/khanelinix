let
  commandName = "changelog";
  description = "Generate and maintain project changelog following established conventions and standards";
  allowedTools = "Bash(git log:*), Bash(git diff:*), Bash(git tag:*), Edit, Read, Write";
  argumentHint = "[version] [--auto] [--format=keepachangelog|conventional] [--since=tag|date]";
  prompt = ''
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
    ```

    ## **PHASE 2: CHANGE CLASSIFICATION**

    ### **Step 2.1: Commit Categorization**
    - Identify commit types (feat, fix, docs, refactor, etc.)
    - Group commits into changelog sections
    - Note breaking changes and migration requirements

    ## **PHASE 3: CHANGELOG GENERATION**

    - Generate new changelog entries
    - Follow existing format and conventions
    - Include version, date, and sections

    ## **PHASE 4: UPDATE FILE**

    - Insert new entry at top
    - Preserve existing history
    - Validate formatting

    **Command Arguments:**
    - `[version]`: Optional explicit version
    - `--auto`: Auto-determine version
    - `--format=keepachangelog`: Keep a Changelog style
    - `--format=conventional`: Conventional commits style
    - `--since=tag`: Use last tag as baseline
    - `--since=date`: Use date as baseline

    Keep changelog entries concise, user-facing, and consistent.
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
