{
  config,
  lib,

  osConfig ? { },
  pkgs,
  ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.programs.graphical.bars.ashell;
  isNiri = config.khanelinix.programs.graphical.wms.niri.enable;

  lockCommand =
    if config.khanelinix.programs.graphical.screenlockers.hyprlock.enable then
      lib.getExe config.programs.hyprlock.package
    else if config.khanelinix.programs.graphical.screenlockers.swaylock.enable then
      lib.getExe config.programs.swaylock.package
    else
      "loginctl lock-session";

  logoutCommand =
    if config.khanelinix.programs.graphical.wms.hyprland.enable then
      "${lib.getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch exit"
    else
      "systemctl --user exit";
in
{
  options.khanelinix.programs.graphical.bars.ashell = {
    enable = lib.mkEnableOption "ashell in the desktop environment";

    style = mkOpt types.str "Islands" "Style of the bar";

    margin = {
      top = mkOpt types.int 10 "Top margin";
      left = mkOpt types.int 20 "Left margin";
      right = mkOpt types.int 20 "Right margin";
      bottom = mkOpt types.int 0 "Bottom margin";
    };

    fullSizeOutputs = mkOpt (types.listOf types.str) [ ] "Outputs to use full size bar on";
    condensedOutputs = mkOpt (types.listOf types.str) [ ] "Outputs to use condensed bar on";

    customModules = mkOpt (types.listOf types.attrs) [ ] "Custom modules configuration";
  };

  config = mkIf cfg.enable {
    programs.ashell = {
      enable = true;
      systemd.enable = true;
      settings =
        let
          # Custom notification helper for swaync integration
          notificationHelper = pkgs.writeShellScriptBin "ashell-notification-helper" ''
            if command -v ${lib.getExe' config.services.swaync.package "swaync-client"} &> /dev/null; then
              ${lib.getExe' config.services.swaync.package "swaync-client"} -swb
            else
              echo '{"text": "0", "alt": "none"}'
            fi
          '';

          # GitHub notifications helper
          githubHelper = pkgs.writeShellScriptBin "ashell-github-helper" ''
            ${lib.optionalString (osConfig.khanelinix.security.sops.enable or false) ''
              ${lib.getExe pkgs.gh} auth login --with-token < ${config.sops.secrets."github/access-token".path}
            ''}

            COUNT="$(${lib.getExe pkgs.gh} api notifications --jq 'length' 2>/dev/null || echo "0")"
            if [ "$COUNT" -gt 0 ]; then
              echo "{\"text\": \"$COUNT\", \"alt\": \"notification\"}"
            else
              echo "{\"text\": \"0\", \"alt\": \"none\"}"
            fi
          '';

          # Detailed weather popup
          weatherDetailPopup = pkgs.writeShellScriptBin "ashell-weather-detail" ''
            # Get comprehensive weather information
            CURRENT_WEATHER=$(${lib.getExe pkgs.curl} -s "wttr.in?format=j1" 2>/dev/null)

            if [ $? -eq 0 ] && [ -n "$CURRENT_WEATHER" ]; then
              # Parse JSON for detailed info
              LOCATION=$(echo "$CURRENT_WEATHER" | ${lib.getExe pkgs.jq} -r '.nearest_area[0].areaName[0].value + ", " + .nearest_area[0].country[0].value')
              CURRENT_TEMP=$(echo "$CURRENT_WEATHER" | ${lib.getExe pkgs.jq} -r '.current_condition[0].temp_F + "°F (" + .current_condition[0].temp_C + "°C)"')
              FEELS_LIKE=$(echo "$CURRENT_WEATHER" | ${lib.getExe pkgs.jq} -r '.current_condition[0].FeelsLikeF + "°F (" + .current_condition[0].FeelsLikeC + "°C)"')
              CONDITION=$(echo "$CURRENT_WEATHER" | ${lib.getExe pkgs.jq} -r '.current_condition[0].weatherDesc[0].value')
              HUMIDITY=$(echo "$CURRENT_WEATHER" | ${lib.getExe pkgs.jq} -r '.current_condition[0].humidity + "%"')
              WIND=$(echo "$CURRENT_WEATHER" | ${lib.getExe pkgs.jq} -r '.current_condition[0].windspeedMiles + " mph " + .current_condition[0].winddir16Point')
              UV_INDEX=$(echo "$CURRENT_WEATHER" | ${lib.getExe pkgs.jq} -r '.current_condition[0].uvIndex')
              VISIBILITY=$(echo "$CURRENT_WEATHER" | ${lib.getExe pkgs.jq} -r '.current_condition[0].visibility + " miles"')

              # Get today's forecast
              TODAY_HIGH=$(echo "$CURRENT_WEATHER" | ${lib.getExe pkgs.jq} -r '.weather[0].maxtempF + "°F"')
              TODAY_LOW=$(echo "$CURRENT_WEATHER" | ${lib.getExe pkgs.jq} -r '.weather[0].mintempF + "°F"')

              WEATHER_DETAIL="🌍 Location: $LOCATION

              🌡️  Current: $CURRENT_TEMP
              🤚 Feels like: $FEELS_LIKE
              ☁️  Condition: $CONDITION

              📊 Today's Range: $TODAY_LOW - $TODAY_HIGH
              💧 Humidity: $HUMIDITY
              💨 Wind: $WIND
              ☀️  UV Index: $UV_INDEX
              👁️  Visibility: $VISIBILITY"
            else
              WEATHER_DETAIL="❌ Unable to fetch detailed weather information"
            fi

            # Show in rofi popup
            if command -v ${lib.getExe pkgs.rofi} &> /dev/null; then
              echo "$WEATHER_DETAIL" | ${lib.getExe pkgs.rofi} -dmenu -p "Weather Details" -theme-str 'window {width: 500px; height: 350px;}' -no-custom
            else
              # Fallback to terminal notification
              echo "$WEATHER_DETAIL"
            fi
          '';

          # Power menu helper with rofi integration
          powerMenuHelper = pkgs.writeShellScriptBin "ashell-power-menu" ''
            # Create power menu options
            POWER_OPTIONS="🔒 Lock
            🌙 Sleep
            🔄 Restart
            ⏻ Shutdown
            🚪 Logout"

            # Use rofi to display power options
            SELECTED=$(echo "$POWER_OPTIONS" | ${lib.getExe pkgs.rofi} -dmenu -p "Power Menu" -theme-str 'window {width: 200px;}' -no-custom)

            case "$SELECTED" in
              "🔒 Lock")
                ${lockCommand} &
                ;;
              "🌙 Sleep")
                systemctl suspend
                ;;
              "🔄 Restart")
                systemctl reboot
                ;;
              "⏻ Shutdown")
                systemctl poweroff
                ;;
              "🚪 Logout")
                ${logoutCommand}
                ;;
            esac
          '';

          # Default custom modules
          CustomPowerMenu = {
            name = "CustomPowerMenu";
            icon = "󰐥";
            command = "${lib.getExe powerMenuHelper}";
            icons = {
              "power" = "󰐥";
              "none" = "󰐥";
            };
          };
          CustomNotifications = {
            name = "CustomNotifications";
            icon = "󰂚";
            command = "${lib.getExe' config.services.swaync.package "swaync-client"} -t -sw";
            listen_cmd = "${lib.getExe notificationHelper}";
            icons = {
              "dnd.*" = "󰂛";
              "notification" = "󰂚";
              "none" = "󰂜";
            };
            alert = ".*notification";
          };
          CustomGithub = {
            name = "CustomGithub";
            icon = "󰊤";
            command = "${lib.getExe' pkgs.xdg-utils "xdg-open"} https://github.com/notifications";
            listen_cmd = "${lib.getExe githubHelper}";
            icons = {
              "notification" = "󰊤";
              "none" = "󰊤";
            };
            alert = ".*notification";
          };
          CustomWeather = {
            name = "CustomWeather";
            icon = "󰖕 ";
            command = "${lib.getExe weatherDetailPopup}";
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

          # All custom modules (default + user-defined)
          allCustomModules = [
            CustomGithub
            CustomNotifications
            CustomPowerMenu
            CustomWeather
          ]
          ++ cfg.customModules;

          leftModules = [
            "CustomPowerMenu"
            "Workspaces"
            "WindowTitle"
          ];

          rightModules = [
            "SystemInfo"
            [
              "Clipboard"
              "CustomNotifications"
              "CustomGithub"
            ]
            [
              "CustomWeather"
              "Clock"
              "Privacy"
              "Settings"
            ]
          ];

          # Configuration for different bar sizes
          commonModules = {
            left = leftModules;
            center = [ ];
            right = rightModules;
          };

          fullSizeModules = {
            left = leftModules;
            center = [ "MediaPlayer" ];
            right = [
              "Tray"
            ]
            ++ rightModules;
          };
        in
        {
          log_level = "warn";
          outputs = "All";
          position = "Top";

          app_launcher_cmd = "anyrun";
          clipboard_cmd = "cliphist-rofi-img | wl-copy";
          truncate_title_after_length = 150;

          modules =
            if cfg.fullSizeOutputs != [ ] || cfg.condensedOutputs != [ ] then
              fullSizeModules
            else
              commonModules;

          workspaces = {
            # Hyprland: workspaces are global and can be pinned to monitors.
            # Niri: workspaces are per-monitor; show all workspaces on every bar.
            visibility_mode = if isNiri then "All" else "MonitorSpecific";
            enable_workspace_filling = false;
          };

          system = {
            indicators = [
              "DownloadSpeed"
              "UploadSpeed"
              "Cpu"
              "Memory"
              "Temperature"
            ];
            cpu = {
              warn_threshold = 60;
              alert_threshold = 80;
            };
            memory = {
              warn_threshold = 70;
              alert_threshold = 85;
            };
            temperature = {
              warn_threshold = 60;
              alert_threshold = 80;
            };
            disk = {
              warn_threshold = 80;
              alert_threshold = 90;
            };
          };

          clock = {
            format = "%a %d %b %R";
          };

          media_player = {
            max_title_length = 100;
          };

          settings = {
            lock_cmd = "${lockCommand}";
            audio_sinks_more_cmd = "${lib.getExe pkgs.pavucontrol} -t 3";
            audio_sources_more_cmd = "${lib.getExe pkgs.pavucontrol} -t 4";
            wifi_more_cmd = "${lib.getExe' pkgs.networkmanagerapplet "nm-connection-editor"}";
            vpn_more_cmd = "${lib.getExe' pkgs.networkmanagerapplet "nm-connection-editor"}";
            bluetooth_more_cmd = "${lib.getExe' pkgs.blueman "blueman-manager"}";
          };

          appearance = {
            inherit (cfg) style;
            margin = {
              inherit (cfg.margin)
                top
                left
                right
                bottom
                ;
            };
          };
        }
        // lib.optionalAttrs (allCustomModules != [ ]) {
          CustomModule = allCustomModules;
        };
    };

    sops.secrets = mkIf (osConfig.khanelinix.security.sops.enable or false) {
      weather_config = {
        sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/weather_config.json";
      };
    };
  };
}
