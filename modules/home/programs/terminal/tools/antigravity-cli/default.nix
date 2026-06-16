{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;

  cfg = config.khanelinix.programs.terminal.tools.antigravity-cli;
  mcpModuleEnabled = config.khanelinix.programs.terminal.tools.mcp.enable or false;
  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib; };
in
{
  imports = [
    ./permissions.nix
  ];

  options.khanelinix.programs.terminal.tools.antigravity-cli = {
    enable = mkEnableOption "Antigravity CLI configuration";
  };

  config = mkIf cfg.enable {
    home.shellAliases = {
      # Control overrides
      "agy-continue" = "agy --continue";
      "agy-sandbox" = "agy --sandbox";
      "agy-safe" = "agy --sandbox";
      "agy-danger" = "agy --dangerously-skip-permissions";

      # Task shortcuts
      "agy-deep" = "agy --model \"Gemini 3.1 Pro (High)\"";
      "agy-quick" = "agy --model \"Gemini 3.5 Flash (High)\"";
      "agy-nano" = "agy --model \"Gemini 3.5 Flash (Low)\"";
    };

    programs.antigravity-cli = {
      enable = true;
      enableMcpIntegration = mkIf mcpModuleEnabled true;

      settings = {
        allowNonWorkspaceAccess = true;
        altScreenMode = "always";
        colorScheme = "tokyo night";
        toolPermission = "request-review";
        artifactReviewPolicy = "asks-for-review";
        notifications = true;
        showTips = false;
        showFeedbackSurvey = false;
        enableTerminalSandbox = false;
        enableTelemetry = false;
        verbosity = "high";
        runningLightSpeed = "medium";
      };

      inherit (aiTools.antigravityCli) commands skills;
      context = {
        AGENTS = aiTools.base;
      };
    };
  };
}
