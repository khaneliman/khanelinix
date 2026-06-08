{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;

  cfg = config.khanelinix.programs.terminal.tools.antigravity-cli;
  mcpModuleEnabled = config.khanelinix.programs.terminal.tools.mcp.enable or false;
  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib; };
in
{
  imports = [
    ./permissions.nix
  ];

  options.khanelinix.programs.terminal.tools.antigravity-cli = {
    enable = mkEnableOption "Antigravity CLI configuration";
  };

  config = mkIf cfg.enable {
    programs.antigravity-cli = {
      enable = true;
      enableMcpIntegration = mkIf mcpModuleEnabled true;

      settings = {
        altScreenMode = "always";
        colorScheme = "tokyo night";
      };

      inherit (aiTools.antigravityCli) commands skills;
      context = {
        AGENTS = aiTools.base;
      };
    };
  };
}
