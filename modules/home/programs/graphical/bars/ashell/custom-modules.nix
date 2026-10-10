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
    listen_cmd = lib.getExe (
      pkgs.writeShellScriptBin "ashell-weather-helper" ''
        ${lib.optionalString (config.khanelinix.services.sops.enable or false) ''
          LOCATION=$(${lib.getExe pkgs.jq} -ers '
          if length == 1 then .[0].wttr.location else null end
          | if type == "string" then
              if length > 0 and (test("[\u0000-\u001f\u007f]") | not) then .
              else error("weather location must be nonempty and contain no control characters") end
            else error("weather location must be a string") end
          ' ${lib.escapeShellArg "${config.home.homeDirectory}/weather_config.json"}) || exit $?
        ''}
        exec ${
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
          lib.optionalString (config.khanelinix.services.sops.enable or false) " --location=\"$LOCATION\""
        }
      ''
    );
    icons = {
      "weather" = "󰖕";
      "none" = "󰖕";
    };
  };
}
