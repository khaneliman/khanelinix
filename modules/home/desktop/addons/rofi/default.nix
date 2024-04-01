{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.desktop.addons.rofi;
in
{
  options.khanelinix.desktop.addons.rofi = {
    enable =
      mkBoolOpt false "Whether to enable Rofi in the desktop environment.";
  };

  config = mkIf cfg.enable {

    home.packages = with pkgs; [
      wtype
    ];

    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;

      font = "MonaspiceNe Nerd Font 14";
      location = "center";
      theme = "catppuccin";

      pass = {
        enable = true;
        package = pkgs.rofi-pass-wayland;
      };

      plugins = with pkgs; [
        rofi-calc
        rofi-emoji
        rofi-top
      ];
    };

    xdg.configFile = {
      "rofi" = {
        source = lib.cleanSourceWith {
          src = lib.cleanSource ./config/.;
        };

        recursive = true;
      };
    };
  };
}
