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
  };

  claudeCommand =
    model:
    lib.concatStringsSep " " [
      "ANTHROPIC_BASE_URL=${lib.escapeShellArg baseUrl}"
      "ANTHROPIC_AUTH_TOKEN=${lib.escapeShellArg apiKey}"
      "ANTHROPIC_DEFAULT_OPUS_MODEL=${lib.escapeShellArg model}"
      "ANTHROPIC_DEFAULT_SONNET_MODEL=${lib.escapeShellArg model}"
      "ANTHROPIC_DEFAULT_HAIKU_MODEL=${lib.escapeShellArg model}"
      "CLAUDE_CODE_SUBAGENT_MODEL=${lib.escapeShellArg model}"
      "CLAUDE_CODE_ALWAYS_ENABLE_EFFORT=1"
      "CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY=3"
      "ENABLE_TOOL_SEARCH=false"
      "claude"
      "--model"
      (lib.escapeShellArg model)
    ];

  codexCommand =
    model: "codex --strict-config -c model_provider='\"cliproxyapi\"' -m ${lib.escapeShellArg model}";

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
        default = "gemini-3.5-flash";
        description = "Gemini provider model used by harness aliases.";
      };
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
          claude-claude = claudeCommand cfg.models.claude;
          claude-codex = claudeCommand cfg.models.codex;
          claude-gemini = claudeCommand cfg.models.gemini;
          claudex = claudeCommand cfg.models.codex;
        }
        // lib.optionalAttrs codexEnabled {
          codex-claude = codexCommand cfg.models.claude;
          codex-codex = codexCommand cfg.models.codex;
          codex-gemini = codexCommand cfg.models.gemini;
        }
        // lib.optionalAttrs opencodeEnabled {
          opencode-claude = "opencode --model cliproxyapi/${cfg.models.claude}";
          opencode-codex = "opencode --model cliproxyapi/${cfg.models.codex}";
          opencode-gemini = "opencode --model cliproxyapi/${cfg.models.gemini}";
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
      models = {
        "${cfg.models.claude}".name = "Claude via CLIProxyAPI";
        "${cfg.models.codex}".name = "Codex via CLIProxyAPI";
        "${cfg.models.gemini}".name = "Gemini via CLIProxyAPI";
      };
    };

    systemd.user.services.cliproxyapi = mkIf pkgs.stdenv.hostPlatform.isLinux {
      Unit = {
        Description = "CLIProxyAPI local AI provider proxy";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
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
