{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.programs.graphical.apps.vesktop;
in
{
  options.${namespace}.programs.graphical.apps.vesktop = {
    enable = lib.mkEnableOption "Vesktop";
  };

  config = lib.mkIf cfg.enable {
    programs.vesktop = {
      enable = true;

      settings = {
        discordBranch = "stable";
        minimizeToTray = true;
        arRPC = true;
        customTitleBar = false;
      };

      vencord = {
        settings = { };
      };
    };
  };
}
