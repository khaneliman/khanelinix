{ lib }:
{
  generateAgentConfig =
    name:
    let
      # Extract task type (last part after last dash)
      parts = lib.splitString "-" name;
      task = lib.last parts;
      specialty = lib.concatStringsSep "-" (lib.init parts);

      # Primary agents: most commonly used, Tab-switchable
      primaryAgents = [
        "nix-coder"
        "code-reviewer"
        "system-planner"
      ];

      # Model Constants
      models = {
        # The Reasoning King (Nov 2025)
        # Best for: Planning, Auditing, Complex Logic
        # Cost: $2.00 / 1M Input
        gemini3 = "google/gemini-3-pro-preview";

        # The Syntax Specialist
        # Best for: Pure Code Generation, Strict Adherence
        # Cost: $3.00 / 1M Input
        claudeSonnet = "anthropic/claude-sonnet-4-5";

        # The Efficiency Workhorse
        # Best for: Reading logs, basic docs
        # Cost: $0.30 / 1M Input
        geminiFlash = "google/gemini-2.5-flash";

        # The Technical Writer
        # Best for: Documentation tone
        claudeHaiku = "anthropic/claude-haiku-4-5";
      };

      # Determine mode based on agent name
      mode = if builtins.elem name primaryAgents then "primary" else "subagent";

      # Task type configurations
      taskConfigs = {
        # Coders: Write code with full tools
        coder = {
          # Stick with Claude for that 77.2% SWE-bench edge.
          model = models.claudeSonnet;
          tools = {
            write = true;
            edit = true;
            bash = true;
          };
          permission = {
            edit = "ask";
            bash = "ask";
          };
        };

        # Reviewers: Analyze and review with git access
        reviewer = {
          # Claude excels at "Theory of Mind" (understanding intent).
          model = models.claudeSonnet;
          tools = {
            write = true;
            edit = true;
            bash = true;
          };
          permission = {
            edit = "ask";
            bash = {
              "git diff*" = "allow";
              "git log*" = "allow";
              "git status" = "allow";
              "*" = "ask";
            };
          };
        };

        # Planners: Read and plan, minimal modifications
        planner = {
          # Massive win on Vending-Bench (Agentic Planning).
          # 1M context lets it hold the whole system closure in head.
          model = models.gemini3;
          tools = {
            write = false;
            edit = false;
            bash = true;
          };
          permission = {
            edit = "deny";
            bash = "ask";
          };
        };

        # Analyzers: Deep analysis, read-only (Claude: thorough analysis)
        analyzer = {
          model = models.claudeSonnet;
          tools = {
            write = false;
            edit = false;
            bash = true;
          };
          permission = {
            edit = "deny";
            bash = "ask";
          };
        };

        # Writers: Documentation and content
        writer = {
          # Better technical tone than Gemini.
          model = models.claudeHaiku;
          tools = {
            write = true;
            edit = true;
            bash = false;
          };
          permission = {
            edit = "allow";
          };
        };

        # Auditors: Security and quality, read-only with limited bash (Claude: careful analysis)
        auditor = {
          # HLE Score (37.5%) crushes Claude (13.7%) on deep reasoning.
          # Better at finding logical exploits.
          model = models.gemini3;
          tools = {
            write = false;
            edit = false;
            bash = true;
          };
          permission = {
            edit = "deny";
            bash = {
              "grep*" = "allow";
              "rg*" = "allow";
              "find*" = "allow";
              "git diff*" = "allow";
              "git log*" = "allow";
              "*" = "ask";
            };
          };
        };
      };

      baseConfig = taskConfigs.${task} or taskConfigs.coder;

      # Specialty-specific overrides
      specialtyOverrides =
        if lib.hasInfix "flake" specialty then
          {
            permission = {
              edit = "ask";
              bash = {
                "nix flake*" = "allow";
                "nix build*" = "allow";
                "nix eval*" = "allow";
                "*" = "ask";
              };
            };
          }
        else if lib.hasInfix "system" specialty then
          {
            permission = {
              edit = "ask";
              bash = {
                "systemctl*" = "ask";
                "nixos-rebuild*" = "ask";
                "*" = "ask";
              };
            };
          }
        else if specialty == "nix" && task == "coder" then
          {
            tools = {
              write = true;
              edit = true;
              bash = false;
            };
            permission = {
              edit = "ask";
            };
          }
        else
          { };

    in
    {
      inherit mode;
    }
    // baseConfig
    // specialtyOverrides;
}
