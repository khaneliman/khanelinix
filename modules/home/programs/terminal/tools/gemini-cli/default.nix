{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.programs.terminal.tools.gemini-cli;
  codexEnabled = config.khanelinix.programs.terminal.tools.codex.enable or false;
  mcpModuleEnabled = config.khanelinix.programs.terminal.tools.mcp.enable or false;

  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib; };
in
{
  imports = [
    ./rules.nix
  ];

  options.khanelinix.programs.terminal.tools.gemini-cli = {
    enable = mkEnableOption "Gemini CLI configuration";
  };

  config = mkIf cfg.enable {
    programs.gemini-cli = {
      # Gemini CLI documentation
      # See: https://github.com/google-gemini/gemini-cli
      enable = true;
      enableMcpIntegration = mkIf mcpModuleEnabled true;

      inherit (aiTools.geminiCli) commands;

      settings = {
        context = {
          fileName = [
            "AGENTS.md"
            "GEMINI.md"
          ];
          discoveryMaxDirs = 1000;
          memoryBoundaryMarkers = [
            ".git"
            ".jj"
          ];
          # NOTE: bombs out on repos that don't have them
          # includeDirectories = [
          #   "lib"
          #   "modules"
          #   "docs"
          # ];
          loadMemoryFromIncludeDirectories = true;
          fileFiltering = {
            enableFuzzySearch = true;
            enableRecursiveFileSearch = true;
            respectGeminiIgnore = true;
            respectGitIgnore = true;
          };
        };

        experimental = {
          contextManagement = true;
          directWebFetch = true;
          memoryManager = true;
          modelSteering = true;
          taskTracker = true;
          topicUpdateNarration = true;
          useOSC52Copy = true;
          useOSC52Paste = true;
          worktrees = true;
        };

        advanced = {
          autoConfigureMemory = true;
        };

        general = {
          checkpointing = {
            enabled = true;
          };
          enableNotifications = true;
          preferredEditor = "neovim";
          sessionRetention = {
            enabled = true;
            maxAge = "30d";
            maxCount = 100;
          };
          vimMode = true;
          plan = {
            enabled = true;
            modelRouting = true;
          };
        };

        ide.enabled = true;

        model = {
          compressionThreshold = 0.7;
        };

        privacy.usageStatisticsEnabled = false;

        security = {
          auth = {
            selectedType = "oauth-personal";
          };
          folderTrust = {
            enabled = true;
          };
          environmentVariableRedaction = {
            enabled = true;
          };
          enablePermanentToolApproval = true;
        };

        tools = {
          shell.showColor = true;
          useRipgrep = true;
          truncateToolOutputThreshold = 50000;
        };

        ui = {
          compactToolOutput = true;
          dynamicWindowTitle = true;
          footer = {
            hideContextPercentage = false;
            hideSandboxStatus = true;
          };
          inlineThinkingMode = "full";
          loadingPhrases = "tips";
          showCitations = true;
          showMemoryUsage = true;
          showModelInfoInChat = true;
          showStatusInTitle = true;
          showUserIdentity = false;
          theme = "GitHub";
          useAlternateBuffer = true;
        };
      };

      context = {
        AGENTS = aiTools.base;
      };

      # NOTE: `codex` deploys to `.agents/skill`
      # Gemini picks up both and duplicates context
      skills = lib.mkIf (!codexEnabled) aiTools.skills;
    };
  };
}
