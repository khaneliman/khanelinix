let
  commandName = "style-audit";
  description = "Comprehensive style compliance checking against project standards";
  allowedTools = "Read, Grep, Bash(eslint*), Bash(prettier*), Bash(black*), Bash(flake8*), Bash(rustfmt*), Bash(gofmt*), Bash(nix fmt*), Bash(nixfmt*), Bash(treefmt*)";
  argumentHint = "[path] [--fix] [--report] [--focus=naming|structure|imports|organization]";
  prompt = ''
    Audit style against project standards, not personal preference.

    Read config and nearby examples first (`.eslintrc`, prettier config,
    `pyproject.toml`, rustfmt, gofmt, nix fmt/treefmt, etc.). Run relevant
    formatters/linters in check mode. Focus on requested style area: naming,
    structure, imports, or organization.

    With `--fix`, apply safe auto-format or auto-fix, then rerun checks. Report
    files checked, violations, auto-fixes, remaining manual issues, and
    recommendations.
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
