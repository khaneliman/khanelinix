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

  cfg = config.khanelinix.programs.graphical.editors.antigravity;
  mcpModuleEnabled = config.khanelinix.programs.terminal.tools.mcp.enable or false;
in
{
  options.khanelinix.programs.graphical.editors.antigravity = {
    enable = mkEnableOption "Antigravity IDE configuration";
  };

  config = mkIf cfg.enable {
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
