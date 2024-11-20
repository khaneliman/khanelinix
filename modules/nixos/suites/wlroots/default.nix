{
  config,
  lib,

  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.khanelinix) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.wlroots;
in
{
  options.khanelinix.suites.wlroots = {
    enable = mkBoolOpt false "Whether or not to enable common wlroots configuration.";
  };

  config = mkIf cfg.enable {

    khanelinix = {
      services = {
        seatd = mkDefault enabled;
      };
    };
    programs = {
      nm-applet.enable = mkDefault true;
      xwayland.enable = mkDefault true;

      wshowkeys = {
        enable = mkDefault true;
        package = pkgs.wshowkeys;
      };
    };
  };
}
