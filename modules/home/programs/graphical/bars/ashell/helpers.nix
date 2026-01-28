{
  config,
  lib,
  osConfig ? { },
  pkgs,
  ...
}:
let
  inherit (config.khanelinix.programs.graphical) launchers;

  # Detect enabled dmenu launchers
  enabledDmenuLaunchers = lib.flatten [
    (lib.optional launchers.vicinae.enable "vicinae dmenu")
    (lib.optional launchers.anyrun.enable "anyrun --show-results-immediately true")
    (lib.optional launchers.walker.enable "walker --stream")
    (lib.optional launchers.sherlock.enable "sherlock")
    (lib.optional launchers.rofi.enable "rofi -dmenu")
  ];

  dmenuCommand = builtins.head enabledDmenuLaunchers;
in
{
  # Screen locker script - detects available locker at runtime
  lockScript = pkgs.writeShellScriptBin "ashell-lock" ''
    # Try to detect and use available screen locker
    if command -v ${lib.getExe config.programs.hyprlock.package} &> /dev/null; then
      ${lib.getExe config.programs.hyprlock.package}
    elif command -v ${lib.getExe config.programs.swaylock.package} &> /dev/null; then
      ${lib.getExe config.programs.swaylock.package}
    else
      loginctl lock-session
    fi
  '';

  # Logout script - detects running WM at runtime
  logoutScript = pkgs.writeShellScriptBin "ashell-logout" ''
    # Detect running window manager and use appropriate exit command
    case "$XDG_CURRENT_DESKTOP" in
      Hyprland)
        ${lib.getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch exit
        ;;
      niri)
        ${lib.getExe' config.programs.niri.package "niri"} msg action quit
        ;;
      sway)
        ${lib.getExe' config.wayland.windowManager.sway.package "swaymsg"} exit
        ;;
      *)
        systemctl --user exit
        ;;
    esac
  '';

  # Power menu with dmenu integration
  powerMenuHelper = pkgs.writeShellScriptBin "ashell-power-menu" ''
    # Create power menu options
    POWER_OPTIONS="🔒 Lock
    🌙 Sleep
    🔄 Restart
    ⏻ Shutdown
    🚪 Logout"

    # Use dmenu to display power options
    SELECTED=$(echo "$POWER_OPTIONS" | ${dmenuCommand} -p "Power Menu")

    case "$SELECTED" in
      "🔒 Lock")
        ${
          lib.getExe
            (import ./helpers.nix {
              inherit
                config
                lib
                osConfig
                pkgs
                ;
            }).lockScript
        } &
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
        ${lib.getExe
          (import ./helpers.nix {
            inherit
              config
              lib
              osConfig
              pkgs
              ;
          }).logoutScript
        }
        ;;
    esac
  '';

  # Notification helper for swaync integration
  notificationHelper = pkgs.writeShellScriptBin "ashell-notification-helper" ''
    if command -v ${lib.getExe' config.services.swaync.package "swaync-client"} &> /dev/null; then
      ${lib.getExe' config.services.swaync.package "swaync-client"} -swb
    else
      echo '{"text": "0", "alt": "none"}'
    fi
  '';

  # GitHub notifications helper - runs continuously
  githubHelper = pkgs.writeShellScriptBin "ashell-github-helper" ''
    ${lib.optionalString (osConfig.khanelinix.security.sops.enable or false) ''
      ${lib.getExe pkgs.gh} auth login --with-token < ${config.sops.secrets."github/access-token".path}
    ''}

    while true; do
      COUNT="$(${lib.getExe pkgs.gh} api notifications --jq 'length' 2>/dev/null || echo "0")"
      if [ "$COUNT" -gt 0 ]; then
        echo "{\"text\": \"$COUNT\", \"alt\": \"notification\"}"
      else
        echo "{\"text\": \"0\", \"alt\": \"none\"}"
      fi
      sleep 300  # Update every 5 minutes
    done
  '';

  # GitHub notifications interactive menu
  githubMenuHelper = pkgs.writeShellScriptBin "ashell-github-menu" ''
    ${lib.optionalString (osConfig.khanelinix.security.sops.enable or false) ''
      ${lib.getExe pkgs.gh} auth login --with-token < ${config.sops.secrets."github/access-token".path}
    ''}

    # Fetch notifications as JSON
    NOTIFICATIONS_JSON=$(${lib.getExe pkgs.gh} api notifications 2>/dev/null)

    if [ -z "$NOTIFICATIONS_JSON" ] || [ "$NOTIFICATIONS_JSON" = "[]" ]; then
      echo "No notifications" | ${dmenuCommand} -p "GitHub Notifications"
      exit 0
    fi

    # Format for dmenu: "repo: title"
    SELECTED=$(echo "$NOTIFICATIONS_JSON" | ${lib.getExe pkgs.jq} -r '.[] | "\(.repository.full_name): \(.subject.title)"' | ${dmenuCommand} -p "GitHub Notifications")

    if [ -n "$SELECTED" ]; then
      # Find the matching notification and get its URL
      REPO=$(echo "$SELECTED" | cut -d: -f1)
      TITLE=$(echo "$SELECTED" | cut -d: -f2- | ${lib.getExe pkgs.gnused} 's/^ //')
      
      # Get the web URL from the notification
      URL=$(echo "$NOTIFICATIONS_JSON" | ${lib.getExe pkgs.jq} -r --arg repo "$REPO" --arg title "$TITLE" '.[] | select(.repository.full_name == $repo and .subject.title == $title) | .subject.url')
      
      # Convert API URL to web URL
      WEB_URL=$(echo "$URL" | ${lib.getExe pkgs.gnused} -E 's|api\.github\.com/repos/|github.com/|; s|/pulls/|/pull/|')
      
      ${lib.getExe' pkgs.xdg-utils "xdg-open"} "$WEB_URL"
    fi
  '';

  # Detailed weather popup with dmenu
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

    # Show in dmenu
    echo "$WEATHER_DETAIL" | ${dmenuCommand} -p "Weather Details"
  '';
}
