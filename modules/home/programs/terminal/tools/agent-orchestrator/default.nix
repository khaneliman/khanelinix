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

  cfg = config.khanelinix.programs.terminal.tools.agent-orchestrator;
in
{
  options.khanelinix.programs.terminal.tools.agent-orchestrator = {
    enable = mkEnableOption "Agent Orchestrator configuration";

    package = mkOption {
      type = types.package;
      default = pkgs.khanelinix.agent-orchestrator;
      defaultText = lib.literalExpression "pkgs.khanelinix.agent-orchestrator";
      description = "Package providing the agent-orchestrator script.";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [ cfg.package ];

      shellAliases = {
        "ao" = "agent-orchestrator";
      };
    };
  };
}
