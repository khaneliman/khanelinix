{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;

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

  config = lib.mkMerge [
    (mkIf cfg.enable {
      assertions = [
        {
          assertion = isLinux;
          message = "Satty is only available on linux";
        }
      ];
    })
    (mkIf (cfg.enable && isLinux) {
      home.file."${lib.removePrefix "${config.home.homeDirectory}/" picturesDir}/screenshots/.keep".text =
        "";

      programs.satty = {
        # Satty documentation
        # See: https://github.com/gabm/satty
        enable = true;

        settings = {
          general = {
            copy-command = lib.getExe' pkgs.wl-clipboard "wl-copy";
            output-filename = "${picturesDir}/screenshots/satty-%Y-%m-%d_%H:%M:%S.png";
            save-after-copy = false;
            default-hide-toolbars = false;
          };

          font = {
            family = lib.mkDefault config.khanelinix.home.fonts.default;
            style = "Bold";
          };
        };
      };
    })
  ];
}
