{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.desktop;
in
{
  options.khanelinix.suites.desktop = {
    enable = mkBoolOpt false "Whether or not to enable common desktop configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      barrier
      bleachbit
      dropbox
      dupeguru
      filelight
      fontpreview
      gparted
      keepass
      pkgs.khanelinix.pocketcasts
    ];

    # TODO: what does this set that makes it default
    programs.firefox.enable = true;

    khanelinix = {
      programs = {
        graphical = {
          apps = {
            _1password = enabled;
          };

          wms = {
            hyprland = enabled;
          };
        };
      };
    };
  };
}
