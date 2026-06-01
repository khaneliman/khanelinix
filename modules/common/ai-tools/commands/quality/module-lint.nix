let
  commandName = "module-lint";
  description = "Software module best practices and compliance checking";
  allowedTools = "Read, Grep, Bash(eslint*), Bash(pylint*), Bash(flake8*), Bash(cargo clippy*)";
  argumentHint = "[path] [--fix] [--strict] [--focus=structure|interfaces|docs]";
  prompt = ''
    Check module structure, interfaces, docs, and lint results for target path.

    Read local conventions first. Validate imports, boundaries, public API
    shape, typing, error handling, docs for public/complex APIs, and
    framework-specific module patterns. Run relevant linters (`eslint`, `pylint`,
    `flake8`, `cargo clippy`, etc.) when configured.

    With `--fix`, apply only safe formatter/linter fixes, then rerun checks.
    Report issue count, auto-fixes, manual findings with file:line references,
    and recommendations.
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
