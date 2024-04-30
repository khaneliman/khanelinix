{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  system,
}:

let
  inherit (lib) getExe getExe' mkIf;
  inherit (inputs) nixpkgs-wayland;

  grim = getExe nixpkgs-wayland.packages.${system}.grim;
  slurp = getExe pkgs.slurp;
in
{
  "$schema" = "/etc/xdg/swaync/configSchema.json";
  control-center-height = 600;
  control-center-margin-bottom = 0;
  control-center-margin-left = 0;
  control-center-margin-right = 10;
  control-center-margin-top = 10;
  control-center-width = 500;
  cssPriority = "user";
  fit-to-screen = true;
  hide-on-action = true;
  hide-on-clear = false;
  image-visibility = "when-available";
  keyboard-shortcuts = true;
  layer = "top";
  notification-body-image-height = 100;
  notification-body-image-width = 200;
  notification-icon-size = 64;
  notification-visibility = { };
  notification-window-width = 500;
  positionX = "right";
  positionY = "top";
  script-fail-notify = true;
  scripts = { };
  timeout = 10;
  timeout-critical = 0;
  timeout-low = 5;
  transition-time = 200;

  widgets = [
    "menubar#label"
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
      max-lines = 4;
      text = "Control Center";
    };
    mpris = {
      image-size = 96;
      image-radius = 12;
    };
    "backlight#KB" = {
      label = " ";
      device = "corsair::kbd_backlight";
      subsystem = "leds";
    };
    volume = {
      label = "";
    };
    "menubar#label" = {
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
            command = "hyprlock --immediate";
          }
          {
            label = " Logout";
            command = "hyprctl exit";
          }
          {
            label = " Shut down";
            command = "systemctl poweroff";
          }
        ];
      };

      "menu#powermode-buttons" = mkIf osConfig.services.power-profiles-daemon.enable {
        label = "";
        position = "left";
        actions = [
          {
            label = "Performance";
            command = "powerprofilesctl set performance";
          }
          {
            label = "Balanced";
            command = "powerprofilesctl set balanced";
          }
          {
            label = "Power-saver";
            command = "powerprofilesctl set power-saver";
          }
        ];
      };

      "buttons#topbar-buttons" = {
        position = "left";
        actions = [
          {
            label = "";
            command = ''${grim} -g "$(${slurp})" - | ${getExe pkgs.swappy} -f -'';
          }
        ];
      };
    };

    buttons-grid = {
      actions = [
        {
          label = "";
          command = "~/.config/rofi/rofi-wifi-menu.sh";
        }
        {
          label = "";
          command = "~/.config/rofi/rofi-bluetooth";
        }
      ];
    };
  };
}
