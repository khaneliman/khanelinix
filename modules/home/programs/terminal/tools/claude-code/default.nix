{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;

  cfg = config.khanelinix.programs.terminal.tools.claude-code;
  mcpModuleEnabled = config.khanelinix.programs.terminal.tools.mcp.enable or false;
  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib pkgs; };

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

      enableMcpIntegration = mkIf mcpModuleEnabled true;

      settings = {
        theme = "dark";

        hooks = lib.importDir ./hooks { inherit pkgs config lib; };

        model = "opus[1m]";
        effortLevel = "xhigh";
        alwaysThinkingEnabled = true;
        verbose = true;
        includeCoAuthoredBy = false;
        gitAttribution = false;
        attribution = {
          commit = "";
          pr = "";
        };

        statusLine = {
          type = "command";
          command = "input=$(cat); echo \"[$(echo \"$input\" | jq -r '.model.display_name')] 📁 $(basename \"$(echo \"$input\" | jq -r '.workspace.current_dir')\")\"";
          padding = 0;
        };

        env = {
          USE_BUILTIN_RIPGREP = "0";
          ANTHROPIC_DEFAULT_HAIKU_MODEL = "claude-haiku-4-5";
        }
        // lib.optionalAttrs mcpModuleEnabled {
          ENABLE_TOOL_SEARCH = "auto:5";
        };
      };

      inherit (aiTools.claudeCode) agents commands;
      inherit (aiTools.claudeCode) skills;
      context = aiTools.base;
    };
  };
}
