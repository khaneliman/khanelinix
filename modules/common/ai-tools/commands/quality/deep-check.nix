let
  commandName = "deep-check";
in
{
  ${commandName} = {
    inherit
      commandName
      ;

    description = "Comprehensive codebase analysis including unused code detection and optimization";
    allowedTools = "Bash(npm*), Bash(cargo*), Bash(make*), Bash(python*), Bash(go*), Bash(node*), Read, Grep";
    argumentHint = "[scope] [--with-builds] [--security] [--performance]";
    prompt = ''
      Run high-signal project health analysis for target scope.

      Workflow:
      1. Read project docs/manifests to identify build, test, lint, and check
         commands. Run narrow checks first; use `--with-builds` for broader builds.
      2. Look for dead code, unused imports/deps, deprecated options, duplicated
         logic, brittle module boundaries, slow paths, and redundant work.
      3. If `--security`, include obvious secrets, unsafe defaults, validation
         gaps, and permission mistakes. Use security skill only for dedicated
         security review depth.
      4. Report only evidence-backed critical issues, warnings, suggestions, and
         recommended actions with file:line references.
    '';
  };
}
