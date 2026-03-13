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
    home.file = {
      ".gemini/policies/read-only-shell.toml".text = ''
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

      ".gemini/policies/risky-shell.toml".text = ''
        [[rule]]
        toolName = "run_shell_command"
        commandPrefix = [
          "git add ",
          "git commit",
          "git checkout",
          "git switch",
          "git restore",
          "git reset",
          "git stash",
          "git merge",
          "git rebase",
          "git pull",
          "git push",
          "cp ",
          "mv ",
          "chmod ",
          "chown ",
          "curl ",
          "wget ",
          "ssh ",
          "scp ",
          "rsync ",
          "nix build ",
          "nix run ",
          "nix shell ",
          "nixos-rebuild ",
          "darwin-rebuild ",
          "nh ",
          "kill ",
          "killall ",
          "pkill ",
          "fix-git",
          "build-by-path ",
          "why-depends "
        ]
        decision = "ask_user"
        priority = 200
      '';

      ".gemini/policies/deny-dangerous-shell.toml".text = ''
        [[rule]]
        toolName = "run_shell_command"
        commandPrefix = [
          "sudo rm",
          "rm -rf /",
          "rm -rf ~",
          "rm -rf ~/",
          "dd ",
          "mkfs ",
          "shutdown",
          "reboot"
        ]
        decision = "deny"
        priority = 300
        deny_message = "Blocked by Gemini CLI safety policy."
      '';
    };

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

        experimental = {
          plan = true;
          taskTracker = true;
          modelSteering = true;
          toolOutputMasking = {
            enabled = true;
            protectLatestTurn = true;
          };
        };

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
          plan = {
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
          autoAccept = false;
          shell.showColor = true;
          useRipgrep = true;
          truncateToolOutputThreshold = 50000;
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
          showMemoryUsage = true;
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
    };
  };
}
