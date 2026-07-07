let
  commandName = "fixup-autosquash";
in
{
  ${commandName} = {
    inherit
      commandName
      ;

    description = "Fix up uncommitted changes into their original commits and autosquash history";
    allowedTools = "Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(git blame:*), Bash(git add:*), Bash(git commit:*), Bash(git rebase:*), Bash(git reset:*), Read, Edit, Grep";
    argumentHint = "[base-ref]";
    prompt = ''
      Fix up all uncommitted changes into the commits where the affected work was
      introduced, then autosquash history so commits are atomic and scoped.

      Workflow:
      1. Inspect status, diffs, and relevant history from the base ref or branch
         fork point.
      2. Map each hunk to its original commit using `git blame`, `git log -p`,
         `git show`, or path history.
      3. Create focused `git commit --fixup=<commit>` commits. Split hunks when
         changes belong to different commits.
      4. Run interactive rebase with autosquash onto the base ref.
      5. Resolve conflicts by preserving each commit's intended scope; continue
         only after reviewing staged conflict resolutions.
      6. Verify final history with `git log` and `git diff <base-ref>...HEAD`.

      Ask before rewriting published/shared history. Stop and report if a hunk
      cannot be confidently associated with a prior commit.
    '';
  };
}
