{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.ddccontrol;
in
{
  options.${namespace}.services.ddccontrol = {
    enable = mkBoolOpt false "Whether or not to configure ddccontrol";
  };

  config = mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      ddcui
      ddcutil
    ];

    services.ddccontrol = {
      enable = true;
    };
  };
}
