{
  config,
  lib,
  pkgs,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.addons.satty;

  picturesDir =
    if config.xdg.userDirs.enable then
      config.xdg.userDirs.pictures
    else
      "${config.home.homeDirectory}/Pictures";
in
{
  options.khanelinix.programs.graphical.addons.satty = {
    enable = lib.mkEnableOption "satty";
  };

  config = mkIf cfg.enable {
    home.file."${lib.removePrefix "${config.home.homeDirectory}/" picturesDir}/screenshots/.keep".text =
      "";

    programs.satty = {
      enable = true;

      settings = {
        general = {
          copy-command = lib.getExe' pkgs.wl-clipboard "wl-copy";
          output-filename = "${picturesDir}/screenshots/satty-%Y-%m-%d_%H:%M:%S.png";
          save-after-copy = false;
          default-hide-toolbars = false;
        };

        font = {
          family = lib.mkDefault (osConfig.khanelinix.system.fonts.default or "MonaspaceNeon NF");
          style = "Bold";
        };
      };
    };
  };
}
