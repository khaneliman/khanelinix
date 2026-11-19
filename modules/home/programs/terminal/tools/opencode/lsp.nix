{
  config,
  lib,
  pkgs,
  self,
  hostname ? null,
  ...
}:
let
  servers = import (lib.getFile "modules/common/ai-tools/lsp-catalog.nix") {
    inherit lib pkgs;
    userName = config.khanelinix.user.name;
    nixdContext = {
      inherit self hostname;
      username = config.home.username;
    };
  };
in
{
  programs.opencode.settings.lsp = lib.mapAttrs (
    _: server:
    {
      command = [ server.command ] ++ (server.args or [ ]);
      extensions = map (extension: extension.name) server.extensions;
    }
    // lib.optionalAttrs (server ? initializationOptions) {
      initialization = server.initializationOptions;
    }
  ) servers;
}
