{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.programs.terminal.tools.gemini-cli;

  sharedAiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib; };
in
{
  options.khanelinix.programs.terminal.tools.gemini-cli = {
    enable = mkEnableOption "Gemini CLI configuration";
  };

  config = mkIf cfg.enable {
    # Force Gemini to use the system's (newer) ripgrep
    # This prevents crashes when the agent's bundled (older) rg reads the global config
    # containing flags it doesn't understand (like --hyperlink-format).
    home.file.".gemini/tmp/bin/rg" = {
      source = lib.getExe pkgs.ripgrep;
    };

    programs.gemini-cli = {
      enable = true;

      settings = {
        ui = {
          theme = "Default";
          footer = {
            hideContextPercentage = false;
          };
          showCitations = true;
          showModelInfoInChat = true;
          showStatusInTitle = true;
        };
        general = {
          vimMode = true;
          preferredEditor = "nvim";
          previewFeatures = true;
          checkpointing = {
            enabled = true;
          };
        };
        ide.enabled = true;
        privacy.usageStatisticsEnabled = false;
        tools.autoAccept = false;
        context = {
          discoveryMaxDirs = 1000;
          includeDirectories = [
            "lib"
            "modules"
            "docs"
          ];
          loadMemoryFromIncludeDirectories = true;
          fileFiltering = {
            respectGitIgnore = true;
            respectGeminiIgnore = true;
            enableRecursiveFileSearch = true;
            disableFuzzySearch = false;
          };
        };
        security = {
          auth = {
            selectedType = "oauth-personal";
          };
        };
      };

      context = {
        GEMINI = lib.getFile "modules/common/ai-tools/base.md";
      };

      commands =
        sharedAiTools.geminiCli.commands
        // sharedAiTools.geminiCli.agents
        // {
          changelog = {
            prompt = ''
              Your task is to parse the version, change type, and message from the input
              and update the CHANGELOG.md file accordingly following
              conventional commit standards.
            '';
            description = "Update CHANGELOG.md with new entry following conventional commit standards";
          };

          review = {
            prompt = ''
              Analyze the staged git changes and provide a thorough
              code review with suggestions for improvement, focusing on
              code quality, security, and maintainability.
            '';
            description = "Analyze staged git changes and provide thorough code review";
          };

          "git/commit-msg" = {
            prompt = ''
              Generate a conventional commit message based on the
              staged changes, following the project's commit standards.
              Analyze the changes and create an appropriate commit message.
            '';
            description = "Generate conventional commit message based on staged changes";
          };
        };
    };
  };
}
