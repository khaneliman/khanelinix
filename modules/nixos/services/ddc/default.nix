{
  lib,
  pkgs,
  config,
  khanelinix-lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt;

  cfg = config.khanelinix.services.ddccontrol;
in
{
  options.khanelinix.services.ddccontrol = {
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
