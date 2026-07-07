{ lib, ... }:
let
  permissions = import (lib.getFile "modules/common/ai-tools/permissions.nix");

  globPermissionAttrs =
    decision: commands:
    builtins.listToAttrs (
      map (command: {
        name = "${command}*";
        value = decision;
      }) commands
    );
in
{
  config = {
    programs.opencode.settings.permission = {
      edit = "ask";
      bash =
        globPermissionAttrs "allow" permissions.readOnlyShellCommands
        // globPermissionAttrs "ask" permissions.askShellCommands;
      read = "allow";
      list = "allow";
      glob = "allow";
      grep = "allow";
      webfetch = "ask";
      write = "ask";
      task = "allow";
      todowrite = "allow";
      todoread = "allow";
    };
  };
}
