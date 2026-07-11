let
  commandName = "parse-sarif";
in
{
  ${commandName} = {
    inherit
      commandName
      ;

    description = "Parse and split large SARIF code analysis files for parallel development work";
    allowedTools = "Bash(jq:*), Read, Write, Glob";
    argumentHint = "<sarif-file-path> [--split=rule|path|severity|balanced] [--chunks=count]";
    prompt = ''
      Parse the SARIF file named in `$ARGUMENTS` without loading full JSON into
      chat. A file path is required.

      Use `jq` for structure, counts, grouping, and split-file generation. Inspect
      schema/version, runs, tool name, result count, artifact count, top `ruleId`
      values, severities, affected paths, and representative locations/messages.

      Write chunk files only when `--split` is present. Use its exact strategy;
      `--chunks` applies only to balanced splitting. Without `--split`, produce a
      report and do not write files.

      Output total issues, affected files, top rules, split files created, and
      recommended assignment/fix order.
    '';
  };
}
