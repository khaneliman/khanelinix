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
    # Unlisted commands do not prompt under the full-access sandbox or
    # approval_policy = "never"; the managed authority gate hook is what holds
    # publishing, pushing, and merging to the user's request.
    ${lib.concatStringsSep "\n" (map renderPrefix permissions.readOnlyShellCommands)}
  '';
}
