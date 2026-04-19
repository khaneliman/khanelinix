{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.programs.terminal.tools.codex;
  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib; };
in
{
  options.khanelinix.programs.terminal.tools.codex = {
    enable = mkEnableOption "Codex configuration";
  };

  config = mkIf cfg.enable {
    home.shellAliases = {
      codex-deep = "codex --profile deep";
      codex-nano = "codex --profile nano";
      codex-offline = "codex --profile offline";
      codex-quick = "codex --profile quick";
      codex-spark = "codex --profile spark";
      codex-unsafe = "codex --profile unsafe";
    };

    programs.codex = {
      enable = true;
      enableMcpIntegration = true;

      # https://developers.openai.com/codex/config-schema.json
      settings = {
        features = {
          apps = true;
          fast_mode = true;
          multi_agent = true;
          prevent_idle_sleep = true;
          shell_snapshot = true;
          skill_mcp_dependency_install = true;
          unified_exec = true;
          undo = true;
        };

        agents = {
          max_threads = 6;
          max_depth = 1;
          job_max_runtime_seconds = 3600;
        };

        history = {
          persistence = "save-all";
          max_bytes = 104857600;
        };

        model = "gpt-5.4";
        model_reasoning_effort = "medium";
        plan_mode_reasoning_effort = "high";
        service_tier = "fast";

        notify =
          let
            codexNotify = pkgs.writeShellApplication {
              name = "codex-notify";
              runtimeInputs = [
                pkgs.jq
              ]
              ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.libnotify ]
              ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.terminal-notifier ];
              text = ''
                payload="$1"
                eventType="$(printf '%s' "$payload" | jq -r '.type // ""')"
                [ "$eventType" = "agent-turn-complete" ] || exit 0

                message="$(printf '%s' "$payload" | jq -r '.["last-assistant-message"] // "Turn complete"')"
                summary="$(printf '%s' "$message" | cut -c1-180)"

                ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
                  ${lib.getExe pkgs.terminal-notifier} -title "Codex" -message "$summary" -group "codex-turn" >/dev/null 2>&1
                ''}
                ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
                  ${lib.getExe pkgs.libnotify}/bin/notify-send "Codex" "$summary" >/dev/null 2>&1
                ''}
              '';
            };
          in
          [ (lib.getExe codexNotify) ];

        personality = "pragmatic";

        project_root_markers = [
          ".git"
          ".jj"
          ".hg"
          ".sl"
        ];

        approval_policy = "on-request";
        sandbox_mode = "danger-full-access";

        tui = {
          status_line = [
            "model-with-reasoning"
            "current-dir"
            "context-remaining"
            "context-used"
            "five-hour-limit"
          ];
        };

        profiles = {
          # Deep analysis and live-research mode.
          deep = {
            model = "gpt-5.4";
            model_auto_compact_token_limit = 900000;
            model_context_window = 1050000;
            model_reasoning_effort = "high";
            model_verbosity = "high";
            plan_mode_reasoning_effort = "xhigh";
            web_search = "live";
          };

          # Cheapest local utility profile for triage and simple transforms.
          nano = {
            model = "gpt-5.4-nano";
            model_reasoning_effort = "none";
            model_verbosity = "low";
            plan_mode_reasoning_effort = "low";
            service_tier = "flex";
            web_search = "disabled";
          };

          # Faster implementation loop for coding tasks.
          quick = {
            model_reasoning_effort = "medium";
            model = "gpt-5.3-codex-spark";
            model_reasoning_summary = "none";
            model_verbosity = "low";
            plan_mode_reasoning_effort = "medium";
            service_tier = "fast";
            web_search = "disabled";
          };

          # High-effort coding profile for coding-first work.
          spark = {
            model = "gpt-5.3-codex-spark";
            model_reasoning_effort = "medium";
            model_verbosity = "medium";
            plan_mode_reasoning_effort = "high";
            service_tier = "fast";
            web_search = "disabled";
          };

          # Force local-only behavior when you do not want network access.
          offline = {
            sandbox_workspace_write.network_access = false;
            web_search = "disabled";
          };

          # Token-enabled profile for package updates and other API-heavy workflows.
          unsafe = {
            approval_policy = "on-request";
            sandbox_mode = "danger-full-access";
            shell_environment_policy.ignore_default_excludes = true;
          };
        };

        projects =
          let
            documentsPath =
              if config.xdg.userDirs.enable then
                config.xdg.userDirs.documents
              else
                config.home.homeDirectory + lib.optionalString pkgs.stdenv.hostPlatform.isLinux "/Documents";

            trustedGithubProjects = [
              "home-manager"
              "khanelivim"
              "nixpkgs"
              "nixvim"
              "waybar"
            ];
          in
          {
            "${config.home.homeDirectory}/khanelinix" = {
              trust_level = "trusted";
            };
          }
          // builtins.listToAttrs (
            map (project: {
              name = "${documentsPath}/github/${project}";
              value = {
                trust_level = "trusted";
              };
            }) trustedGithubProjects
          );
      };

      context = builtins.readFile aiTools.base;
      skills = aiTools.skillsDir;
      rules = import ./rules.nix;
    };
  };
}
