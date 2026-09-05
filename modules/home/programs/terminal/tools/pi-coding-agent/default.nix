{
  config,
  lib,
  osConfig ? { },
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

  cfg = config.khanelinix.programs.terminal.tools.pi-coding-agent;
  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib pkgs; };
  projectedSkills = aiTools.piCodingAgent.skills;

  # Same local endpoints opencode uses; each model is reached through the
  # service that owns it (see opencode/provider.nix).
  ollamaEnabled =
    (config.services.ollama.enable or false) || (osConfig.services.ollama.enable or false);
  swapCfg = osConfig.khanelinix.services.llm.llamaSwap or { };
  swapEnabled = swapCfg.enable or false;
  swapEndpoint = swapCfg.endpoint or "http://127.0.0.1:8090/v1";
  # These servers do not accept the developer role or reasoning_effort.
  localCompat = {
    supportsDeveloperRole = false;
    supportsReasoningEffort = false;
  };
  localProviders =
    lib.optionalAttrs (config.services.exo.enable or false) {
      exo = {
        baseUrl = "http://localhost:52415/v1";
        api = "openai-completions";
        apiKey = "exo";
        compat = localCompat;
        models = [
          {
            id = "mlx-community/Qwen3-Coder-Next-4bit";
            name = "Qwen3 Coder Next 4bit";
          }
          {
            id = "mlx-community/Qwen3.6-35B-A3B-5bit";
            name = "Qwen3.6 35B A3B 5bit";
          }
          {
            id = "mlx-community/gpt-oss-20b-MXFP4-Q8";
            name = "GPT OSS 20B MXFP4 Q8";
            reasoning = true;
          }
        ];
      };
    }
    // lib.optionalAttrs swapEnabled {
      llama-swap = {
        baseUrl = swapEndpoint;
        api = "openai-completions";
        apiKey = "llama-swap";
        compat = localCompat;
        models = [
          {
            id = "qwen3-6-27b";
            name = "Qwen3.6 27B";
          }
          {
            id = "qwen3-coder-30b";
            name = "Qwen3 Coder 30B";
          }
          {
            id = "qwen36-colibri";
            name = "Qwen3.6 35B-A3B (streamed)";
          }
        ];
      };
    }
    // lib.optionalAttrs ollamaEnabled {
      ollama = {
        baseUrl = "http://localhost:11434/v1";
        api = "openai-completions";
        apiKey = "ollama";
        compat = localCompat;
        models = [
          {
            id = "glm-4.7-flash";
            name = "GLM 4.7 Flash";
          }
          {
            id = "gpt-oss:20b";
            name = "GPT OSS 20B";
            reasoning = true;
          }
        ];
      };
    };
in
{
  options.khanelinix.programs.terminal.tools.pi-coding-agent = {
    enable = mkEnableOption "Pi coding agent configuration";

    package = mkOption {
      type = types.package;
      default = pkgs.pi-coding-agent;
      defaultText = lib.literalExpression "pkgs.pi-coding-agent";
      description = "Package providing the pi CLI.";
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Settings written to ~/.pi/agent/settings.json.";
    };
  };

  config = mkIf cfg.enable {
    home = {
      sessionVariables = {
        PI_SKIP_VERSION_CHECK = "1";
        PI_TELEMETRY = "0";
      };

      shellAliases = {
        pi-deep = "pi --model openai-codex/gpt-6-astra --thinking high";
        pi-json = "pi --mode json";
        pi-print = "pi --print";
        pi-quick = "pi --model openai-codex/gpt-5.3-codex-spark --thinking low";
        pi-read = "pi --tools read,grep,find,ls";
        pi-spark = "pi --model openai-codex/gpt-5.3-codex-spark --thinking high";
      };
    };

    programs.pi-coding-agent = {
      enable = true;
      inherit (cfg) package;
      context = aiTools.base;
      models = lib.mkIf (localProviders != { }) { providers = localProviders; };
      settings = lib.recursiveUpdate {
        defaultProvider = "openai-codex";
        defaultModel = "gpt-5.6-luna";
        defaultThinkingLevel = "high";
        enableInstallTelemetry = false;
        collapseChangelog = true;
        transport = "auto";

        packages = [
          aiTools.planningWithFiles.piCodingAgent.package
        ];

        skills = [ projectedSkills ];

        compaction = {
          reserveTokens = 20000;
          keepRecentTokens = 50000;
        };

        retry = {
          provider.maxRetryDelayMs = 60000;
        };
      } cfg.settings;
    };
  };
}
