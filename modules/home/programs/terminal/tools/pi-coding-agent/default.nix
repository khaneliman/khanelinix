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
  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib pkgs; };
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
        pi-deep = "pi --model openai-codex/gpt-5.5 --thinking high";
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
      settings = lib.recursiveUpdate {
        defaultProvider = "openai-codex";
        defaultModel = "gpt-5.4-mini";
        defaultThinkingLevel = "high";
        enableInstallTelemetry = false;
        collapseChangelog = true;
        transport = "auto";

        packages = [
          aiTools.planningWithFiles.piCodingAgent.package
        ];

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
