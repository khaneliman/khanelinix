let
  commandName = "check-todos";
  description = "Scan codebase for incomplete implementations and TODOs that need completion";
  allowedTools = "Grep, Glob, Read, Edit, Write";
  argumentHint = "[directory-scope]";
  prompt = ''
    Scan target scope for incomplete work and either report or complete it when
    user asked for fixes.

    Search for comment markers (`TODO`, `FIXME`, `HACK`, `XXX`, `BUG`, `ISSUE`),
    placeholder code (`NotImplemented`, `throw new Error("TODO")`, `panic!`,
    `assert(false)`, `unreachable!`, stub returns), mock/test-only data in
    production paths, and placeholder config values.

    For each finding, inspect context before classifying as critical, high,
    medium, low, or false positive. If fixing, make focused edits and rerun the
    scan plus relevant tests. Output counts, actionable file:line findings, fix
    plan or changes made, verification, and residual risk.
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
