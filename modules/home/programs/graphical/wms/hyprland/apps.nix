{
  config,
  lib,

  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf getExe;

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

    wayland.windowManager.hyprland = {
      settings = {
        exec-once =
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
                  in
                  if (osConfig.programs.uwsm.enable or false) then
                    "uwsm app ${if slice == null then "" else "-s ${slice}"} -- ${cmd}"
                  else
                    cmd;

                # Single-argument version: mkStartCommand "command"
                withoutArgs = cmd: if (osConfig.programs.uwsm.enable or false) then "uwsm app -- ${cmd}" else cmd;
              in
              args: if lib.isString args then withoutArgs args else withArgs args;
          in
          # ░█▀█░█▀█░█▀█░░░█▀▀░▀█▀░█▀█░█▀▄░▀█▀░█░█░█▀█
          # ░█▀█░█▀▀░█▀▀░░░▀▀█░░█░░█▀█░█▀▄░░█░░█░█░█▀▀
          # ░▀░▀░▀░░░▀░░░░░▀▀▀░░▀░░▀░▀░▀░▀░░▀░░▀▀▀░▀░░

          # Regular applications (app-graphical.slice) - actively used, interactive
          (
            lib.optionals (osConfig.programs.uwsm.enable or false) [ "uwsm finalize" ]
            ++ lib.optionals config.programs.firefox.enable [
              (mkStartCommand "${getExe config.programs.firefox.package}")
            ]
            # Background applications (background-graphical.slice) - communication clients, often idle
            # NOTE: rarely use anymore
            # ++ lib.optionals config.programs.vesktop.enable [
            #   (mkStartCommand { slice = "b"; } "${getExe config.programs.vesktop.package}")
            # ]
            ++ lib.optionals (osConfig.programs.steam.enable or false) [
              (mkStartCommand { slice = "b"; } "steam")
            ]
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
      };
    };
  };
}
