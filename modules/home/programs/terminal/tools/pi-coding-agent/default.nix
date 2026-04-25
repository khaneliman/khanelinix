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

  cfg = config.khanelinix.programs.terminal.tools.pi-coding-agent;
  codexEnabled = config.khanelinix.programs.terminal.tools.codex.enable or false;
  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib; };
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
      packages = [ cfg.package ];

      sessionVariables = {
        PI_SKIP_VERSION_CHECK = "1";
        PI_TELEMETRY = "0";
      };

      shellAliases = {
        pi-deep = "pi --model openai-codex/gpt-5.5 --thinking high";
        pi-json = "pi --mode json";
        pi-print = "pi --print";
        pi-quick = "pi --model openai-codex/gpt-5.3-codex-spark --thinking low";
        pi-read = "pi --tools read,grep,find,ls";
        pi-spark = "pi --model openai-codex/gpt-5.3-codex-spark --thinking high";
      };

      file = {
        ".pi/agent/AGENTS.md".source = aiTools.base;
        ".pi/agent/settings.json".text = builtins.toJSON (
          lib.recursiveUpdate {
            defaultProvider = "openai-codex";
            defaultModel = "gpt-5.3-codex-spark";
            defaultThinkingLevel = "high";
            enableInstallTelemetry = false;
            collapseChangelog = true;
            transport = "auto";

            compaction = {
              reserveTokens = 20000;
              keepRecentTokens = 50000;
            };

            retry = {
              provider.maxRetryDelayMs = 60000;
            };
          } cfg.settings
        );
      }
      // lib.optionalAttrs (!codexEnabled) {
        ".pi/agent/skills".source = aiTools.skillsDir;
      };
    };
  };
}
