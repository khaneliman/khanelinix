{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf getExe getExe';
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.graphical.addons.mako;
in
{
  options.${namespace}.programs.graphical.addons.mako = {
    enable = mkBoolOpt false "Whether to enable Mako in Sway.";
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
