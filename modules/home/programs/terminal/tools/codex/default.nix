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
  mcpModuleEnabled = config.khanelinix.programs.terminal.tools.mcp.enable or false;
  exoEnabled = config.services.exo.enable or false;
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
  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib pkgs; };
  tomlFormat = pkgs.formats.toml { };
  codexConfigDir =
    if config.home.preferXdgDirectories then
      "${lib.removePrefix config.home.homeDirectory config.xdg.configHome}/codex"
    else
      ".codex";
  codexConfigPath =
    if config.home.preferXdgDirectories then
      "${config.xdg.configHome}/codex"
    else
      "${config.home.homeDirectory}/.codex";
  disabledSystemSkillConfig = map (name: {
    path = "${codexConfigPath}/skills/.system/${name}/SKILL.md";
    enabled = false;
  }) aiTools.codex.disabledSystemSkills;
  codexCommandSkillNames = builtins.attrNames aiTools.codex.commandSkillFiles;
  codexAgentFiles = lib.mapAttrs' (
    name: agentSettings:
    lib.nameValuePair "${codexConfigDir}/agents/${name}.toml" {
      source = tomlFormat.generate "codex-agent-${name}" agentSettings;
    }
  ) aiTools.codex.agents;
  codexCommandSkillDirs = lib.mapAttrs (
    name: commandFiles:
    pkgs.runCommandLocal "codex-command-skill-${name}" { } (
      lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          relativePath: fileText:
          let
            file = builtins.toFile "codex-command-${name}-${lib.replaceStrings [ "/" ] [ "-" ] relativePath}" fileText;
          in
          ''
            install -Dm0644 ${file} "$out/${relativePath}"
          ''
        ) commandFiles
      )
    )
  ) aiTools.codex.commandSkillFiles;
  codexSkills = aiTools.codex.skillSources // codexCommandSkillDirs;
  codexCommandSkillCleanup = lib.concatMapStringsSep "\n" (
    name:
    let
      target = "${codexConfigPath}/skills/${name}";
    in
    ''
      if [ -d ${lib.escapeShellArg target} ] && [ ! -L ${lib.escapeShellArg target} ]; then
        [ ! -L ${lib.escapeShellArg "${target}/SKILL.md"} ] || rm -f ${lib.escapeShellArg "${target}/SKILL.md"}
        [ ! -L ${lib.escapeShellArg "${target}/agents/openai.yaml"} ] || rm -f ${lib.escapeShellArg "${target}/agents/openai.yaml"}
        rmdir ${lib.escapeShellArg "${target}/agents"} 2>/dev/null || true
        rmdir ${lib.escapeShellArg target} 2>/dev/null || true
      fi
    ''
  ) codexCommandSkillNames;
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
      model = "gpt-5.4-mini";
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
    home = {
      # Codex plugin caches are mutable content downloaded at runtime, so
      # patching them cannot be declared; re-patch on every switch instead.
      # Non-fatal so a fresh machine (no plugin cache yet) or an unsupported
      # codex bump does not block activation. The native-messaging manifest and
      # node_repl MCP server are managed declaratively below, so the installer's
      # manifest writes are redirected to a scratch root it may own.
      activation = {
        codexCommandSkillShape = lib.hm.dag.entryBefore [ "checkLinkTargets" ] codexCommandSkillCleanup;
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        codexBrowserUseInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${lib.getExe pkgs.khanelinix.codex-browser-use-linux-chromium} install \
            --codex-home ${codexConfigPath} \
            --browser-config-root ${config.xdg.stateHome}/codex-browser-use-linux-chromium \
            --skip-feature-config \
            --patch-chromium-extension \
            || verboseEcho "codex-browser-use-linux-chromium install failed (non-fatal); run codex-browser-doctor"
        '';
      };
      file = codexAgentFiles;
      packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.khanelinix.codex-browser-use-linux-chromium
      ];
      shellAliases = {
        codex-deep = "codex --profile deep";
        codex-long = "codex --profile long -c model_context_window=1000000 -c model_auto_compact_token_limit=850000";
        codex-nano = "codex --profile nano";
        codex-offline = "codex --profile offline";
        codex-quick = "codex --profile quick";
        codex-spark = "codex --profile spark";
        codex-unsafe = "codex --profile unsafe --dangerously-bypass-hook-trust";
      }
      // lib.optionalAttrs exoEnabled {
        codex-exo = ''f(){ model="$1"; shift; codex -c model_provider='"exo"' -m "$model" "$@"; }; f'';
        codex-exo-coder = ''codex -c model_provider='"exo"' -m mlx-community/Qwen3-Coder-Next-4bit'';
        codex-exo-gpt-oss = ''codex -c model_provider='"exo"' -m mlx-community/gpt-oss-20b-MXFP4-Q8'';
        codex-exo-qwen = ''codex -c model_provider='"exo"' -m mlx-community/Qwen3.6-35B-A3B-5bit'';
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
      profiles = codexProfiles;

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
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          # Required by codex-browser-use-linux-chromium (codex >= 0.133) so
          # plugin MCP servers are discovered instead of deferred.
          tool_search_always_defer_mcp_tools = false;
        };

        agents = {
          max_threads = 12;
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
        model_reasoning_effort = "high";
        plan_mode_reasoning_effort = "high";
        # service_tier = "fast"; # Not preferred by default for now; use /fast on when needed.

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

        skills = lib.optionalAttrs (disabledSystemSkillConfig != [ ]) {
          config = disabledSystemSkillConfig;
        };

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
            githubRoot =
              if pkgs.stdenv.hostPlatform.isLinux then
                "${documentsPath}/github"
              else
                "${config.home.homeDirectory}/github";

            trustedGithubProjects = [
              "home-manager"
              "khanelivim"
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
      hooks = aiTools.planningWithFiles.codex.hooks;
    };
  };
}
