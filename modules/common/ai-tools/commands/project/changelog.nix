let
  commandName = "changelog";
in
{
  ${commandName} = {
    inherit
      commandName
      ;

    description = "Generate and maintain project changelog following established conventions and standards";
    allowedTools = "Bash(git log:*), Bash(git diff:*), Bash(git tag:*), Edit, Read, Write";
    argumentHint = "[version] [--since=tag|date] [--format=keepachangelog|conventional]";
    prompt = ''
      Generate or update one canonical changelog using existing project
      convention. Inputs come from `$ARGUMENTS`; with no arguments, use the
      unreleased range from the latest release tag to `HEAD`.

      Workflow:
      1. Find `CHANGELOG.md`, `HISTORY.md`, `CHANGES.md`, `NEWS.md`,
         `RELEASES.md`, or docs equivalents; infer format, version style, date
         style, and section names.
      2. Determine range from `[version]`, `--since`, last tag, or project
         release pattern. Classify commits by user-visible impact and breaking
         changes.
      3. Write concise user-facing entries. Prefer existing format; use
         `--format` only when no convention exists or user requests override.
      4. Insert at top without rewriting history. Preserve links and headings.

      If the destination or commit range is ambiguous, make no edits and return a
      concise blocker. Otherwise report baseline, commit range, changed file, and
      any omitted internal-only commits.
    '';
  };
}
