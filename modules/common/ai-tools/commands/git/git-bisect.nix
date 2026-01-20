let
  commandName = "git-bisect";
  description = "Guided git bisect workflow to find the commit that introduced a regression";
  allowedTools = "Bash(git bisect:*), Bash(git log:*), Bash(git show:*), Bash(git checkout:*), Read, Grep";
  argumentHint = "<good-ref> <bad-ref> [--test=command]";
  prompt = ''
    Use git bisect to efficiently find the commit that introduced a regression.

    **Workflow:**

    1. **Setup Phase**:
       - Confirm the "bad" ref (usually HEAD or current state with the bug)
       - Confirm the "good" ref (a known working commit/tag)
       - Estimate the number of commits to search through
       - Calculate expected number of steps (log2 of commits)

    2. **Bisect Initialization**:
       - Start bisect with `git bisect start`
       - Mark bad commit with `git bisect bad <bad-ref>`
       - Mark good commit with `git bisect good <good-ref>`
       - Git will checkout the middle commit automatically

    3. **Testing Loop**:
       - At each commit, guide user to test for the bug
       - If `--test` provided, run the test command automatically
       - Mark as good or bad based on test results
       - Continue until the culprit commit is found

    4. **Results & Cleanup**:
       - Show the first bad commit with full details
       - Display the commit message, author, and changes
       - Suggest next steps (revert, fix, etc.)
       - Reset with `git bisect reset`

    **Command Arguments:**
    - `<good-ref>`: Known good commit (before the bug existed)
    - `<bad-ref>`: Known bad commit (where the bug exists)
    - `--test=command`: Automated test command (exit 0 = good, non-zero = bad)

    Provide clear guidance on each step and confirm before marking commits.
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
