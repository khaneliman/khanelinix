{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.addons.looking-glass-client;
in
{
  options.khanelinix.programs.graphical.addons.looking-glass-client = {
    enable = lib.mkEnableOption "the Looking Glass client";
  };

  config = mkIf cfg.enable {
    programs.looking-glass-client = {
      enable = true;
      package = pkgs.looking-glass-client;

      settings = {
        input = {
          rawMouse = "yes";
          mouseSens = 6;
          # escapeKey = "";
        };

        spice = {
          enable = true;
          audio = true;
        };

        win = {
          autoResize = "yes";
          quickSplash = "yes";
        };
      };
    };
  };
}
