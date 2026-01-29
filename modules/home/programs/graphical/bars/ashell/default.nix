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

  helpers = import ./helpers.nix {
    inherit
      config
      lib
      osConfig
      pkgs
      ;
  };

  customModules = import ./custom-modules.nix {
    inherit
      config
      lib
      pkgs
      osConfig
      helpers
      ;
  };
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
          enabledDmenuLaunchers =
            let
              inherit (config.khanelinix.programs.graphical) launchers;
            in
            lib.flatten [
              (lib.optional launchers.vicinae.enable "vicinae dmenu")
              (lib.optional launchers.anyrun.enable "anyrun --show-results-immediately true")
              (lib.optional launchers.walker.enable "walker --stream")
              (lib.optional launchers.sherlock.enable "sherlock")
              (lib.optional launchers.rofi.enable "rofi -dmenu")
            ];

          dmenuCommand = builtins.head enabledDmenuLaunchers;

          allCustomModules = [
            customModules.CustomGithub
            customModules.CustomNotifications
            customModules.CustomPowerMenu
            customModules.CustomWeather
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

          commonModules = {
            left = leftModules;
            center = [ ];
            right = rightModules;
          };

          fullSizeModules = {
            left = leftModules;
            center = [ "MediaPlayer" ];
            right = [ "Tray" ] ++ rightModules;
          };

          enabledAppLaunchers =
            let
              inherit (config.khanelinix.programs.graphical) launchers;
            in
            lib.flatten [
              (lib.optional launchers.vicinae.enable "vicinae open")
              (lib.optional launchers.anyrun.enable "anyrun")
              (lib.optional launchers.walker.enable "walker")
              (lib.optional launchers.sherlock.enable "sherlock")
              (lib.optional launchers.rofi.enable "rofi -show drun")
            ];
        in
        {
          log_level = "warn";
          outputs = "All";
          position = "Top";

          app_launcher_cmd = builtins.head enabledAppLaunchers;
          clipboard_cmd = "cliphist list | ${dmenuCommand} | cliphist decode | wl-copy";
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
              { Disk = "/"; }
              "Temperature"
            ];
            cpu = {
              warn_threshold = 50;
              alert_threshold = 75;
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
            lock_cmd = "${lib.getExe helpers.lockScript}";
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
        // lib.optionalAttrs (allCustomModules != [ ]) { CustomModule = allCustomModules; };
    };

    sops.secrets = mkIf (osConfig.khanelinix.security.sops.enable or false) {
      weather_config = {
        sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/weather_config.json";
      };
    };
  };
}
