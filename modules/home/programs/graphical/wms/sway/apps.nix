{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf getExe;

  cfg = config.${namespace}.programs.graphical.wms.sway;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.sway = {
      config = {
        startup = [
          { command = getExe config.programs.firefox.package; }
          { command = getExe pkgs.steam; }
          { command = getExe pkgs.discord; }
          { command = getExe pkgs.thunderbird; }

          # Startup background apps
          { command = "${getExe pkgs.openrgb-with-all-plugins} --startminimized --profile default"; }
          { command = "${getExe pkgs._1password-gui} --silent"; }
          { command = getExe pkgs.tailscale-systray; }
          { command = "run-as-service $(${getExe pkgs.wayvnc} $(${getExe pkgs.tailscale} ip --4))"; }
        ];
      };
    };
  };
}
