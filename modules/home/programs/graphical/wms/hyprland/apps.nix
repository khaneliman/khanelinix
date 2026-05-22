{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf getExe getExe';

  cfg = config.khanelinix.programs.graphical.wms.hyprland;
in
{
  config = mkIf cfg.enable {
    # NOTE: xdgautostart method of providing a desktop item to start
    # xdg.configFile = {
    #   "autostart/OpenRGB.desktop".source = pkgs.makeDesktopItem {
    #     name = "OpenRGB";
    #     desktopName = "openrgb";
    #     genericName = "Control RGB lighting.";
    #     exec = "openrgb --startminimized --profile default";
    #     icon = "OpenRGB";
    #     type = "Application";
    #     categories = [ "Utility" ];
    #     terminal = false;
    #   };
    # };

    khanelinix.programs.graphical.wms.hyprland.startupCommands =
      let
        # Helper function to conditionally prefix with uwsm
        # Usage: mkStartCommand "command" or mkStartCommand { slice = "b"; } "command"
        mkStartCommand =
          let
            # Two-argument version: mkStartCommand { slice = "b"; } "command"
            withArgs =
              args: cmd:
              let
                slice = args.slice or null;
                timeoutStopSec =
                  args.timeoutStopSec or {
                    a = "15s";
                    b = "10s";
                    s = "30s";
                  }
                  .${if slice == null then "a" else slice} or "15s";
              in
              if (osConfig.programs.uwsm.enable or false) then
                "uwsm app ${
                  lib.optionalString (slice != null) "-s ${slice} "
                }-p TimeoutStopSec=${timeoutStopSec} -- ${cmd}"
              else
                cmd;

            # Single-argument version: mkStartCommand "command"
            withoutArgs =
              cmd:
              if (osConfig.programs.uwsm.enable or false) then
                "uwsm app -p TimeoutStopSec=15s -- ${cmd}"
              else
                cmd;
          in
          args: if lib.isString args then withoutArgs args else withArgs args;
        appCommands =
          # Regular applications (app-graphical.slice) - actively used, interactive
          (
            lib.optionals config.programs.firefox.enable [
              (mkStartCommand "${getExe config.programs.firefox.package}")
            ]
            # Background applications (background-graphical.slice) - communication clients, often idle
            # NOTE: rarely use anymore
            # ++ lib.optionals config.programs.vesktop.enable [
            #   (mkStartCommand { slice = "b"; } "${getExe config.programs.vesktop.package}")
            # ]
            ++ lib.optionals config.khanelinix.suites.social.enable [
              (mkStartCommand { slice = "b"; } "element-desktop")
            ]
            ++ lib.optionals config.khanelinix.suites.business.enable [
              (mkStartCommand { slice = "b"; } "teams-for-linux")
              (mkStartCommand { slice = "b"; } "thunderbird")
            ]
            # System services and utilities (background-graphical.slice)
            ++ lib.optionals (osConfig.services.hardware.openrgb.enable or false) [
              (mkStartCommand { slice = "b"; } "openrgb -c blue")
            ]
            ++ lib.optionals (osConfig.programs._1password-gui.enable or false) [
              (mkStartCommand { slice = "b"; } "1password --silent")
            ]
            ++ lib.optionals (osConfig.networking.networkmanager.enable or false) [
              (mkStartCommand { slice = "b"; } "nm-applet")
            ]
          )
          ++ [
            # Always start these utilities (no UWSM wrapping needed)
            (mkStartCommand { slice = "b"; } "wayvnc $(tailscale ip --4)")
          ];
      in
      lib.mkBefore (
        if (osConfig.programs.uwsm.enable or false) then [ "uwsm finalize" ] ++ appCommands else appCommands
      );

    systemd.user.services.hyprland-start-steam = mkIf (osConfig.programs.steam.enable or false) {
      Unit = {
        Description = "Start Steam after Hyprland session";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        Type = "oneshot";
        ExecStartPre = "${getExe' pkgs.coreutils "sleep"} 5";
        ExecStart =
          if (osConfig.programs.uwsm.enable or false) then
            "${getExe pkgs.uwsm} app -s b -a steam -p TimeoutStopSec=10s -- steam"
          else
            "steam";
      };
    };
  };
}
