{
  config,
  lib,
  pkgs,
  osConfig ? { },
  helpers ? import ./helpers.nix {
    inherit
      config
      lib
      pkgs
      osConfig
      ;
  },
  ...
}:
{
  CustomPowerMenu = {
    name = "CustomPowerMenu";
    icon = "󰐥";
    command = "${lib.getExe helpers.powerMenuHelper}";
    icons = {
      "power" = "󰐥";
      "none" = "󰐥";
    };
  };

  CustomNotifications = {
    name = "CustomNotifications";
    icon = "󰂚 ";
    command = "${lib.getExe' config.services.swaync.package "swaync-client"} -t -sw";
    listen_cmd = "${lib.getExe helpers.notificationHelper}";
    icons = {
      "dnd.*" = "󰂛 ";
      "notification" = "󰂚 ";
      "none" = "󰂜 ";
    };
    alert = ".*notification";
  };

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
    } --fahrenheit --ampm${
      lib.optionalString (osConfig.khanelinix.security.sops.enable or false
      ) " --location $(jq '.wttr.location' ${config.home.homeDirectory}/weather_config.json)"
    }";
    icons = {
      "weather" = "󰖕";
      "none" = "󰖕";
    };
  };
}
