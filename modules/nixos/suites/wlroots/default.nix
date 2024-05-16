{
  config,
  inputs,
  system,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  inherit (inputs) nixpkgs-wayland;

  cfg = config.khanelinix.suites.wlroots;
in
{
  options.khanelinix.suites.wlroots = {
    enable = mkBoolOpt false "Whether or not to enable common wlroots configuration.";
  };

  config = mkIf cfg.enable {
    programs = {
      nm-applet.enable = true;
      xwayland.enable = true;

      wshowkeys = {
        enable = true;
        package = nixpkgs-wayland.packages.${system}.wshowkeys;
      };
    };
  };
}
