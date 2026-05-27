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

  # Codex-style status line: model+reasoning, dir, context usage, 5h limit.
  # Rate-limit fields only appear for Claude.ai subscribers, so guard for null.
  statusLineScript = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      input=$(cat)
      jq -r '
        def pc(v): (v // 0) | floor | tostring;
        (.model.display_name // "?") as $name |
        ( "[" + $name
          + (if ((.model.id // "") | test("\\[1m\\]")) and (($name | ascii_downcase) | test("1m") | not)
             then " ·1M" else "" end)
          + (if (.effort.level // "") != "" then " " + .effort.level else "" end)
          + (if .thinking.enabled == true then " +think" else "" end)
          + "]" )
        + " 📁 " + (((.workspace.current_dir // .cwd // "") | split("/") | last))
        + (if .context_window.used_percentage != null
           then " | ctx " + pc(.context_window.used_percentage) + "%"
           else "" end)
        + (if .rate_limits.five_hour.used_percentage != null
           then " | 5h " + pc(.rate_limits.five_hour.used_percentage) + "%"
           else "" end)
        + (if .rate_limits.seven_day.used_percentage != null
           then " | 7d " + pc(.rate_limits.seven_day.used_percentage) + "%"
           else "" end)
      ' <<<"$input"
    '';
  };
in
{
  imports = [
    ./lsp.nix
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
        # Usage credits
        # fastMode = true;
        cleanupPeriodDays = 90;
        verbose = true;
        includeCoAuthoredBy = false;
        gitAttribution = false;
        attribution = {
          commit = "";
          pr = "";
        };

        statusLine = {
          type = "command";
          command = lib.getExe statusLineScript;
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
