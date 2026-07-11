let
  commandName = "check-todos";
in
{
  ${commandName} = {
    inherit
      commandName
      ;

    description = "Report incomplete implementations and actionable TODO markers";
    allowedTools = "Grep, Glob, Read";
    argumentHint = "[directory-scope]";
    prompt = ''
      Run a read-only incomplete-work scan. Scope comes from `$ARGUMENTS`; with no
      argument, scan current directory.

      Search for comment markers (`TODO`, `FIXME`, `HACK`, `XXX`, `BUG`, `ISSUE`),
      placeholder code (`NotImplemented`, `throw new Error("TODO")`, `panic!`,
      `assert(false)`, `unreachable!`, stub returns), mock/test-only data in
      production paths, and placeholder config values.

      Inspect context before classifying each match as actionable or false
      positive. Return counts, actionable `file:line` findings with severity and
      evidence, false-positive count, and a minimal fix plan. Do not edit files.
    '';
  };
}
