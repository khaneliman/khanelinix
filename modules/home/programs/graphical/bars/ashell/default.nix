{
  config,
  lib,
  namespace,
  osConfig ? { },
  pkgs,
  ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkOpt;

  cfg = config.${namespace}.programs.graphical.bars.ashell;
in
{
  options.${namespace}.programs.graphical.bars.ashell = {
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
            ${lib.optionalString (osConfig.${namespace}.security.sops.enable or false) ''
              ${lib.getExe pkgs.gh} auth login --with-token < ${config.sops.secrets."github/access-token".path}
            ''}

            COUNT="$(${lib.getExe pkgs.gh} api notifications --jq 'length' 2>/dev/null || echo "0")"
            if [ "$COUNT" -gt 0 ]; then
              echo "{\"text\": \"$COUNT\", \"alt\": \"notification\"}"
            else
              echo "{\"text\": \"0\", \"alt\": \"none\"}"
            fi
          '';

          # Weather helper
          weatherHelper = pkgs.writeShellScriptBin "ashell-weather-helper" ''
            if [ -f "${config.home.homeDirectory}/weather_config.json" ]; then
              WEATHER=$(${lib.getExe pkgs.curl} -s "$(cat ${config.home.homeDirectory}/weather_config.json | ${lib.getExe pkgs.jq} -r .url)" | \
              ${lib.getExe pkgs.jq} -r '.current.condition.text + " " + (.current.temp_c | tostring) + "°C"' 2>/dev/null || echo "Weather N/A")
              echo "{\"text\": \"$WEATHER\", \"alt\": \"weather\"}"
            else
              echo "{\"text\": \"Weather N/A\", \"alt\": \"none\"}"
            fi
          '';

          # Default custom modules
          defaultCustomModules = [
            {
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
            }
            {
              name = "CustomGithub";
              icon = "󰊤";
              command = "${lib.getExe' pkgs.xdg-utils "xdg-open"} https://github.com/notifications";
              listen_cmd = "${lib.getExe githubHelper}";
              icons = {
                "notification" = "󰊤";
                "none" = "󰊤";
              };
              alert = ".*notification";
            }
            {
              name = "CustomWeather";
              icon = "󰖕";
              command = "${lib.getExe' pkgs.xdg-utils "xdg-open"} https://weather.com";
              listen_cmd = "${lib.getExe weatherHelper}";
              icons = {
                "weather" = "󰖕";
                "none" = "󰖕";
              };
            }
          ];

          # All custom modules (default + user-defined)
          allCustomModules = defaultCustomModules ++ cfg.customModules;

          # Configuration for different bar sizes
          commonModules = {
            left = [ "Workspaces" ];
            center = [ "WindowTitle" ];
            right =
              [ "SystemInfo" ]
              ++ (builtins.map (mod: mod.name) allCustomModules)
              ++ [
                [
                  "Clock"
                  "Privacy"
                  "Settings"
                ]
              ];
          };

          fullSizeModules = {
            left = [ "Workspaces" ];
            center = [ "WindowTitle" ];
            right =
              [
                "Tray"
                "SystemInfo"
              ]
              ++ (builtins.map (mod: mod.name) allCustomModules)
              ++ [
                [
                  "Clock"
                  "Privacy"
                  "Settings"
                ]
              ];
          };
        in
        {
          log_level = "warn";
          outputs = "All";
          position = "Top";

          app_launcher_cmd = "~/.config/rofi/launcher.sh";
          clipboard_cmd = "cliphist-rofi-img | wl-copy";
          truncate_title_after_length = 150;

          modules =
            if cfg.fullSizeOutputs != [ ] || cfg.condensedOutputs != [ ] then
              fullSizeModules
            else
              commonModules;

          workspaces = {
            visibility_mode = "MonitorSpecific";
            enable_workspace_filling = false;
          };

          system = {
            indicators = [
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
            lock_cmd = "${lib.getExe config.programs.hyprlock.package}";
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

    sops.secrets = mkIf (osConfig.${namespace}.security.sops.enable or false) {
      weather_config = {
        sopsFile = lib.snowfall.fs.get-file "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/weather_config.json";
      };
    };
  };
}
