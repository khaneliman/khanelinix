{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) types mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt mkOpt enabled;

  cfg = config.khanelinix.programs.graphical.wms.sway;
in
{
  options.khanelinix.programs.graphical.wms.sway = with types; {
    enable = mkBoolOpt false "Whether or not to enable Sway.";
    extraConfig = mkOpt str "" "Additional configuration for the Sway config file.";
    wallpaper = mkOpt (nullOr package) null "The wallpaper to display.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      display-managers = {
        sddm = {
          enable = true;
        };
      };

      programs = {
        graphical = {
          addons = {
            keyring = enabled;
            xdg-portal = enabled;
          };

          apps = {
            partitionmanager = enabled;
          };

          file-managers = {
            nautilus = enabled;
            thunar = enabled;
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
      package = pkgs.sway;
    };

    services.displayManager.sessionPackages = [ pkgs.sway ];
  };
}
