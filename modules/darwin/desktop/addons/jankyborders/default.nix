{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.desktop.addons.jankyborders;
in
{
  options.khanelinix.desktop.addons.jankyborders = {
    enable =
      mkBoolOpt false "Whether to enable jankyborders in the desktop environment.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs.khanelinix; [
      jankyborders
    ];

    khanelinix.home.configFile = {
      "borders/bordersrc".source = ./bordersrc;
    };
  };
}
