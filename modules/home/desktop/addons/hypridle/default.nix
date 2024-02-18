{ config
, inputs
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf getExe getExe';
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.desktop.addons.hypridle;
in
{
  options.khanelinix.desktop.addons.hypridle = {
    enable =
      mkBoolOpt false "Whether to enable hypridle in the desktop environment.";
  };

  config = mkIf cfg.enable {
    xdg.configFile = {
      "hypr/hypridle.conf".text = /* bash */ ''
        general {
            lock_cmd = "${getExe config.programs.swaylock.package} -defF"  # dbus/sysd lock command (loginctl lock-session)
            # unlock_cmd = notify-send "unlock!"      # same as above, but unlock
            before_sleep_cmd = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch dpms off"
            after_sleep_cmd = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch dpms on"
            ignore_dbus_inhibit = false # whether to ignore dbus-sent idle-inhibit requests (used by e.g. firefox or steam)
        }

        listener {
          timeout = 900
          on-timeout = "${getExe config.programs.swaylock.package} -defF"
        }

        listener {
          timeout = 1200
          on-timeout = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch dpms off"
        }
      '';
    };

    systemd.user.services.hypridle = {
      Install.WantedBy = [ "hyprland-session.target" ];

      Unit = {
        Description = "Hypridle Service";
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${getExe pkgs.khanelinix.hypridle}";
        Restart = "always";
      };
    };
  };
}
