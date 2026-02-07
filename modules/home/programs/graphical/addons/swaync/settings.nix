{
  config,
  lib,

  osConfig ? { },
  pkgs,
}:

let
  inherit (lib) getExe getExe';
in
{
  "$schema" = "/etc/xdg/swaync/configSchema.json";
  control-center-height = 640;
  control-center-margin-bottom = 0;
  control-center-margin-left = 12;
  control-center-margin-right = 12;
  control-center-margin-top = 12;
  control-center-width = 480;
  cssPriority = "user";
  fit-to-screen = true;
  hide-on-action = true;
  hide-on-clear = false;
  image-visibility = "when-available";
  keyboard-shortcuts = true;
  layer = "top";
  notification-body-image-height = 120;
  notification-body-image-width = 240;
  notification-icon-size = 56;
  notification-visibility = { };
  notification-window-width = 460;
  positionX = "right";
  positionY = "top";
  script-fail-notify = true;
  scripts = { };
  timeout = 8;
  timeout-critical = 0;
  timeout-low = 4;
  transition-time = 220;

  widgets = [
    "label"
    "menubar"
    "buttons-grid"
    "volume"
    "mpris"
    "title"
    "dnd"
    "notifications"
  ];

  widget-config = {
    title = {
      text = "Notifications";
      clear-all-button = true;
      button-text = "Clear All";
    };
    dnd = {
      text = "Do Not Disturb";
    };
    label = {
      max-lines = 1;
      text = "Control Center";
    };
    mpris = {
      image-size = 112;
      image-radius = 16;
    };
    "backlight#KB" = {
      label = " ";
      device = "corsair::kbd_backlight";
      subsystem = "leds";
    };
    volume = {
      label = "";
      show-per-app = true;
    };
    "menubar" = {
      "menu#power-buttons" = {
        label = "";
        position = "right";
        actions = [
          {
            label = " Reboot";
            command = "systemctl reboot";
          }
          {
            label = " Lock";
            command = ''
              sh -c '
                if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ];
                  then ${getExe config.programs.hyprlock.package};
                else ${getExe config.programs.swaylock.package};
                fi'
            '';
          }
          {
            label = " Logout";
            command =
              if (osConfig.programs.uwsm.enable or false) then "uwsm stop" else "loginctl terminate-user $USER";
          }
          {
            label = " Shut down";
            command = "systemctl poweroff";
          }
        ];
      };

      "menu#powermode-buttons" = lib.mkIf (osConfig.services.power-profiles-daemon.enable or false) {
        label = "";
        position = "left";
        actions = [
          {
            label = "Performance";
            active = true;
            command = "powerprofilesctl set performance";
            update-command = ''sh -c "[[ $(powerprofilesctl get) == "performance" ]] && echo true || echo false"'';
          }
          {
            label = "Balanced";
            active = false;
            command = "powerprofilesctl set balanced";
            update-command = ''sh -c "[[ $(powerprofilesctl get) == "balanced" ]] && echo true || echo false"'';
          }
          {
            label = "Power-saver";
            active = false;
            command = "powerprofilesctl set power-saver";
            update-command = ''sh -c "[[ $(powerprofilesctl get) == "power-saver" ]] && echo true || echo false"'';
          }
        ];
      };

      "menu#screenshot-buttons" = {
        label = "";
        position = "left";
        actions = [
          {
            label = "󰹑  Whole screen";
            command = ''
              sh -c '
                if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ];
                  then ${getExe pkgs.grimblast} --notify save screen;
                else ${getExe pkgs.grim} - | ${getExe' pkgs.wl-clipboard "wl-copy"};
                fi'
            '';
          }
          {
            label = "󰩭  Window / Region";
            command = ''
              sh -c '
                if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ];
                  then ${getExe pkgs.grimblast} --notify --freeze save area;
                else ${getExe pkgs.grim} -g "$(${getExe pkgs.slurp})" - | ${getExe' pkgs.wl-clipboard "wl-copy"};
                fi'
            '';
          }
          {
            label = "  Record area";
            command = "${lib.getExe pkgs.khanelinix.record_screen} area & ; swaync-client -t";
          }
          {
            label = "  Record screen";
            command = "${lib.getExe pkgs.khanelinix.record_screen} screen & ; swaync-client -t";
          }
          {
            label = "  Stop Record";
            command = "${lib.getExe pkgs.khanelinix.record_screen} stop & ; swaync-client -t";
          }
        ];
      };
    };

    buttons-grid = {
      actions = [
        {
          label = "";
          command = "${getExe' pkgs.networkmanagerapplet "nm-connection-editor"}";
        }
        {
          label = "";
          command = "${getExe' pkgs.blueman "blueman-manager"}";
        }
      ];
    };
  };
}
