let
  commandName = "triage-issue";
in
{
  ${commandName} = {
    inherit
      commandName
      ;

    description = "Triage a GitHub issue and draft concise next-step guidance";
    allowedTools = "Bash(gh auth status:*), Bash(gh issue view:*), Bash(gh issue list:*), Bash(gh search:*), Bash(gh api:*), Bash(gh pr view:*), Bash(gh pr list:*), Bash(git remote:*), Bash(rg:*), Read, Grep, Glob";
    argumentHint = "<issue-number|issue-url|search> [--repo owner/repo]";
    prompt = ''
      Run read-only GitHub issue triage. Target is command arguments or invoking
      user message: $ARGUMENTS.

      If target is a number, use current repo unless `--repo` is provided. If it is
      a URL, use that owner/repo. If it is search text, find candidate open issues.

      Use `github-toolkit` in issue-triage mode. Use `git-toolkit` workflow mode
      only for branch, commit, or follow-up implementation guidance. If the issue
      touches a specific language or domain, load the matching toolkit skill before
      proposing code direction.

      Workflow:
      1. Resolve issue metadata, labels, comments, linked PRs, duplicates, and
         current status.
      2. Read repository guidance: `CONTRIBUTING.md`, issue templates, root
         `AGENTS.md`/`CLAUDE.md`, and directly relevant docs.
      3. Classify as bug, feature, docs, question, support, duplicate, stale, or
         needs-info. Separate confirmed facts from inference.
      4. Recommend the smallest useful next step: request info, link docs, close as
         duplicate/not planned, label/route, or outline implementation.

      Output concise triage:
      - Target and classification.
      - Evidence, missing info, and relevant docs/guidelines to cite.
      - Recommended next action.
      - Draft GitHub reply text.
      - If implementing: minimal branch, commit, and validation plan.

      Do not comment, label, close, assign, push, or edit files.
    '';
  };
}
