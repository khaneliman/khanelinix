{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.antigravity-cli;
  permissions = import (lib.getFile "modules/common/ai-tools/permissions.nix");
in
{
  config = lib.mkIf cfg.enable {
    programs.antigravity-cli = {
      settings.permissions = {
        allow = map (command: "command(${command})") permissions.readOnlyShellCommands;
        ask = map (command: "command(${command})") permissions.askShellCommands;
        deny = map (command: "command(${command})") permissions.denyShellCommands;
      };
    };
  };
}
