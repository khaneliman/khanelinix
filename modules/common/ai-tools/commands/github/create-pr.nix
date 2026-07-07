let
  commandName = "create-pr";
in
{
  ${commandName} = {
    inherit
      commandName
      ;

    description = "Draft or create a GitHub pull request from current branch";
    allowedTools = "Bash(gh auth status:*), Bash(gh api:*), Bash(gh pr create:*), Bash(gh pr view:*), Bash(gh repo view:*), Bash(git branch:*), Bash(git diff:*), Bash(git log:*), Bash(git remote:*), Bash(git status:*), Bash(rg:*), Read, Grep, Glob";
    argumentHint = "[base] [--draft] [--submit]";
    prompt = ''
      Prepare PR for current branch. Inputs are command arguments or invoking user
      message: $ARGUMENTS.

      Use `github-toolkit` in pull-request-creation mode and `git-toolkit` in
      workflow/commit-message mode.

      Hard rules:
      - `--submit` is the only permission to create a GitHub PR.
      - Never push, force-push, rebase, amend, or edit files.
      - If branch is unpushed, dirty, or missing required template context, stop
        with title/body and exact blocker.

      Workflow:
      1. Resolve repo, current branch, base branch, remote, commits, diff, checks,
         related issues, and dirty worktree state.
      2. Read `CONTRIBUTING.md`, PR template, root and changed-path
         `AGENTS.md`/`CLAUDE.md`, and directly relevant docs. If multiple PR
         templates fit and user did not choose one, stop.
      3. Fill the selected template exactly. Preserve headings, required fields,
         labels, and checkboxes. Keep prose concise.
      4. Note contribution gaps before submit: missing tests, docs, issue links,
         atomic commit concerns, secrets/licensing risks, or unpushed commits.

      Without `--submit`, output title/body only. With `--submit`, create the PR
      using the filled template; use draft PR when `--draft` is present.
    '';
  };
}
