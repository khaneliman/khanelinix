{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

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

    # Shottr owns the managed macOS capture shortcut.
    launchd.agents.flameshot.enable = lib.mkIf isDarwin (lib.mkForce false);

    services.flameshot = {
      # Flameshot documentation
      # See: https://flameshot.org/docs/
      enable = true;

      settings.General = {
        filenamePattern = "flameshot-%Y-%m-%d_%H-%M-%S";
        savePath = "${picturesDir}/screenshots";
        savePathFixed = true;
        showStartupLaunchMessage = false;
      };
    };
  };
}
