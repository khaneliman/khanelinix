{
  config,
  lib,

  pkgs,
  ...
}:
let
  cfg = config.khanelinix.programs.graphical.launchers.vicinae;
in
{
  options.khanelinix.programs.graphical.launchers.vicinae = {
    enable = lib.mkEnableOption "vicinae in the desktop environment";
  };

  config = lib.mkIf cfg.enable {
    programs.vicinae = {
      enable = true;
      package = pkgs.vicinae;

      systemd = {
        enable = true;
      };

      # settings = {
      #   theme = {
      #     name = "catppuccin-macchiato";
      #   };
      # };
    };
  };
}
