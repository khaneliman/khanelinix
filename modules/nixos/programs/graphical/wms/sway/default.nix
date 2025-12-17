{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.khanelinix) mkOpt enabled;

  cfg = config.khanelinix.programs.graphical.wms.sway;
in
{
  options.khanelinix.programs.graphical.wms.sway = with types; {
    enable = lib.mkEnableOption "Sway";
    withUWSM = lib.mkEnableOption "Universal Wayland Session Manager integration";
    extraConfig = mkOpt str "" "Additional configuration for the Sway config file.";
    wallpaper = mkOpt (nullOr package) null "The wallpaper to display.";
  };

  config = mkIf cfg.enable {
    khanelinix.home = {
      configFile = lib.optionalAttrs cfg.withUWSM {
        "uwsm/env-sway".text = /* Bash */ ''
          export XDG_CURRENT_DESKTOP=sway
          export XDG_SESSION_TYPE=wayland
          export XDG_SESSION_DESKTOP=sway
        '';
      };
    };
    khanelinix = {
      display-managers = {
        sddm = {
          enable = true;
        };
      };

      programs = {
        graphical = {
          apps = {
            gnome-disks = enabled;
            partitionmanager = enabled;
          };

          file-managers = {
            nautilus = enabled;
          };
        };
      };

      security = {
        keyring = enabled;
        polkit = enabled;
      };

      suites = {
        wlroots = enabled;
      };

      theme = {
        gtk = enabled;
        qt = enabled;
      };
    };

    programs.sway = {
      enable = true;
      package = pkgs.swayfx;
    };

    services.displayManager.sessionPackages = [ pkgs.swayfx ];

    # UWSM integration
    programs.uwsm = lib.mkIf cfg.withUWSM {
      enable = true;
      waylandCompositors = {
        sway = {
          prettyName = "Sway";
          comment = "Sway compositor managed by UWSM";
          binPath = "/run/current-system/sw/bin/sway";
        };
      };
    };
  };
}
