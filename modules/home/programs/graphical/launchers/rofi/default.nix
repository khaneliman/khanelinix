{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.launchers.rofi;
in
{
  options.khanelinix.programs.graphical.launchers.rofi = {
    enable = lib.mkEnableOption "Rofi in the desktop environment";
  };

  config = mkIf cfg.enable {

    home.packages = with pkgs; [ wtype ];

    programs.rofi = {
      enable = true;
      # NOTE: rofi-wayland doesn't support plugins with HM module. But... non wayland sucks... sooo
      package = pkgs.rofi-wayland;

      font = "MonaspaceNeon NF 14";
      location = "center";
      theme =
        if config.khanelinix.theme.catppuccin.enable then
          "catppuccin"
        else if config.khanelinix.theme.tokyonight.enable then
          "tokyonight"
        else
          "catppuccin";

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
        source = lib.cleanSourceWith { src = lib.cleanSource ./config/.; };

        recursive = true;
      };
    };
  };
}
