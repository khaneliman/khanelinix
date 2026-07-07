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
    # Mutating commands intentionally stay off this allowlist so Codex falls
    # back to approval_policy = "on-request" in default.nix.
    ${lib.concatStringsSep "\n" (map renderPrefix permissions.readOnlyShellCommands)}
  '';
}
