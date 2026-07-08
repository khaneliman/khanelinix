{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;

  cfg = config.khanelinix.theme.catppuccin;
in
{
  imports = [
    ./gtk.nix
    ./qt.nix
  ];

  options.khanelinix.theme.catppuccin = {
    enable = mkEnableOption "catppuccin theme for applications";

    accent = mkOption {
      type = types.enum [
        "rosewater"
        "flamingo"
        "pink"
        "mauve"
        "red"
        "maroon"
        "peach"
        "yellow"
        "green"
        "teal"
        "sky"
        "sapphire"
        "blue"
        "lavender"
      ];
      default = "blue";
      description = ''
        An optional theme accent.
      '';
    };

    flavor = mkOption {
      type = types.enum [
        "latte"
        "frappe"
        "macchiato"
        "mocha"
      ];
      default = "macchiato";
      description = ''
        An optional theme flavor.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.catppuccin.override {
        inherit (cfg) accent;
        variant = cfg.flavor;
      };
      description = "Catppuccin package configured with the selected accent and flavor.";
    };
  };

  config = mkMerge [
    # catppuccin/nix migration: pin the global toggle and disable auto-enrolling
    # every port so the deprecation warning stays silent on every system. The
    # actual catppuccin styling is applied through Home Manager.
    (lib.optionalAttrs (inputs ? catppuccin && inputs.catppuccin ? nixosModules) {
      catppuccin = {
        inherit (cfg) enable;
        autoEnable = false;
      };
    })

    (mkIf cfg.enable {
      khanelinix.theme.enable = true;
      khanelinix.theme.package = cfg.package;

      assertions = [
        {
          assertion = !config.khanelinix.theme.nord.enable;
          message = "Nord and Catppuccin themes cannot be enabled at the same time";
        }
        {
          assertion = !config.khanelinix.theme.tokyonight.enable;
          message = "Catppuccin and Tokyonight themes cannot be enabled at the same time";
        }
      ];
    })
  ];
}
