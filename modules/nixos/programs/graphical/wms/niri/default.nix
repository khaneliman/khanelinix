{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkIf
    mkOption
    types
    ;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.programs.graphical.wms.niri;
in
{
  options.khanelinix.programs.graphical.wms.niri = with types; {
    enable = lib.mkEnableOption "Niri";
    package = mkOption {
      type = package;
      default = pkgs.niri;
      defaultText = literalExpression "pkgs.niri";
      description = "Niri package to install.";
    };
  };

  config = mkIf cfg.enable {
    programs.niri = {
      enable = true;
      inherit (cfg) package;
    };

    khanelinix = {
      display-managers.sddm.enable = true;

      home = {
        configFile = lib.optionalAttrs config.programs.uwsm.enable {
          "uwsm/env-niri".text = /* Bash */ ''
            export XDG_CURRENT_DESKTOP=niri
            export XDG_SESSION_TYPE=wayland
            export XDG_SESSION_DESKTOP=niri
          '';
        };
      };

      programs.graphical = {
        apps = {
          gnome-disks = enabled;
          partitionmanager = enabled;
        };

        file-managers = {
          nautilus = enabled;
        };
      };

      security = {
        keyring = enabled;
        polkit = enabled;
      };

      suites.wlroots = enabled;

      theme = {
        gtk = enabled;
        qt = enabled;
      };
    };
  };
}
