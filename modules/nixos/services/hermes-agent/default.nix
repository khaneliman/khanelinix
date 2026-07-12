{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.services.hermes-agent;
  inherit (cfg) stateDir;
  workingDirectory = "${stateDir}/workspace";
in
{
  imports = lib.optional (
    inputs ? hermes-agent
    && inputs.hermes-agent ? nixosModules
    && inputs.hermes-agent.nixosModules ? default
  ) inputs.hermes-agent.nixosModules.default;

  options.khanelinix.services.hermes-agent = {
    enable = lib.mkEnableOption "Hermes agent";

    environmentFiles = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.path lib.types.str);
      default = [ ];
      description = "Files sourced into Hermes service environment.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/hermes";
      description = "Hermes state directory.";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Hermes YAML config settings.";
    };

    enableDefaultMcpServers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable low-friction filesystem and sequential-thinking MCP servers.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.hermes-agent = {
      enable = true;
      addToSystemPackages = true;
      restart = "always";
      restartSec = 5;
      inherit stateDir workingDirectory;

      environmentFiles = map toString cfg.environmentFiles;

      settings =
        let
          auxiliaryModel = "gpt-5.3-codex-spark";
        in
        lib.recursiveUpdate {
          model = {
            provider = "openai-codex";
            default = "gpt-5.6-sol";
          };

          fallback_providers = [
            {
              provider = "openai-codex";
              model = "gpt-5.3-codex-spark";
            }
            {
              provider = "gemini";
              model = "gemini-3.5-flash";
            }
            {
              provider = "gemini";
              model = "gemini-3.1-pro-preview";
            }
          ];

          toolsets = [ "all" ];

          discord = {
            require_mention = true;
            thread_require_mention = true;
            auto_thread = true;
            reactions = true;
            reply_to_mode = "first";
          };

          group_sessions_per_user = true;

          agent = {
            max_turns = 90;
            gateway_timeout = 3600;
            gateway_timeout_warning = 900;
            gateway_notify_interval = 180;
            reasoning_effort = "medium";
            tool_use_enforcement = [
              "gpt"
              "codex"
              "claude"
              "gemini"
              "qwen"
            ];
          };

          terminal = {
            backend = "local";
            cwd = workingDirectory;
            timeout = 300;
            persistent_shell = true;
          };

          compression = {
            enabled = true;
            threshold = 0.80;
            target_ratio = 0.25;
            protect_last_n = 24;
            abort_on_summary_failure = true;
          };

          auxiliary = {
            vision = {
              provider = "gemini";
              model = "gemini-3.5-flash";
              timeout = 120;
            };
            compression = {
              provider = "openai-codex";
              model = auxiliaryModel;
              timeout = 180;
            };
            approval = {
              provider = "openai-codex";
              model = auxiliaryModel;
            };
            mcp = {
              provider = "openai-codex";
              model = auxiliaryModel;
            };
            title_generation = {
              provider = "openai-codex";
              model = auxiliaryModel;
            };
            triage_specifier = {
              provider = "openai-codex";
              model = auxiliaryModel;
            };
          };

          delegation = {
            provider = "openai-codex";
            model = "gpt-5.3-codex-spark";
            reasoning_effort = "medium";
            max_iterations = 50;
            child_timeout_seconds = 900;
            max_concurrent_children = 3;
          };

          display = {
            compact = false;
            personality = "pragmatic";
            busy_input_mode = "steer";
            bell_on_complete = false;
            show_reasoning = false;
            streaming = false;
            timestamps = true;
            runtime_footer = {
              enabled = true;
              fields = [
                "model"
                "context_pct"
                "cwd"
              ];
            };
          };

          dashboard.show_token_analytics = false;

          memory = {
            memory_enabled = true;
            user_profile_enabled = true;
            memory_char_limit = 3000;
            user_char_limit = 1800;
          };

          tool_loop_guardrails = {
            warnings_enabled = true;
            hard_stop_enabled = true;
          };
        } cfg.settings;

      documents = {
        "AGENTS.md" = lib.mkDefault (lib.getFile "modules/common/ai-tools/base.md");
      };

      mcpServers = lib.optionalAttrs cfg.enableDefaultMcpServers {
        filesystem = {
          command = "npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-filesystem"
            workingDirectory
            stateDir
          ];
        };

        sequential-thinking = {
          command = "npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-sequential-thinking"
          ];
        };
      };

      extraPackages = [
        pkgs.bashInteractive
        pkgs.coreutils
        pkgs.curl
        pkgs.fd
        pkgs.git
        pkgs.gnumake
        pkgs.iproute2
        pkgs.jq
        pkgs.openssh
        (pkgs.nodejs_22 or pkgs.nodejs)
        pkgs.python312
        pkgs.ripgrep
        pkgs.tailscale
        pkgs.tmux
        pkgs.uv
      ];

      container = {
        backend = lib.mkDefault (
          if config.virtualisation.podman.enable or false then "podman" else "docker"
        );
        hostUsers = lib.mkDefault [ config.khanelinix.user.name ];
      };
    };
  };
}
