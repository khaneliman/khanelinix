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

  cfg = config.khanelinix.programs.terminal.tools.codex;
  exoEnabled = config.services.exo.enable or false;
  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib pkgs; };
  tomlFormat = pkgs.formats.toml { };
  codexConfigDir =
    if config.home.preferXdgDirectories then
      "${lib.removePrefix config.home.homeDirectory config.xdg.configHome}/codex"
    else
      ".codex";
  codexProfiles = {
    # Deep analysis and live-research mode. Intentionally expensive:
    # benchmark preference is GPT-5.5 xhigh for best pass rate.
    deep = {
      model = "gpt-5.5";
      model_reasoning_effort = "xhigh";
      model_verbosity = "high";
      plan_mode_reasoning_effort = "xhigh";
      web_search = "live";
    };

    # Large-context escape hatch. The alias passes context overrides directly
    # via CLI -c because those fields are top-level settings in the published
    # schema.
    long = {
      model = "gpt-5.4";
      model_reasoning_effort = "xhigh";
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
in
{
  options.khanelinix.programs.terminal.tools.codex = {
    enable = mkEnableOption "Codex configuration";
  };

  config = mkIf cfg.enable {
    home.shellAliases = {
      codex-deep = "codex --profile deep";
      codex-long = "codex --profile long -c model_context_window=1000000 -c model_auto_compact_token_limit=850000";
      codex-nano = "codex --profile nano";
      codex-offline = "codex --profile offline";
      codex-quick = "codex --profile quick";
      codex-spark = "codex --profile spark";
      codex-unsafe = "codex --profile unsafe";
    }
    // lib.optionalAttrs exoEnabled {
      codex-exo = ''f(){ model="$1"; shift; codex -c model_provider='"exo"' -m "$model" "$@"; }; f'';
      codex-exo-coder = ''codex -c model_provider='"exo"' -m mlx-community/Qwen3-Coder-Next-4bit'';
      codex-exo-gpt-oss = ''codex -c model_provider='"exo"' -m mlx-community/gpt-oss-20b-MXFP4-Q8'';
      codex-exo-qwen = ''codex -c model_provider='"exo"' -m mlx-community/Qwen3.6-35B-A3B-5bit'';
    };

    home.file = lib.mapAttrs' (
      name: profileSettings:
      lib.nameValuePair "${codexConfigDir}/${name}.config.toml" {
        source = tomlFormat.generate "codex-${name}-config" profileSettings;
      }
    ) codexProfiles;

    programs.codex = {
      enable = true;
      enableMcpIntegration = true;

      # https://developers.openai.com/codex/config-schema.json
      settings = {
        features = {
          apps = true;
          browser_use = true;
          browser_use_external = true;
          computer_use = true;
          enable_request_compression = true;
          fast_mode = true;
          goals = true;
          guardian_approval = true;
          hooks = true;
          image_generation = true;
          in_app_browser = true;
          multi_agent = true;
          personality = true;
          plugin_sharing = true;
          plugins = true;
          prevent_idle_sleep = true;
          shell_snapshot = true;
          shell_tool = true;
          skill_mcp_dependency_install = true;
          terminal_resize_reflow = true;
          tool_call_mcp_elicitation = true;
          tool_suggest = true;
          unified_exec = true;
          workspace_dependencies = true;
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

        notice.hide_rate_limit_model_nudge = true;

        # DeepSWE favors GPT-5.5 high/xhigh enough to justify high as the
        # routine default; xhigh stays reserved for explicit deep runs.
        model = "gpt-5.5";
        model_auto_compact_token_limit = 240000;
        model_context_window = 272000;
        model_reasoning_effort = "high";
        plan_mode_reasoning_effort = "high";
        # service_tier = "fast"; # Not preferred by default for now; use /fast on when needed.

        model_providers = lib.optionalAttrs exoEnabled {
          exo = {
            name = "exo (local cluster)";
            base_url = "http://localhost:52415/v1";
            wire_api = "responses";
            requires_openai_auth = false;
            request_max_retries = 1;
            stream_max_retries = 1;
            stream_idle_timeout_ms = 300000;
          };
        };

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

                cwd="$(printf '%s' "$payload" | jq -r '.cwd // .workspace.current_dir // empty')"
                if [ -z "$cwd" ]; then
                  cwd="$PWD"
                fi
                dirName="''${cwd##*/}"

                message="$(printf '%s' "$payload" | jq -r '.["last-assistant-message"] // "Turn complete"')"
                summary="''${message:0:180}"

                if [ -n "$dirName" ] && [ "$dirName" != "$cwd" ]; then
                  summary="[$dirName] $summary"
                elif [ -n "$cwd" ]; then
                  summary="[$cwd] $summary"
                fi

                if [ -n "$cwd" ]; then
                  printf '\nCodex awaiting input: %s\n' "$cwd" > /dev/tty 2>/dev/null || true
                else
                  printf '\nCodex awaiting input\n' > /dev/tty 2>/dev/null || true
                fi

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
      inherit (aiTools.codex) skills;
      rules = import ./rules.nix;
    };
  };
}
