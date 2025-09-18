{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.programs.terminal.tools.opencode;
in
{
  options.khanelinix.programs.terminal.tools.opencode = {
    enable = mkEnableOption "OpenCode configuration";
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;

      settings = {
        theme = "opencode";
        model = "anthropic/claude-sonnet-4-20250514";
        autoshare = false;
        autoupdate = false;

        formatter = {
          nixfmt = {
            command = [
              (lib.getExe pkgs.nixfmt)
              "$FILE"
            ];
            extensions = [ ".nix" ];
          };

          csharpier = {
            command = [
              (lib.getExe pkgs.csharpier)
              "$FILE"
            ];
            extensions = [
              ".cs"
            ];
          };

          rustfmt = {
            command = [
              (lib.getExe pkgs.rustfmt)
              "$FILE"
            ];
            extensions = [ ".rs" ];
          };
        };

        mcp = {
          github = {
            type = "local";
            command = [
              (lib.getExe pkgs.github-mcp-server)
              "--read-only"
              "stdio"
            ];
            enabled = true;
          };

          socket = {
            type = "remote";
            url = "https://mcp.socket.dev/";
            enabled = true;
          };
        };
      };

      inherit ((import (lib.getFile "modules/common/ai-tools") { inherit lib; }).claudeCode) agents;

      inherit ((import (lib.getFile "modules/common/ai-tools") { inherit lib; }).claudeCode) commands;
    };
  };
}
