{
  git-resolve = ''
    ---
    allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Read, Edit
    argument-hint: "[file] [--strategy=ours|theirs|manual]"
    description: Guided merge conflict resolution with context and recommendations
    ---

    Guide through understanding and resolving git merge conflicts.

    **Workflow:**

    1. **Conflict Assessment**:
       - Run `git status` to list all conflicted files
       - Categorize conflict types (content, renamed, deleted, etc.)
       - Identify the branches/commits involved in the conflict

    2. **Context Gathering**:
       - For each conflicted file, show the conflict markers
       - Explain what "ours" and "theirs" represent in this context
       - Use `git log` to understand the changes on each side
       - Identify if conflict is semantic (logic) or syntactic (formatting)

    3. **Resolution Strategy**:
       - For simple conflicts: suggest ours/theirs based on context
       - For complex conflicts: show both versions and propose merged solution
       - Explain the implications of each choice
       - Consider dependencies and side effects

    4. **Apply Resolution**:
       - Make the edit to resolve the conflict
       - Remove conflict markers completely
       - Stage the resolved file with `git add`
       - Verify no conflict markers remain

    **Command Arguments:**
    - `[file]`: Focus on specific conflicted file
    - `--strategy=ours`: Accept current branch version
    - `--strategy=theirs`: Accept incoming branch version
    - `--strategy=manual`: Guide through manual resolution

    **Conflict Understanding:**

    ```
    <<<<<<< HEAD (ours - current branch)
    Code from your current branch
    =======
    Code from the incoming branch
    >>>>>>> feature (theirs - incoming)
    ```

    **Resolution Commands:**

    ```bash
    # Accept ours (current branch)
    git checkout --ours path/to/file

    # Accept theirs (incoming branch)
    git checkout --theirs path/to/file

    # See what we're merging
    git log --oneline HEAD..MERGE_HEAD
    ```

    **Safety Rules:**
    - Always verify conflict markers are completely removed
    - Run `git diff --check` to verify no markers remain
    - Suggest running tests after resolution
    - Never stage files with remaining conflict markers
  '';
}
