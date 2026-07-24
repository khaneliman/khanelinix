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
    mkOption
    types
    ;

  cfg = config.khanelinix.services.cliproxyapi;
  claudeCodeEnabled = config.khanelinix.programs.terminal.tools.claude-code.enable or false;
  codexEnabled = config.khanelinix.programs.terminal.tools.codex.enable or false;
  opencodeEnabled = config.khanelinix.programs.terminal.tools.opencode.enable or false;

  apiKey = "sk-cliproxyapi-local";
  baseUrl = "http://${cfg.host}:${toString cfg.port}";
  authDir = "${config.xdg.stateHome}/cliproxyapi/auth";
  configPath = "${config.xdg.configHome}/cliproxyapi/config.yaml";
  yamlFormat = pkgs.formats.yaml { };
  proxyConfig = yamlFormat.generate "cliproxyapi-config.yaml" {
    inherit (cfg) host;
    inherit (cfg) port;
    auth-dir = authDir;
    api-keys = [ apiKey ];
    remote-management = {
      allow-remote = false;
      secret-key = "";
      disable-control-panel = true;
    };
    logging-to-file = false;
    usage-statistics-enabled = false;
    ws-auth = true;
    oauth-excluded-models = cfg.oauthExcludedModels;
    oauth-model-alias = lib.mapAttrs (
      _: models:
      map (model: {
        name = model.model;
        inherit (model) alias;
        display-name = model.displayName;
      }) models
    ) (lib.groupBy (model: model.provider) cfg.claudeCodeModels);
  };

  proxyModel =
    provider: model:
    let
      mapping = lib.findFirst (
        candidate: candidate.provider == provider && candidate.model == model
      ) null cfg.claudeCodeModels;
    in
    if mapping == null then model else mapping.alias;

  claudeGatewayEnv = {
    ANTHROPIC_BASE_URL = baseUrl;
    ANTHROPIC_AUTH_TOKEN = apiKey;
    CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1";
    ENABLE_TOOL_SEARCH = "false";
  };

  claudeCommand =
    provider: model:
    lib.concatStringsSep " " (
      lib.mapAttrsToList (name: value: "${name}=${lib.escapeShellArg value}") claudeGatewayEnv
      ++ [
        "CLAUDE_CODE_ALWAYS_ENABLE_EFFORT=1"
        "CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY=3"
        "claude"
        "--model"
        (lib.escapeShellArg (proxyModel provider model))
      ]
    );

  codexCommand =
    provider: model:
    "codex --strict-config -c model_provider='\"cliproxyapi\"' -m ${lib.escapeShellArg (proxyModel provider model)}";

  loginCommand =
    provider: flag:
    pkgs.writeShellApplication {
      name = "cliproxyapi-${provider}-login";
      runtimeInputs = [ pkgs.coreutils ];
      text = ''
        mkdir -p ${lib.escapeShellArg authDir}
        exec ${lib.getExe cfg.package} \
          --config ${lib.escapeShellArg configPath} \
          ${flag} "$@"
      '';
    };
in
{
  options.khanelinix.services.cliproxyapi = {
    enable = mkEnableOption "CLIProxyAPI local AI provider proxy";

    package = mkOption {
      type = types.package;
      default = pkgs.khanelinix.cliproxyapi;
      defaultText = lib.literalExpression "pkgs.khanelinix.cliproxyapi";
      description = "CLIProxyAPI package to use.";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Local address on which CLIProxyAPI listens.";
    };

    port = mkOption {
      type = types.port;
      default = 8317;
      description = "Local port on which CLIProxyAPI listens.";
    };

    models = {
      claude = mkOption {
        type = types.str;
        default = "claude-fable-5";
        description = "Claude provider model used by harness aliases.";
      };

      codex = mkOption {
        type = types.str;
        default = "gpt-5.6-sol";
        description = "Codex provider model used by harness aliases.";
      };

      gemini = mkOption {
        type = types.str;
        default = "gemini-3.6-flash-high";
        description = "Gemini provider model used by harness aliases.";
      };
    };

    oauthExcludedModels = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = {
        antigravity = [
          "gemini-3-flash"
          "gemini-3-flash-agent"
          "gemini-3.1-flash-image"
          "gemini-3.1-flash-lite"
          "gemini-3.1-pro-low"
          "gemini-3.5-flash-extra-low"
          "gemini-3.5-flash-low"
        ];
        codex = [
          "codex-auto-review"
          "gpt-5.4"
          "gpt-5.4-mini"
          "gpt-5.5"
          "gpt-image-1.5"
          "gpt-image-2"
        ];
        claude = [
          "claude-3-5-haiku-20241022"
          "claude-3-7-sonnet-20250219"
          "claude-opus-4-20250514"
          "claude-opus-4-1-20250805"
          "claude-opus-4-5-20251101"
          "claude-opus-4-6"
          "claude-opus-4-7"
          "claude-sonnet-4-20250514"
          "claude-sonnet-4-5-20250929"
          "claude-sonnet-4-6"
        ];
      };
      description = ''
        OAuth provider models hidden from CLIProxyAPI clients. Lists use
        CLIProxyAPI's case-insensitive wildcard syntax and apply before model
        aliases.
      '';
    };

    claudeCodeModels = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            provider = mkOption {
              type = types.str;
              description = "CLIProxyAPI OAuth provider that owns the model.";
            };

            model = mkOption {
              type = types.str;
              description = "Upstream model ID routed by CLIProxyAPI.";
            };

            alias = mkOption {
              type = types.str;
              description = "Claude-prefixed model ID exposed to Claude Code.";
            };

            displayName = mkOption {
              type = types.str;
              description = "Human-readable model name exposed to gateway clients.";
            };
          };
        }
      );
      default = [
        {
          provider = "codex";
          model = "gpt-5.3-codex-spark";
          alias = "claude-gpt-5.3-codex-spark";
          displayName = "OpenAI · GPT 5.3 Codex Spark";
        }
        {
          provider = "codex";
          model = "gpt-5.6-sol";
          alias = "claude-gpt-5.6-sol";
          displayName = "OpenAI · GPT 5.6 Sol";
        }
        {
          provider = "codex";
          model = "gpt-5.6-terra";
          alias = "claude-gpt-5.6-terra";
          displayName = "OpenAI · GPT 5.6 Terra";
        }
        {
          provider = "codex";
          model = "gpt-5.6-luna";
          alias = "claude-gpt-5.6-luna";
          displayName = "OpenAI · GPT 5.6 Luna";
        }
        {
          provider = "antigravity";
          model = "gemini-3.6-flash-high";
          alias = "claude-gemini-3.6-flash";
          displayName = "Google · Gemini 3.6 Flash";
        }
        {
          provider = "antigravity";
          model = "gemini-pro-agent";
          alias = "claude-gemini-3.1-pro";
          displayName = "Google · Gemini 3.1 Pro";
        }
        {
          provider = "antigravity";
          model = "claude-sonnet-4-6";
          alias = "claude-antigravity-sonnet-4-6";
          displayName = "Google · Claude Sonnet 4.6";
        }
        {
          provider = "antigravity";
          model = "claude-opus-4-6-thinking";
          alias = "claude-antigravity-opus-4-6";
          displayName = "Google · Claude Opus 4.6";
        }
        {
          provider = "antigravity";
          model = "gpt-oss-120b-medium";
          alias = "claude-gpt-oss-120b";
          displayName = "Google · GPT-OSS 120B";
        }
      ];
      description = ''
        Models exposed additively to Claude Code through CLIProxyAPI gateway
        discovery. Aliases must start with `claude` or `anthropic` because
        Claude Code filters other gateway model IDs from its picker.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.elem cfg.host [
          "127.0.0.1"
          "::1"
          "localhost"
        ];
        message = "khanelinix.services.cliproxyapi.host must remain loopback-only";
      }
      {
        assertion = lib.all (
          model: lib.hasPrefix "claude" model.alias || lib.hasPrefix "anthropic" model.alias
        ) cfg.claudeCodeModels;
        message = "khanelinix.services.cliproxyapi.claudeCodeModels aliases must start with claude or anthropic";
      }
      {
        assertion =
          let
            aliases = map (model: model.alias) cfg.claudeCodeModels;
          in
          lib.length aliases == lib.length (lib.unique aliases);
        message = "khanelinix.services.cliproxyapi.claudeCodeModels aliases must be unique";
      }
    ];

    home = {
      activation.cliproxyapiState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${lib.getExe' pkgs.coreutils "mkdir"} -p ${lib.escapeShellArg authDir}
      '';

      packages = [
        cfg.package
        (loginCommand "claude" "--claude-login")
        (loginCommand "codex" "--codex-login")
        (loginCommand "gemini" "--antigravity-login")
      ];

      shellAliases =
        lib.optionalAttrs claudeCodeEnabled {
          claude = claudeCommand "claude" cfg.models.claude;
          claude-claude = claudeCommand "claude" cfg.models.claude;
          claude-codex = claudeCommand "codex" cfg.models.codex;
          claude-direct = lib.concatStringsSep " " [
            "ANTHROPIC_BASE_URL=https://api.anthropic.com"
            "ANTHROPIC_AUTH_TOKEN=''"
            "CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=0"
            "ENABLE_TOOL_SEARCH=true"
            "command claude"
          ];
          claude-gemini = claudeCommand "antigravity" cfg.models.gemini;
          claudex = claudeCommand "codex" cfg.models.codex;
        }
        // lib.optionalAttrs codexEnabled {
          codex-claude = codexCommand "claude" cfg.models.claude;
          codex-codex = codexCommand "codex" cfg.models.codex;
          codex-gemini = codexCommand "antigravity" cfg.models.gemini;
        }
        // lib.optionalAttrs opencodeEnabled {
          opencode-claude = "opencode --model cliproxyapi/${proxyModel "claude" cfg.models.claude}";
          opencode-codex = "opencode --model cliproxyapi/${proxyModel "codex" cfg.models.codex}";
          opencode-gemini = "opencode --model cliproxyapi/${proxyModel "antigravity" cfg.models.gemini}";
        };
    };

    xdg.configFile."cliproxyapi/config.yaml".source = proxyConfig;

    programs.codex.settings.model_providers.cliproxyapi = mkIf codexEnabled {
      name = "CLIProxyAPI";
      base_url = "${baseUrl}/v1";
      experimental_bearer_token = apiKey;
      wire_api = "responses";
      requires_openai_auth = true;
      supports_websockets = true;
    };

    programs.opencode.settings.provider.cliproxyapi = mkIf opencodeEnabled {
      npm = "@ai-sdk/openai-compatible";
      name = "CLIProxyAPI";
      options = {
        baseURL = "${baseUrl}/v1";
        inherit apiKey;
      };
      models =
        builtins.listToAttrs (
          map (model: {
            name = model.alias;
            value.name = model.displayName;
          }) cfg.claudeCodeModels
        )
        // {
          "${proxyModel "claude" cfg.models.claude}".name = "Anthropic · Fable 5";
          "claude-opus-4-8".name = "Anthropic · Opus 4.8";
          "claude-sonnet-5".name = "Anthropic · Sonnet 5";
        };
    };

    programs.claude-code.settings.env = mkIf claudeCodeEnabled claudeGatewayEnv;

    systemd.user.services.cliproxyapi = mkIf pkgs.stdenv.hostPlatform.isLinux {
      Unit = {
        Description = "CLIProxyAPI local AI provider proxy";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
        X-Restart-Triggers = [ "${proxyConfig}" ];
      };

      Service = {
        ExecStart = "${lib.getExe cfg.package} --config ${configPath}";
        Restart = "on-failure";
        RestartSec = "5s";
      };

      Install.WantedBy = [ "default.target" ];
    };

    launchd.agents.cliproxyapi.config = mkIf pkgs.stdenv.hostPlatform.isDarwin {
      ProgramArguments = [
        (lib.getExe cfg.package)
        "--config"
        configPath
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.xdg.stateHome}/cliproxyapi/stdout.log";
      StandardErrorPath = "${config.xdg.stateHome}/cliproxyapi/stderr.log";
    };
  };
}
