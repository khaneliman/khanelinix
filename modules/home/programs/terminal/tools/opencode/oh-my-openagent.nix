{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.opencode;

  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib; };

  json = pkgs.formats.json { };
in
{
  options.khanelinix.programs.terminal.tools.opencode.ohMyOpenAgent.settings = lib.mkOption {
    inherit (json) type;
    default = { };
    description = ''
      Raw Oh My OpenAgent configuration written to
      {file}`$XDG_CONFIG_HOME/opencode/oh-my-openagent.json`.

      This is separate from {option}`programs.opencode.settings`, which configures
      OpenCode itself. Shared defaults seed OmO from `modules/common/ai-tools`,
      and this option recursively overrides them.
    '';
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."opencode/oh-my-openagent.json".source =
      let
        defaultConfig = {
          "$schema" =
            "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json";

          agents = {
            sisyphus = {
              model = aiTools.agents.refactorer.model.opencode;
              prompt_append = "Follow the repository engineering rules already provided through the shared OpenCode context. Prefer the shared commands and skills before inventing new workflows.";
            };
            oracle.model = aiTools.agents.debugger.model.opencode;
            explore.model = aiTools.agents.test-runner.model.opencode;
            librarian.model = aiTools.agents.test-runner.model.opencode;
          };

          categories = {
            quick = {
              model = "openai/gpt-5.3-codex-spark";
              description = "Fast, minimal edits and low-surface changes.";
            };
            deep = {
              model = aiTools.agents.debugger.model.opencode;
              description = "Debugging, diagnosis, and deliberate investigation.";
            };
            unspecified-high = {
              model = aiTools.agents.refactorer.model.opencode;
              description = "General engineering work that benefits from stronger reasoning.";
            };
            unspecified-low = {
              model = aiTools.agents.test-runner.model.opencode;
              description = "Cheaper general subtasks and verification work.";
            };
            writing = {
              model = aiTools.agents.test-runner.model.opencode;
              description = "Documentation and prose-heavy tasks.";
            };
          };

          background_task = {
            providerConcurrency = {
              openai = 3;
              github-copilot = 8;
            };
            modelConcurrency = {
              "openai/gpt-5.4" = 2;
              "github-copilot/gpt-5-mini" = 12;
            };
          };

          runtime_fallback = true;

          model_capabilities = {
            enabled = true;
            auto_refresh_on_start = true;
            refresh_timeout_ms = 5000;
          };

          skills.sources = [
            {
              path = toString aiTools.skillsDir;
              recursive = true;
            }
          ];

          experimental = {
            task_system = true;
            dynamic_context_pruning = {
              enabled = true;
              notification = "minimal";
              turn_protection = {
                enabled = true;
                turns = 3;
              };
            };
          };
        };
      in
      json.generate "oh-my-openagent.json" (lib.recursiveUpdate defaultConfig cfg.ohMyOpenAgent.settings);
  };
}
