{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;

  cfg = config.khanelinix.programs.terminal.tools.codex;
  mcpModuleEnabled = config.khanelinix.programs.terminal.tools.mcp.enable or false;
  exoEnabled = config.services.exo.enable or false;

  swapCfg = osConfig.khanelinix.services.llm.llamaSwap or { };
  swapEnabled = swapCfg.enable or false;

  # The proxy publishes its base URL, so a host or port change needs no edit
  # here. The literal only guards an evaluation without this system's config.
  swapEndpoint = swapCfg.endpoint or "http://127.0.0.1:8090/v1";

  # codex speaks only the responses API. llama.cpp serves it through the proxy;
  # colibri does not, exposing chat completions, completions, and messages.
  swapModels = lib.attrNames (
    lib.filterAttrs (_: model: model.backend == "llama-cpp") (swapCfg.models or { })
  );
  # `programs.codex.settings.mcp_servers` is merged with the auto-generated
  # entries from `programs.mcp.servers` per top-level server name (whole-entry
  # override, not a deep per-field merge), so any entry listed here would
  # otherwise drop its `command`/`args`/`env` transport. Replicate the same
  # transform home-manager's codex module applies so policy overrides keep
  # their transport intact.
  codexMcpTransport = lib.mapAttrs (
    name: server:
    lib.hm.mcp.transformMcpServer {
      inherit server;
      exclude = [
        "headers"
        "type"
      ];
      extraTransforms = [
        (s: s // lib.optionalAttrs (s.headers or { } != { }) { http_headers = s.headers; })
        lib.hm.mcp.addType
        (lib.hm.mcp.wrapEnvFilesCommand { inherit pkgs name; })
      ];
    }
  ) config.programs.mcp.servers;
  aiTools = import (lib.getFile "modules/common/ai-tools") {
    gatewayEnabled = config.khanelinix.services.cliproxyapi.enable or false;
    inherit lib pkgs;
  };
  tomlFormat = pkgs.formats.toml { };
  codexConfigPath =
    if config.home.preferXdgDirectories then
      "${config.xdg.configHome}/codex"
    else
      "${config.home.homeDirectory}/.codex";
  codexPackage =
    if pkgs.stdenv.hostPlatform.isDarwin && config.home.preferXdgDirectories then
      pkgs.symlinkJoin {
        name = pkgs.codex.name;
        paths = [ pkgs.codex ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/codex" \
            --set-default CODEX_HOME ${lib.escapeShellArg codexConfigPath}
        '';
        meta = pkgs.codex.meta;
      }
    else
      pkgs.codex;
  codexRepairMessageIds = pkgs.writeShellApplication {
    name = "codex-repair-message-ids";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      jq
      lsof
    ];
    text = ''
      codex_home_default=${lib.escapeShellArg codexConfigPath}
      ${builtins.readFile ./repair-message-ids.sh}
    '';
  };
  disabledSystemSkillConfig = map (name: {
    path = "${codexConfigPath}/skills/.system/${name}/SKILL.md";
    enabled = false;
  }) aiTools.codex.disabledSystemSkills;
  codexAgentSources = lib.mapAttrs (
    name: agentSettings: tomlFormat.generate "codex-agent-${name}" agentSettings
  ) aiTools.codex.agents;
  codexAgentSettingNames = [
    "default_subagent_model"
    "default_subagent_reasoning_effort"
    "enabled"
    "interrupt_message"
    "max_concurrent_threads_per_session"
    "max_depth"
  ];
  codexAgentRoleNameCollisions = lib.intersectLists codexAgentSettingNames (
    lib.attrNames aiTools.codex.agents
  );
  # Codex rejects symlinked role files. Point role declarations at regular Nix
  # store files instead of copying them into the mutable Codex home.
  codexAgentRoles =
    assert lib.assertMsg (codexAgentRoleNameCollisions == [ ])
      "Codex agent role names collide with agent settings: ${lib.concatStringsSep ", " codexAgentRoleNameCollisions}";
    lib.mapAttrs (name: _: {
      config_file = codexAgentSources.${name};
    }) aiTools.codex.agents;
  codexSkills = aiTools.codex.skillSources;
  codexProfiles = {
    # Deep analysis and live-research mode. Intentionally expensive.
    deep = {
      model = "gpt-6-astra";
      model_reasoning_effort = "xhigh";
      model_verbosity = "high";
      plan_mode_reasoning_effort = "xhigh";
      web_search = "live";
    };

    # Large-context escape hatch. The alias passes context overrides directly
    # via CLI -c because those fields are top-level settings in the published
    # schema.
    long = {
      model = "gpt-6-astra";
      model_reasoning_effort = "xhigh";
      model_verbosity = "high";
      plan_mode_reasoning_effort = "xhigh";
      web_search = "live";
    };

    # Faster implementation loop for routine coding tasks.
    quick = {
      model_reasoning_effort = "medium";
      model = "gpt-5.6-luna";
      model_reasoning_summary = "none";
      model_verbosity = "low";
      plan_mode_reasoning_effort = "medium";
      service_tier = "priority";
      web_search = "disabled";
    };

    # Trivial latency-first profile for obvious, low-risk work.
    spark = {
      model = "gpt-5.3-codex-spark";
      model_reasoning_effort = "medium";
      model_verbosity = "medium";
      plan_mode_reasoning_effort = "high";
      service_tier = "priority";
      web_search = "disabled";
    };

    # Force local-only behavior when you do not want network access.
    offline = {
      sandbox_mode = "workspace-write";
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
    home = {
      # Codex plugin caches are mutable content downloaded at runtime, so
      # patching them cannot be declared; re-patch on every switch instead.
      # Non-fatal so a fresh machine (no plugin cache yet) or an unsupported
      # codex bump does not block activation. The native-messaging manifest and
      # node_repl MCP server are managed declaratively below, so the installer's
      # manifest writes are redirected to a scratch root it may own.
      activation = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        codexBrowserUseInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${lib.getExe pkgs.khanelinix.codex-browser-use-linux-chromium} install \
            --codex-home ${codexConfigPath} \
            --browser-config-root ${config.xdg.stateHome}/codex-browser-use-linux-chromium \
            --skip-feature-config \
            --patch-chromium-extension \
          || verboseEcho "codex-browser-use-linux-chromium install failed (non-fatal); run codex-browser-doctor"
        '';
      };
      packages = [
        codexRepairMessageIds
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.khanelinix.codex-browser-use-linux-chromium
      ];
      shellAliases = {
        codex-deep = "codex --strict-config --profile deep";
        codex-doctor = "codex doctor --summary";
        codex-long = "codex --strict-config --profile long -c model_context_window=1000000 -c model_auto_compact_token_limit=850000";
        codex-offline = "codex --strict-config --profile offline";
        codex-quick = "codex --strict-config --profile quick";
        codex-spark = "codex --strict-config --profile spark";
        codex-unsafe = "codex --strict-config --profile unsafe --dangerously-bypass-hook-trust";
      }
      // lib.optionalAttrs swapEnabled (
        {
          codex-local = ''f(){ model="$1"; shift; codex --strict-config -c model_provider='"llama-swap"' -m "$model" "$@"; }; f'';
        }
        # One alias per served model, so the set follows the service rather than
        # a list repeated here.
        // lib.listToAttrs (
          map (model: {
            name = "codex-local-${model}";
            value = ''codex --strict-config -c model_provider='"llama-swap"' -m ${model}'';
          }) swapModels
        )
      )
      // lib.optionalAttrs exoEnabled {
        codex-exo = ''f(){ model="$1"; shift; codex --strict-config -c model_provider='"exo"' -m "$model" "$@"; }; f'';
        codex-exo-coder = ''codex --strict-config -c model_provider='"exo"' -m mlx-community/Qwen3-Coder-Next-4bit'';
        codex-exo-gpt-oss = ''codex --strict-config -c model_provider='"exo"' -m mlx-community/gpt-oss-20b-MXFP4-Q8'';
        codex-exo-qwen = ''codex --strict-config -c model_provider='"exo"' -m mlx-community/Qwen3.6-35B-A3B-5bit'';
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        codex-browser-doctor = "codex-browser-use-linux-chromium doctor --codex-home ${codexConfigPath}";
      };
    };

    # Official Codex Chrome extension, required by the browser-use bridge.
    programs.chromium.extensions =
      lib.mkIf
        (pkgs.stdenv.hostPlatform.isLinux && config.khanelinix.programs.graphical.browsers.chromium.enable)
        [
          { id = "hehggadaopoacecdllhhajmbjkdcmajg"; }
        ];

    # Native-messaging manifest wiring the Codex extension to the bridge.
    # force: replaces the manifest earlier installer runs wrote imperatively.
    xdg.configFile."chromium/NativeMessagingHosts/com.openai.codexextension.json" =
      lib.mkIf
        (pkgs.stdenv.hostPlatform.isLinux && config.khanelinix.programs.graphical.browsers.chromium.enable)
        {
          force = true;
          text = builtins.toJSON {
            name = "com.openai.codexextension";
            description = "Codex Browser Use Linux Chromium native host bridge";
            path = lib.getExe' pkgs.khanelinix.codex-browser-use-linux-chromium "codex-native-host-bridge";
            type = "stdio";
            allowed_origins = [ "chrome-extension://hehggadaopoacecdllhhajmbjkdcmajg/" ];
          };
        };

    programs.codex = {
      enable = true;
      enableMcpIntegration = mkIf mcpModuleEnabled true;
      package = codexPackage;
      profiles = codexProfiles;

      # https://developers.openai.com/codex/config-schema.json
      settings = {
        apps._default.default_tools_approval_mode = "writes";

        # Nix rebuilds change the ad-hoc Mach-O CDHash. Keychain then treats
        # Codex as a new executable and asks for the login password again.
        # Codex does not migrate Keychain credentials into file storage.
        cli_auth_credentials_store = if pkgs.stdenv.hostPlatform.isDarwin then "file" else "auto";
        mcp_oauth_credentials_store = if pkgs.stdenv.hostPlatform.isDarwin then "file" else "auto";

        features = {
          memories = !aiTools.codex.okfMemoryEnabled;
          multi_agent = true;
          multi_agent_v2 = false;
          prevent_idle_sleep = true;
        };

        agents = {
          max_concurrent_threads_per_session = 12;
        }
        // codexAgentRoles;

        history = {
          max_bytes = 104857600;

          # Matches the upstream default; codex-acp embeds an older core that
          # refuses to load a config without the key. Editor plugins reach
          # codex through that bridge.
          persistence = "save-all";
        };

        memories = lib.optionalAttrs aiTools.codex.okfMemoryEnabled {
          generate_memories = false;
          use_memories = false;
        };

        notice.hide_rate_limit_model_nudge = true;

        # Keep expensive parent reasoning separate from Luna/Spark worker routes.
        # No service_tier: Astra is costly enough on the default tier.
        model = "gpt-6-astra";
        model_reasoning_effort = "high";
        plan_mode_reasoning_effort = "high";
        web_search = "live";

        # Browser-side counterpart lives in the chromium native-messaging
        # manifest; together they let codex drive Chromium without the
        # imperative --write-codex-config step.
        mcp_servers =
          lib.optionalAttrs mcpModuleEnabled (
            lib.mapAttrs (
              name: policy: (codexMcpTransport.${name} or { }) // policy
            ) aiTools.permissions.codexMcpServerPolicies
          )
          // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
            node_repl = {
              command = lib.getExe' pkgs.khanelinix.codex-browser-use-linux-chromium "codex-node-repl-mcp";
              # js/js_reset/browser_cleanup drive the local Chromium bridge;
              # prompting per call makes browser use unusable.
              default_tools_approval_mode = "approve";
            };
          };

        model_providers =
          lib.optionalAttrs swapEnabled {
            llama-swap = {
              name = "Local (llama-swap)";
              base_url = swapEndpoint;
              # codex dropped the chat wire API, and llama.cpp answers
              # /v1/responses through the proxy.
              wire_api = "responses";
              requires_openai_auth = false;
              request_max_retries = 1;
              stream_max_retries = 1;
              # A streamed expert container answers slowly, and colibri warms its
              # experts before the first token.
              stream_idle_timeout_ms = 600000;
            };
          }
          // lib.optionalAttrs exoEnabled {
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

                message="$(printf '%s' "$payload" | jq -r '.["last-assistant-message"] // empty')"
                if [ -z "$message" ]; then
                  message="Turn complete"
                fi
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
                  ${lib.getExe pkgs.terminal-notifier} -title "Codex" -message "$summary" -group "codex-turn" -sender "com.openai.codex" >/dev/null 2>&1 || \
                  ${lib.getExe pkgs.terminal-notifier} -title "Codex" -message "$summary" -group "codex-turn" >/dev/null 2>&1
                ''}
                ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
                  ${lib.getExe pkgs.libnotify}/bin/notify-send "Codex" "$summary" >/dev/null 2>&1
                ''}
              '';
            };
          in
          [ (lib.getExe codexNotify) ];

        personality = "none";

        project_root_markers = [
          ".git"
          ".jj"
          ".hg"
          ".sl"
        ];

        approval_policy = "on-request";
        sandbox_mode = "danger-full-access";

        skills = lib.optionalAttrs (disabledSystemSkillConfig != [ ]) {
          config = disabledSystemSkillConfig;
        };

        tui = {
          status_line = [
            "model-with-reasoning"
            "current-dir"
            "git-branch"
            "context-remaining"
            "context-used"
            "five-hour-limit"
          ];
          terminal_title = [
            "activity"
            "project-name"
            "git-branch"
          ];
        };

        projects =
          let
            documentsPath =
              if config.xdg.userDirs.enable then
                config.xdg.userDirs.documents
              else
                config.home.homeDirectory + lib.optionalString pkgs.stdenv.hostPlatform.isLinux "/Documents";
            githubRoot =
              if pkgs.stdenv.hostPlatform.isLinux then
                "${documentsPath}/github"
              else
                "${config.home.homeDirectory}/github";

            trustedGithubProjects = [
              "home-manager"
              "khanelivim"
              "midnight-scavenger"
              "nixpkgs"
              "nixvim"
              "Austin-Horstman"
              "neotest-nix"
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
              name = "${githubRoot}/${project}";
              value = {
                trust_level = "trusted";
              };
            }) trustedGithubProjects
          );
      };

      context = builtins.readFile aiTools.base;
      contextOverride = aiTools.codex.contextOverride;
      skills = codexSkills;
      rules = import ./rules.nix { inherit lib; };
    };
  };
}
