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
    khanelinix.theme.catppuccin.enable = lib.mkForce false;

    khanelinix.theme.stylix = {
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
}
