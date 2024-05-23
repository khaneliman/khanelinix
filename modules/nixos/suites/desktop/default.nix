{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt enabled;

  cfg = config.${namespace}.suites.desktop;
in
{
  options.${namespace}.suites.desktop = {
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
      pkgs.${namespace}.pocketcasts
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
