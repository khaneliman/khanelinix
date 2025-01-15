{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.programs.graphical.addons.looking-glass-client;
in
{
  options.khanelinix.programs.graphical.addons.looking-glass-client = {
    enable = mkBoolOpt false "Whether or not to enable the Looking Glass client.";
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

    home.packages = with pkgs; [ obs-studio-plugins.looking-glass-obs ];
  };
}
