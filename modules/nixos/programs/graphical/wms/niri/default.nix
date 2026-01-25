{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib)
    mkBefore
    mkDefault
    mkIf
    types
    ;
  inherit (lib.khanelinix) enabled mkOpt;

  cfg = config.khanelinix.programs.graphical.wms.niri;
  hasNiri = inputs ? niri;
in
{
  imports = lib.optionals hasNiri [ inputs.niri.nixosModules.niri ];

  options.khanelinix.programs.graphical.wms.niri = with types; {
    enable = lib.mkEnableOption "Niri";
    package = mkOpt package pkgs.niri-stable "Niri package (stable or unstable).";
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      (lib.optionalAttrs hasNiri {
        niri-flake.cache.enable = mkDefault true;

        nixpkgs.overlays = mkBefore [ inputs.niri.overlays.niri ];

        programs.niri = {
          enable = true;
          inherit (cfg) package;
        };
      })

      {
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
      }
    ]
  );
}
