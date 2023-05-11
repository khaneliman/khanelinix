{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.appimage-run;
in {
  options.khanelinix.tools.appimage-run = with types; {
    enable = mkBoolOpt false "Whether or not to enable appimage-run.";
  };

  config = mkIf cfg.enable {
    khanelinix.home.configFile."wgetrc".text = "";

    environment.systemPackages = with pkgs; [
      appimage-run
    ];
  };
}
