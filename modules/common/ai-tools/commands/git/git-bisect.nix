let
  commandName = "git-bisect";
  description = "Guided git bisect workflow to find the commit that introduced a regression";
  allowedTools = "Bash(git bisect:*), Bash(git log:*), Bash(git show:*), Bash(git checkout:*), Read, Grep";
  argumentHint = "<good-ref> <bad-ref> [--test=command]";
  prompt = ''
    Find regression commit with `git bisect`.

    Workflow:
    1. Confirm clean worktree, known good ref, known bad ref, and reproducible
       test. Estimate step count with `git rev-list --count <good>..<bad>`.
    2. Start bisect, mark refs, then run provided `--test` command at each step
       when available. Exit 0 means good; non-zero means bad.
    3. If test is manual, ask before each `git bisect good|bad`.
    4. Show first bad commit with `git show --stat --patch`, explain likely
       cause, recommend revert/fix path, then run `git bisect reset`.
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
