{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.tools.qmk;
in
{
  options.${namespace}.tools.qmk = {
    enable = mkBoolOpt false "Whether or not to enable QMK";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ qmk ];

    services.udev.packages = with pkgs; [ qmk-udev-rules ];
  };
}
