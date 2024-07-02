{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.suites.wlroots;
in
{
  options.${namespace}.suites.wlroots = {
    enable = mkBoolOpt false "Whether or not to enable common wlroots configuration.";
  };

  config = mkIf cfg.enable {
    programs = {
      nm-applet.enable = true;
      xwayland.enable = true;

      wshowkeys = {
        enable = true;
        package = pkgs.wshowkeys;
      };
    };
  };
}
