{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf getExe getExe';
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.desktop.addons.mako;
in
{
  options.khanelinix.desktop.addons.mako = {
    enable = mkBoolOpt false "Whether to enable Mako in Sway.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ mako libnotify ];

    khanelinix.home.configFile."mako/config".source = ./config;

    systemd.user.services.mako = {
      after = [ "graphical-session.target" ];
      description = "Mako notification daemon";
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";

        ExecCondition = ''
          ${getExe pkgs.bash} -c '[ -n "$WAYLAND_DISPLAY" ]'
        '';

        ExecStart = ''
          ${getExe pkgs.mako}
        '';

        ExecReload = ''
          ${getExe' pkgs.mako "makoctl"} reload
        '';

        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };

  };
}
