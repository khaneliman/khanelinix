{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf getExe;

  cfg = config.khanelinix.programs.graphical.wms.sway;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.sway = {
      config = {
        startup = [
          # 1/2
          { command = getExe config.programs.firefox.package; }

          # 4
          { command = getExe pkgs.steam; }

          # 5
          { command = getExe config.programs.vesktop.package; }
          { command = getExe pkgs.element-desktop; }
          { command = getExe pkgs.teams-for-linux; }

          # 6
          { command = getExe pkgs.thunderbird; }

          # Startup background apps
          { command = "${getExe pkgs.openrgb-with-all-plugins} -c blue"; }
          { command = "${getExe pkgs._1password-gui} --silent"; }
          { command = getExe pkgs.tailscale-systray; }
          { command = getExe pkgs.networkmanagerapplet; }
          { command = "${getExe pkgs.wl-clip-persist} --clipboard both"; }

          { command = "$(${getExe pkgs.wayvnc} $(${getExe pkgs.tailscale} ip --4))"; }

          { command = "${lib.getExe pkgs.libnotify} --icon ~/.face -u normal \"Hello $(whoami)\""; }
        ];
      };
    };
  };
}
