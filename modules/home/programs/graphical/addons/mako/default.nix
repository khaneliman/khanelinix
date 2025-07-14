{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf getExe getExe';

  cfg = config.khanelinix.programs.graphical.addons.mako;
in
{
  options.khanelinix.programs.graphical.addons.mako = {
    enable = lib.mkEnableOption "Mako in Sway";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      mako
      libnotify
    ];

    xdg.configFile."mako/config".source = ./config;

    systemd.user.services.mako = {
      after = [ "graphical-session.target" ];
      description = "Mako notification daemon";
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";

        ExecCondition = # bash
          ''
            ${getExe pkgs.bash} -c '[ -n "$WAYLAND_DISPLAY" ]'
          '';

        ExecStart = # bash
          ''
            ${getExe pkgs.mako}
          '';

        ExecReload = # bash
          ''
            ${getExe' pkgs.mako "makoctl"} reload
          '';

        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
