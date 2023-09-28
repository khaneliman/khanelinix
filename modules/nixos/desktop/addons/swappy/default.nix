{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.desktop.addons.swappy;
in
{
  options.khanelinix.desktop.addons.swappy = {
    enable =
      mkBoolOpt false "Whether to enable Swappy in the desktop environment.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ swappy ];

    khanelinix.home = {
      configFile."swappy/config".source = ./config;
      file."Pictures/screenshots/.keep".text = "";
    };
  };
}
