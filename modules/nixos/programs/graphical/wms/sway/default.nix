{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.${namespace}) mkOpt enabled;

  cfg = config.${namespace}.programs.graphical.wms.sway;
in
{
  options.${namespace}.programs.graphical.wms.sway = with types; {
    enable = lib.mkEnableOption "Sway";
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
      package = pkgs.sway;
    };

    services.displayManager.sessionPackages = [ pkgs.sway ];
  };
}
