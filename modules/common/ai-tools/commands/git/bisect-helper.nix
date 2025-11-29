{
  git-bisect = ''
    ---
    allowed-tools: Bash(git bisect:*), Bash(git log:*), Bash(git show:*), Bash(git checkout:*), Read, Grep
    argument-hint: "<good-ref> <bad-ref> [--test=command]"
    description: Guided git bisect workflow to find the commit that introduced a regression
    ---

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

    **Bisect Commands:**

    ```bash
    # Start bisect
    git bisect start
    git bisect bad HEAD
    git bisect good v1.0.0

    # Manual marking
    git bisect good  # Current commit is good
    git bisect bad   # Current commit is bad

    # Automated bisect
    git bisect run ./test-script.sh

    # Skip untestable commit
    git bisect skip

    # View bisect log
    git bisect log

    # End bisect
    git bisect reset
    ```

    **Automated Test Script Example:**

    ```bash
    #!/bin/bash
    # test-regression.sh
    make build && ./run-specific-test
    # Exit code determines good (0) or bad (non-zero)
    ```

    **Tips:**
    - If a commit can't be tested, use `git bisect skip`
    - Save progress with `git bisect log > bisect.log`
    - Replay bisect with `git bisect replay bisect.log`
    - For build failures, script should exit 125 to skip

    **Important Limitations:**
    - Bisect works best with linear history
    - With merge commits, bisect may check commits from merged branches
    - Consider using `git bisect --first-parent` to stay on main branch
    - For complex merge histories, you may need to bisect manually

    Guide the user through each step, explaining what git is doing and why.
  '';
}
