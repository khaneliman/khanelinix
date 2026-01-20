let
  commandName = "git-cleanup";
  description = "Identify and clean stale branches, merged branches, and remote tracking refs";
  allowedTools = "Bash(git branch:*), Bash(git remote:*), Bash(git fetch:*), Bash(git log:*)";
  argumentHint = "[--dry-run] [--remote] [--age=days]";
  prompt = ''
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

    Always confirm before deleting any branches. Use dry-run by default.
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
