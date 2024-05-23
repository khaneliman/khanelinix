{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.${namespace}.services.tray;
in
{
  options.${namespace}.services.tray = {
    enable = mkEnableOption "tray";
  };

  config = mkIf cfg.enable {
    systemd.user.targets.tray = {
      Unit = {
        Description = "Home Manager System Tray";
        Requires = [ "graphical-session-pre.target" ];
      };
    };
  };
}
