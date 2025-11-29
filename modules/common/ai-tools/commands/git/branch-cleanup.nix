{
  git-cleanup = ''
    ---
    allowed-tools: Bash(git branch:*), Bash(git remote:*), Bash(git fetch:*), Bash(git log:*)
    argument-hint: "[--dry-run] [--remote] [--age=days]"
    description: Identify and clean stale branches, merged branches, and remote tracking refs
    ---

    Identify and clean stale branches to keep the repository organized.

    **Workflow:**

    1. **Assessment Phase**:
       - List all local branches with `git branch -v`
       - List merged branches with `git branch --merged main`
       - Check remote tracking status with `git branch -vv`
       - Identify stale remote tracking refs

    2. **Analysis Phase**:
       - Categorize branches: merged, stale, active, orphaned
       - Calculate age of last commit on each branch
       - Identify branches with no remote tracking
       - Note branches that are ahead/behind remote

    3. **Recommendation Phase**:
       - List branches safe to delete (merged into main)
       - Identify potentially stale branches (no commits in X days)
       - Suggest pruning stale remote tracking refs
       - Warn about branches with unmerged work

    4. **Cleanup Phase** (if not --dry-run):
       - Delete merged local branches
       - Prune stale remote tracking refs
       - Report what was cleaned

    **Command Arguments:**
    - `--dry-run`: Only report what would be cleaned, don't delete
    - `--remote`: Include remote branch analysis
    - `--age=days`: Consider branches stale if no commits in N days (default: 30)

    **Safety Rules:**
    - NEVER delete `main`, `master`, or `develop` branches
    - NEVER delete the currently checked out branch
    - Always confirm with user before deleting unmerged branches
    - Use `--dry-run` by default if user doesn't specify

    **Useful Commands:**

    ```bash
    # Merged into main
    git branch --merged main

    # Not merged into main
    git branch --no-merged main

    # Delete merged branches
    git branch --merged main | grep -v main | xargs git branch -d

    # Prune stale remote refs
    git remote prune origin

    # Fetch and prune
    git fetch --prune
    ```

    Present findings in a clear table format and always ask for confirmation before deletions.
  '';
}
