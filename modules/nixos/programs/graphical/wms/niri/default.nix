{
  config,
  options,
  lib,
  pkgs,
  inputs,
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
  hasNiri = inputs ? niri;
in
{
  options.khanelinix.programs.graphical.wms.niri = with types; {
    enable = lib.mkEnableOption "Niri";
    package = mkOption {
      type = package;
      default = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-stable;
      defaultText = literalExpression "inputs.niri.packages.\${pkgs.stdenv.hostPlatform.system}.niri-stable";
      description = "Niri package (stable or unstable).";
    };
  };

  config = lib.mkMerge [
    (lib.optionalAttrs hasNiri {
      home-manager.sharedModules = [
        inputs.niri.homeModules.config
        { programs.niri.package = lib.mkForce cfg.package; }
      ]
      ++ lib.optionals (options ? stylix) [ inputs.niri.homeModules.stylix ];
    })

    (mkIf cfg.enable (
      lib.mkMerge [
        (lib.optionalAttrs hasNiri {
          nix.settings = {
            substituters = [ "https://niri.cachix.org" ];
            trusted-public-keys = [ "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=" ];
          };

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
    ))
  ];
}
