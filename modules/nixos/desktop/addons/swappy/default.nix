{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.addons.swappy;
in {
  options.khanelinix.desktop.addons.swappy = with types; {
    enable =
      mkBoolOpt false "Whether to enable Swappy in the desktop environment.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [swappy];

    khanelinix.home.configFile."swappy/config".source = ./config;
    khanelinix.home.file."Pictures/screenshots/.keep".text = "";
  };
}
