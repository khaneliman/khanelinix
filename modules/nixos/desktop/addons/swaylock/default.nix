{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.addons.swaylock;
in {
  options.khanelinix.desktop.addons.swaylock = with types; {
    enable =
      mkBoolOpt false "Whether to enable swaylock in the desktop environment.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [swaylock-effects];
    security.pam.services.swaylock = {};
  };
}
