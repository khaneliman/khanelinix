{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.graphical.launchers.rofi;
in
{
  options.${namespace}.programs.graphical.launchers.rofi = {
    enable = mkBoolOpt false "Whether to enable Rofi in the desktop environment.";
  };

  config = mkIf cfg.enable {

    home.packages = with pkgs; [ wtype ];

    programs.rofi = {
      enable = true;
      # NOTE: rofi-wayland doesn't support plugins with HM module. But... non wayland sucks... sooo
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
        source = lib.cleanSourceWith { src = lib.cleanSource ./config/.; };

        recursive = true;
      };
    };
  };
}
