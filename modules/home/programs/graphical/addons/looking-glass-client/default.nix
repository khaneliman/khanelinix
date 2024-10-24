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

  cfg = config.${namespace}.programs.graphical.addons.looking-glass-client;
in
{
  options.${namespace}.programs.graphical.addons.looking-glass-client = {
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
