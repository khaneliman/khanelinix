{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.opencode;
  opencodeSkills = config.programs.opencode.skills or null;

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
        debuggerModel = aiTools.agents.debugger.model.opencode;
        refactorerModel = aiTools.agents.refactorer.model.opencode;
        testRunnerModel = aiTools.agents.test-runner.model.opencode;
        quickModel = "openai/gpt-5.3-codex-spark";
        nanoModel = "openai/gpt-5.4-nano";

        deliberateFallbackModels = [
          {
            model = "openai/gpt-5.3-codex";
            reasoningEffort = "high";
          }
          testRunnerModel
        ];

        fastFallbackModels = [
          quickModel
          nanoModel
        ];

        defaultConfig = {
          skills = lib.optionalAttrs (opencodeSkills != null) {
            sources = [
              {
                path = toString aiTools.skillsDir;
                recursive = true;
              }
            ];
          };

          "$schema" =
            "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json";

          agents = {
            sisyphus = {
              model = refactorerModel;
              fallback_models = deliberateFallbackModels;
              prompt_append = "Follow the repository engineering rules already provided through the shared OpenCode context. Prefer the shared commands and skills before inventing new workflows.";
            };
            oracle = {
              model = debuggerModel;
              fallback_models = deliberateFallbackModels;
            };
            explore = {
              model = testRunnerModel;
              fallback_models = fastFallbackModels;
            };
            librarian = {
              model = testRunnerModel;
              fallback_models = fastFallbackModels;
            };
          };

          categories = {
            quick = {
              model = quickModel;
              fallback_models = [
                nanoModel
                testRunnerModel
              ];
              description = "Fast, minimal edits and low-surface changes.";
            };
            deep = {
              model = debuggerModel;
              fallback_models = deliberateFallbackModels;
              description = "Debugging, diagnosis, and deliberate investigation.";
            };
            unspecified-high = {
              model = refactorerModel;
              fallback_models = deliberateFallbackModels;
              description = "General engineering work that benefits from stronger reasoning.";
            };
            unspecified-low = {
              model = testRunnerModel;
              fallback_models = fastFallbackModels;
              description = "Cheaper general subtasks and verification work.";
            };
            writing = {
              model = testRunnerModel;
              fallback_models = [
                quickModel
                nanoModel
              ];
              description = "Documentation and prose-heavy tasks.";
            };
          };

          # Prefer the repository's local skill implementations for browser, git,
          # and UI workflows to avoid duplicate instructions from OmO built-ins.
          disabled_skills = [
            "frontend-ui-ux"
            "git-master"
            "playwright"
            "playwright-cli"
          ];

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

          git_master = {
            commit_footer = false;
            include_co_authored_by = false;
          };

          runtime_fallback = true;

          model_capabilities = {
            enabled = true;
            auto_refresh_on_start = true;
            refresh_timeout_ms = 5000;
          };

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
