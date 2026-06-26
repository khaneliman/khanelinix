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
    home = {
      # TODO: Upstream to home manager?
      # NOTE: antigravity will mutate config and replace file.
      file.".gemini/antigravity-cli/settings.json".force = true;
      shellAliases = {
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
        trustedWorkspaces =
          let
            documentsPath =
              if config.xdg.userDirs.enable then
                config.xdg.userDirs.documents
              else
                config.home.homeDirectory + lib.optionalString pkgs.stdenv.hostPlatform.isLinux "/Documents";
            githubRoot =
              if pkgs.stdenv.hostPlatform.isLinux then
                "${documentsPath}/github"
              else
                "${config.home.homeDirectory}/github";

            trustedGithubProjects = [
              "home-manager"
              "khanelivim"
              "nixpkgs"
              "nixvim"
              "Austin-Horstman"
              "neotest-nix"
              "waybar"
            ];
          in
          [
            "${config.home.homeDirectory}/khanelinix"
          ]
          ++ map (project: "${githubRoot}/${project}") trustedGithubProjects;
      };

      inherit (aiTools.antigravityCli) commands skills;
      context = {
        AGENTS = aiTools.base;
      };
    };
  };
}
