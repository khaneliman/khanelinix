{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.antigravity-cli;
  permissions = import (lib.getFile "modules/common/ai-tools/permissions.nix");

  renderMcpPermission =
    permission:
    let
      parts = lib.splitString "__" permission;
      # Codex normalizes MCP server hyphens to underscores in tool names.
      server = lib.replaceStrings [ "_" ] [ "-" ] (builtins.elemAt parts 1);
      tool = builtins.elemAt parts 2;
    in
    "mcp(${server}/${tool})";
in
{
  config = lib.mkIf cfg.enable {
    programs.antigravity-cli = {
      settings.permissions = {
        allow =
          map (command: "command(${command})") permissions.readOnlyShellCommands
          ++ map renderMcpPermission permissions.readOnlyMcpTools;
        ask = map (command: "command(${command})") permissions.askShellCommands;
        deny = map (command: "command(${command})") permissions.denyShellCommands;
      };
    };
  };
}
