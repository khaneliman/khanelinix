{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.programs.graphical.addons.wofi;
in
{
  options.khanelinix.programs.graphical.addons.wofi = {
    enable = mkBoolOpt false "Whether to enable the Wofi in the desktop environment.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      wofi
      wofi-emoji
    ];

    xdg.configFile = {
      "wofi/config".source = ./config;
      "wofi/style.css".source = ./style.css;
    };
  };
}
