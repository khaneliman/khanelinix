{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf getExe getExe';
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  cfg = config.khanelinix.programs.graphical.addons.mako;
in
{
  options.khanelinix.programs.graphical.addons.mako = {
    enable = lib.mkEnableOption "Mako in Sway";
  };

  config = lib.mkMerge [
    (mkIf cfg.enable {
      assertions = [
        {
          assertion = isLinux;
          message = "Mako is only available on linux";
        }
      ];
    })
    (mkIf (cfg.enable && isLinux) {
      home.packages = with pkgs; [
        mako
        libnotify
      ];

      # Mako configuration
      # See: https://man.archlinux.org/man/mako.5
      xdg.configFile."mako/config".source = ./config;

      systemd.user.services.mako = {
        Unit = {
          After = [ "graphical-session.target" ];
          Description = "Mako notification daemon";
          PartOf = [ "graphical-session.target" ];
        };
        Install.WantedBy = [ "graphical-session.target" ];
        Service = {
          Type = "dbus";
          BusName = "org.freedesktop.Notifications";

          ExecCondition = /* bash */ ''
            ${getExe pkgs.bash} -c '[ -n "$WAYLAND_DISPLAY" ]'
          '';

          ExecStart = /* bash */ ''
            ${getExe pkgs.mako}
          '';

          ExecReload = /* bash */ ''
            ${getExe' pkgs.mako "makoctl"} reload
          '';

          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };
    })
  ];
}
