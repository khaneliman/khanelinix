let
  commandName = "dependency-audit";
in
{
  ${commandName} = {
    inherit
      commandName
      ;

    description = "Produce a read-only dependency usage, conflict, update, or vulnerability report";
    allowedTools = "Bash(npm audit*), Bash(npm ls*), Bash(pip-audit*), Bash(cargo audit*), Bash(bundle audit*), Read, Grep";
    argumentHint = "[scope] [--unused] [--conflicts] [--updates] [--security]";
    prompt = ''
      Audit dependencies for unused packages, conflicts, updates, and security
      issues selected by `$ARGUMENTS`. With no scope, use current repository; with
      no flags, report all four categories.

      Inspect manifests/lockfiles first, then use ecosystem tools (`npm audit`,
      `npm ls`, `pip-audit`, `cargo audit`, `bundle audit`, etc.) when available.
      For unused detection, verify imports/usages before recommending removal.
      For updates, distinguish safe patch/minor upgrades from breaking changes.

      Return dependency counts, confirmed unused dependencies, conflicts,
      vulnerability severity and fix path, upgrade opportunities, and exact
      follow-up commands. Do not modify manifests or lockfiles.
    '';
  };
}
