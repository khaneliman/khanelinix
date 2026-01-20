let
  commandName = "git-resolve";
  description = "Guided merge conflict resolution with context and recommendations";
  allowedTools = "Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Read, Edit";
  argumentHint = "[file] [--strategy=ours|theirs|manual]";
  prompt = ''
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

    Resolve conflicts carefully and ensure resulting code is correct and consistent.
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
