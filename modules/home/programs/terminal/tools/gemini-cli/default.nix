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

  sharedAiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib; };

  readOnlyShellRules = [
    {
      toolName = "run_shell_command";
      commandPrefix = [
        "ls "
        "find "
        "cat "
        "head "
        "tail "
        "rg "
        "grep "
        "type "
        "which "
        "whereis "
      ];
      decision = "allow";
      priority = 100;
    }
    {
      toolName = "run_shell_command";
      commandRegex = "ls(\\s|$)";
      decision = "allow";
      priority = 100;
    }
    {
      toolName = "run_shell_command";
      commandRegex = "git (status|diff|log|show|branch|remote|ls-files)(\\s|$)";
      decision = "allow";
      priority = 100;
    }
    {
      toolName = "run_shell_command";
      commandRegex = "nix (eval|search|log|path-info)(\\s|$)";
      decision = "allow";
      priority = 100;
    }
  ];

  riskyShellRules = [
    {
      toolName = "run_shell_command";
      commandPrefix = [
        "git add "
        "cp "
        "mv "
        "chmod "
        "chown "
        "curl "
        "wget "
        "ssh "
        "scp "
        "rsync "
        "nix build "
        "nix run "
        "nix shell "
        "nixos-rebuild "
        "darwin-rebuild "
        "nh "
        "kill "
        "killall "
        "pkill "
        "build-by-path "
        "why-depends "
      ];
      decision = "ask_user";
      priority = 200;
    }
    {
      toolName = "run_shell_command";
      commandRegex = "git (commit|checkout|switch|restore|reset|stash|merge|rebase|pull|push)(\\s|$)";
      decision = "ask_user";
      priority = 200;
    }
    {
      toolName = "run_shell_command";
      commandRegex = "fix-git(\\s|$)";
      decision = "ask_user";
      priority = 200;
    }
  ];

  denyDangerousShellRules = [
    {
      toolName = "run_shell_command";
      commandRegex = "sudo rm(\\s|$)";
      decision = "deny";
      priority = 300;
      deny_message = "Blocked by Gemini CLI safety policy.";
    }
    {
      toolName = "run_shell_command";
      commandRegex = "rm -rf (/$|~(/|$))";
      decision = "deny";
      priority = 300;
      deny_message = "Blocked by Gemini CLI safety policy.";
    }
    {
      toolName = "run_shell_command";
      commandRegex = "(dd|mkfs)(\\s|$)";
      decision = "deny";
      priority = 300;
      deny_message = "Blocked by Gemini CLI safety policy.";
    }
    {
      toolName = "run_shell_command";
      commandRegex = "(shutdown|reboot)(\\s|$)";
      decision = "deny";
      priority = 300;
      deny_message = "Blocked by Gemini CLI safety policy.";
    }
  ];
in
{
  options.khanelinix.programs.terminal.tools.gemini-cli = {
    enable = mkEnableOption "Gemini CLI configuration";
  };

  config = mkIf cfg.enable {
    programs.gemini-cli = {
      # Gemini CLI documentation
      # See: https://github.com/google-gemini/gemini-cli
      enable = true;
      enableMcpIntegration = mkIf mcpModuleEnabled true;

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
          taskTracker = true;
          modelSteering = true;
          topicUpdateNarration = true;
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
          };
          inlineThinkingMode = "full";
          showCitations = true;
          showModelInfoInChat = true;
          showStatusInTitle = true;
          theme = "GitHub";
          useAlternateBuffer = true;
          showMemoryUsage = true;
        };
      };

      policies = {
        read-only-shell.rule = readOnlyShellRules;
        risky-shell.rule = riskyShellRules;
        deny-dangerous-shell.rule = denyDangerousShellRules;
      };

      context = {
        AGENTS = sharedAiTools.base;
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

          "git/fix-git" = {
            prompt = ''
              If you suspect the local git repository is corrupted, use the `fix-git`
              utility to replace your local history with that of the remote.
              This will rewrite history but leave the working tree intact.
            '';
            description = "Replace local git history with remote when corruption is suspected";
          };

          "nix/build-by-path" = {
            prompt = ''
              Your task is to build a nixpkgs package by its attribute path using
              `build-by-path.sh`. This avoids evaluating the entire nixpkgs.
              Input should be the attribute path.
            '';
            description = "Build a nixpkgs package by attribute path efficiently";
          };

          "nix/why-depends" = {
            prompt = ''
              Your task is to determine why a package depends on another in the
              Nix closure. Use `why-depends.sh` with the source and target paths.
            '';
            description = "Determine closure dependency reasons between two packages";
          };
        };
    }
    // lib.optionalAttrs (!codexEnabled) {
      inherit (sharedAiTools.geminiCli) skills;
    };
  };
}
