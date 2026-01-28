{
  config,
  lib,
  pkgs,
  ...
}:
let
  helpers = import ./helpers.nix {
    inherit config lib pkgs;
    osConfig = { };
  };
in
{
  # Power menu custom module
  CustomPowerMenu = {
    name = "CustomPowerMenu";
    icon = "󰐥";
    command = "${lib.getExe helpers.powerMenuHelper}";
    icons = {
      "power" = "󰐥";
      "none" = "󰐥";
    };
  };

  # Notification center integration
  CustomNotifications = {
    name = "CustomNotifications";
    icon = "󰂚";
    command = "${lib.getExe' config.services.swaync.package "swaync-client"} -t -sw";
    listen_cmd = "${lib.getExe helpers.notificationHelper}";
    icons = {
      "dnd.*" = "󰂛";
      "notification" = "󰂚";
      "none" = "󰂜";
    };
    alert = ".*notification";
  };

  # GitHub notifications with interactive menu
  CustomGithub = {
    name = "CustomGithub";
    icon = "󰊤";
    command = "${lib.getExe helpers.githubMenuHelper}";
    listen_cmd = "${lib.getExe helpers.githubHelper}";
    icons = {
      "notification" = "󰊤";
      "none" = "󰊤";
    };
    alert = ".*notification";
  };

  # Weather display with detailed popup
  CustomWeather = {
    name = "CustomWeather";
    icon = "󰖕 ";
    command = "${lib.getExe helpers.weatherDetailPopup}";
    listen_cmd = "${
      lib.getExe (
        pkgs.wttrbar.overrideAttrs {
          # Ashell needs `alt` instead of tooltip
          postPatch = ''
            substituteInPlace src/main.rs \
            --replace-fail "data.insert(\"tooltip\", tooltip);" \
                           "data.insert(\"alt\", tooltip);"
          '';
        }
      )
    } --fahrenheit --ampm";
    icons = {
      "weather" = "󰖕";
      "none" = "󰖕";
    };
  };
}
