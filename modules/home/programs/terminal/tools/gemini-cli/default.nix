{
  config,
  lib,
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
    home.file.".gemini/policies/read-only-shell.toml".text = ''
      [[rule]]
      toolName = "run_shell_command"
      commandPrefix = [
        "ls",
        "ls ",
        "find ",
        "cat ",
        "head ",
        "tail ",
        "rg ",
        "grep ",
        "git status",
        "git diff",
        "git log",
        "git show",
        "git branch",
        "git remote",
        "git ls-files",
        "nix eval",
        "nix search",
        "nix log",
        "nix path-info",
        "type ",
        "which ",
        "whereis "
      ]
      decision = "allow"
      priority = 100
    '';

    programs.gemini-cli = {
      # Gemini CLI documentation
      # See: https://github.com/google-gemini/gemini-cli
      enable = true;

      settings = {
        contextFilename = "AGENTS.md";

        context = {
          discoveryMaxDirs = 1000;
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
        experimental.plan = true;
        general = {
          checkpointing = {
            enabled = true;
          };
          enablePromptCompletion = true;
          preferredEditor = "neovim";
          previewFeatures = true;
          sessionRetention = {
            enabled = true;
            maxAge = "30d";
            maxCount = 100;
          };
          vimMode = true;
        };
        ide.enabled = true;
        privacy.usageStatisticsEnabled = false;
        security = {
          auth = {
            selectedType = "oauth-personal";
          };
          folderTrust = {
            enabled = true;
          };
        };
        tools = {
          autoAccept = false;
          shell.showColor = true;
        };
        ui = {
          footer = {
            hideContextPercentage = false;
          };
          inlineThinkingMode = "full";
          showCitations = true;
          showModelInfoInChat = true;
          showStatusInTitle = true;
          theme = "Default";
          useAlternateBuffer = true;
        };
      };

      context = {
        AGENTS = lib.getFile "modules/common/ai-tools/base.md";
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
