let
  commandName = "create-issue";
in
{
  ${commandName} = {
    inherit
      commandName
      ;

    description = "Draft or create a GitHub issue from notes or logs";
    allowedTools = "Bash(gh auth status:*), Bash(gh api:*), Bash(gh issue create:*), Bash(gh issue list:*), Bash(gh repo view:*), Bash(rg:*), Read, Grep, Glob, Write";
    argumentHint = "<notes|file|url> [--repo owner/repo] [--submit]";
    prompt = ''
      Prepare GitHub issue from command arguments or invoking user message:
      $ARGUMENTS.

      Use `github-toolkit` in issue-creation mode.

      Hard rules:
      - `--submit` is the only permission to create a GitHub issue.
      - Never label, assign, close, or edit unrelated files.
      - If required template choice or contribution context is ambiguous, stop
        with a concise blocker and draft nothing.

      Workflow:
      1. Resolve target repo and source notes/logs. Redact secrets.
      2. Read `CONTRIBUTING.md`, issue templates, root `AGENTS.md`/`CLAUDE.md`,
         and directly relevant docs. If multiple issue templates fit and user did
         not choose one, stop.
      3. Fill the selected template exactly. Preserve headings, required fields,
         labels, and checkboxes. Keep prose concise and evidence-backed.
      4. Check for likely duplicates or linked PRs before submit.

      Without `--submit`, write the draft to `issues/YYYY-MM-DD-short-title.md`
      and report the path. With `--submit`, create the issue from the filled
      template.
    '';
  };
}
