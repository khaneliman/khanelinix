{
  config,
  inputs,
  system,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  inherit (inputs) nixpkgs-wayland;

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
        package = nixpkgs-wayland.packages.${system}.wshowkeys;
      };
    };
  };
}
