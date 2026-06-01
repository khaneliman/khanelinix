let
  commandName = "resolve-conflicts";
  description = "Guided merge conflict resolution with context and recommendations";
  allowedTools = "Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Read, Edit";
  argumentHint = "[file] [--strategy=ours|theirs|manual]";
  prompt = ''
    Resolve merge conflicts with evidence.

    Workflow:
    1. Use `git status` and focused `git diff --cc` to list conflicts.
    2. For each target file, identify ours/theirs meaning for current operation
       and inspect both sides with `git show` or stage-specific diffs.
    3. Apply requested strategy only when safe; otherwise create minimal manual
       merge preserving both intended behaviors.
    4. Remove markers, stage resolved files, search for leftover conflict
       markers, and recommend focused validation.

    Explain semantic choices and risky assumptions before editing.
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
