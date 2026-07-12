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

  cfg = config.khanelinix.programs.graphical.editors.antigravity;
  mcpModuleEnabled = config.khanelinix.programs.terminal.tools.mcp.enable or false;
  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib pkgs; };
in
{
  options.khanelinix.programs.graphical.editors.antigravity = {
    enable = mkEnableOption "Antigravity IDE configuration";
  };

  config = mkIf cfg.enable {
    home.file.".gemini/config/plugins/okf-memory".source =
      lib.mkDefault aiTools.antigravityCli.okfMemoryPlugin;

    programs.antigravity = {
      enable = true;
      mutableExtensionsDir = false;

      profiles.default = {
        enableExtensionUpdateCheck = false;
        enableMcpIntegration = mkIf mcpModuleEnabled true;
        enableUpdateCheck = false;

        userSettings = {
          "telemetry.telemetryLevel" = "off";
        };
      };
    };
  };
}
