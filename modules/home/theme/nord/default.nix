{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkDefault
    mkIf
    mkOption
    types
    ;

  cfg = config.khanelinix.theme.nord;
in
{
  imports = [
    ./apps.nix
    ./gtk.nix
    ./oh-my-posh.nix
    ./qt.nix
  ];

  options.khanelinix.theme.nord = {
    enable = mkEnableOption "Nord theme for applications";

    variant = mkOption {
      type = types.enum [
        "default"
        "darker"
        "bluish"
        "polar"
      ];
      default = "default";
      description = "Nordic theme variant to use for GTK and Qt.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.khanelinix.theme.catppuccin.enable;
        message = "Nord and Catppuccin themes cannot be enabled at the same time";
      }
    ];

    khanelinix.theme = {
      wallpaper = {
        theme = mkDefault "nord";
        primary = mkDefault "arctic-landscape.png";
        secondary = mkDefault "Abstract-Nord.png";
        lock = mkDefault "Abstract-Nord.png";
        list = mkDefault [
          "Abstract-Nord.png"
          "BirdNord.png"
          "Minimal-Nord.png"
          "arctic-landscape.png"
          "chemical_nord.png"
          "ign-0001.png"
          "ign-0011.png"
          "nixos.png"
        ];
      };
      stylix = {
        enable = true;
        theme = "nord";

        cursor = {
          name = "Nordzy-cursors";
          package = pkgs.nordzy-cursor-theme;
          size = 32;
        };

        icon = {
          name = "Nordzy-dark";
          package = pkgs.nordzy-icon-theme;
        };
      };
    };

    stylix.image = lib.khanelinix.theme.wallpaperPath {
      inherit config pkgs;
      name = config.khanelinix.theme.wallpaper.primary;
    };
  };
}
