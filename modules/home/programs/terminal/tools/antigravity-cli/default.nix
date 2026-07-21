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
  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib pkgs; };
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
      file.".gemini/config/plugins/okf-memory".source =
        lib.mkDefault aiTools.antigravityCli.okfMemoryPlugin;
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

      settings =
        let
          statusLineScript = pkgs.writeShellApplication {
            name = "agy-statusline";
            runtimeInputs = [ pkgs.jq ];
            text = ''
              input=$(cat)
              jq -r '
                def pc(v): (v // 0) | floor | tostring;
                (.model.display_name // .model // "?") as $name |
                ( "[" + $name
                  + (if (.effort.level // "") != "" then " " + .effort.level else "" end)
                  + (if .thinking.enabled == true then " +think" else "" end)
                  + "]" )
                + " 📁 " + (((.workspace.current_dir // .cwd // "") | split("/") | last))
                + (if .context_window.used_percentage != null
                   then " | ctx " + pc(.context_window.used_percentage) + "%"
                   else "" end)
              ' <<<"$input"
            '';
          };

          titleScript = pkgs.writeShellApplication {
            name = "agy-title";
            runtimeInputs = [ pkgs.jq ];
            text = ''
              input=$(cat)
              jq -r '
                (.model.display_name // .model // "?") as $name |
                "agy | " + $name + " | 📁 " + (((.workspace.current_dir // .cwd // "") | split("/") | last))
              ' <<<"$input"
            '';
          };

        in
        {
          model = "Gemini 3.5 Flash (High)";
          historySize = 5000;
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

          statusLine = {
            type = "command";
            command = lib.getExe statusLineScript;
            enabled = true;
          };

          title = {
            type = "command";
            command = lib.getExe titleScript;
            enabled = true;
          };

          modelConfigs = {
            overrides = [
              {
                match = {
                  model = "*";
                };
                modelConfig = {
                  generateContentConfig = {
                    maxOutputTokens = 65536;
                  };
                };
              }
              {
                match = {
                  model = "* (Thinking)";
                };
                modelConfig = {
                  generateContentConfig = {
                    thinkingConfig = {
                      thinkingLevel = "MAX";
                    };
                  };
                };
              }
            ];
          };

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

      inherit (aiTools.antigravityCli) skills;
      context = {
        AGENTS = aiTools.base;
      };
    };
  };
}
