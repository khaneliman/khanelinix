{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.addons.flameshot;

  picturesDir =
    if config.xdg.userDirs.enable then
      config.xdg.userDirs.pictures
    else
      "${config.home.homeDirectory}/Pictures";
in
{
  options.khanelinix.programs.graphical.addons.flameshot = {
    enable = lib.mkEnableOption "flameshot";
  };

  config = mkIf cfg.enable {
    home.file."${lib.removePrefix "${config.home.homeDirectory}/" picturesDir}/screenshots/.keep".text =
      "";

    services.flameshot = {
      enable = true;
    };
  };
}
