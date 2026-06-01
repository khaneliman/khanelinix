let
  commandName = "dependency-audit";
  description = "Check and optimize project dependencies and package management";
  allowedTools = "Bash(npm audit*), Bash(npm ls*), Bash(pip-audit*), Bash(cargo audit*), Bash(bundle audit*), Read, Grep";
  argumentHint = "[--unused] [--conflicts] [--updates] [--security] [--report]";
  prompt = ''
    Audit dependencies for unused packages, conflicts, updates, and security
    issues according to requested flags.

    Inspect manifests/lockfiles first, then use ecosystem tools (`npm audit`,
    `npm ls`, `pip-audit`, `cargo audit`, `bundle audit`, etc.) when available.
    For unused detection, verify imports/usages before recommending removal.
    For updates, distinguish safe patch/minor upgrades from breaking changes.

    Output dependency counts, confirmed unused deps, vulnerability severity and
    fix path, upgrade opportunities, and commands or file edits needed.
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
