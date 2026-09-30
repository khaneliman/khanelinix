{ lib, ... }:
let
  permissions = import ../../../../../common/ai-tools/permissions.nix;
  renderPrefix =
    command:
    let
      pattern = lib.splitString " " command;
    in
    "prefix_rule(pattern = ${builtins.toJSON pattern}, decision = \"allow\")";
in
{
  "read-only" = ''
    # Read-only shell commands that should not require repeated approvals.
    ${lib.concatStringsSep "\n" (map renderPrefix permissions.readOnlyShellCommands)}
  '';
}
