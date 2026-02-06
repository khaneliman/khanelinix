{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
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

  config = mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = !config.khanelinix.theme.nord.enable;
            message = "Nord and Catppuccin themes cannot be enabled at the same time";
          }
          {
            assertion = !config.khanelinix.theme.catppuccin.enable;
            message = "Nord and Catppuccin themes cannot be enabled at the same time";
          }
        ];
      }
    ]
  );
}
