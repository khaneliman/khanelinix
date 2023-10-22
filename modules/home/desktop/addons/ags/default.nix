{ config
, inputs
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  inherit (inputs) ags;

  cfg = config.khanelinix.desktop.addons.ags;

in
{
  imports = [ ags.homeManagerModules.default ];

  options.khanelinix.desktop.addons.ags = {
    enable = mkBoolOpt false "Whether to enable ags.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      ydotool
      sassc
    ];

    programs.ags = {
      enable = true;
      configDir = ./config;
    };
  };
}
