let
  commandName = "parse-sarif";
in
{
  ${commandName} = {
    inherit
      commandName
      ;

    description = "Parse and split large SARIF code analysis files for parallel development work";
    allowedTools = "Bash, Read, Write, Grep, Glob";
    argumentHint = "[sarif-file-path]";
    prompt = ''
      Parse large SARIF files without loading full JSON into chat.

      Use `jq` for structure, counts, grouping, and split-file generation. Inspect
      schema/version, runs, tool name, result count, artifact count, top `ruleId`
      values, severities, affected paths, and representative locations/messages.

      Choose split strategy by requested goal: rule type, file path, severity, or
      balanced count. Write focused chunk files only when useful for parallel work.

      Output total issues, affected files, top rules, split files created, and
      recommended assignment/fix order.
    '';
  };
}
