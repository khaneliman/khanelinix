{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.programs.terminal.tools.claude-code;

  claudeIcon = ./assets/claude.ico;
in
{
  imports = [
    ./permissions.nix
  ];

  options.khanelinix.programs.terminal.tools.claude-code = {
    enable = mkEnableOption "Claude Code configuration";
  };

  config = mkIf cfg.enable {
    # Install Claude icon for notifications
    xdg.dataFile."icons/claude.ico".source = claudeIcon;

    programs.claude-code = {
      enable = true;

      mcpServers = {
        github = {
          type = "stdio";
          command = lib.getExe pkgs.github-mcp-server;
          args = [
            # NOTE: avoid accidentally causing unexpected changes with default MCP and whitelist allow
            "--read-only"
            "stdio"
          ];
        };

        socket = {
          type = "http";
          url = "https://mcp.socket.dev/";
        };
      };

      settings = {
        theme = "dark";

        hooks = lib.importDir ./hooks { inherit pkgs; };

        # Let default do its job
        # model = "claude-sonnet-4-5";
        verbose = true;
        includeCoAuthoredBy = false;

        statusLine = {
          type = "command";
          command = "input=$(cat); echo \"[$(echo \"$input\" | jq -r '.model.display_name')] 📁 $(basename \"$(echo \"$input\" | jq -r '.workspace.current_dir')\")\"";
          padding = 0;
        };
      };

      inherit ((import (lib.getFile "modules/common/ai-tools") { inherit lib; }).claudeCode) agents;

      inherit ((import (lib.getFile "modules/common/ai-tools") { inherit lib; }).claudeCode) commands;

      inherit ((import (lib.getFile "modules/common/ai-tools") { inherit lib; }).claudeCode) skills;

      memory.source = lib.getFile "modules/common/ai-tools/base.md";
    };
  };
}
