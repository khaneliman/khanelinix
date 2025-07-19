{
  lib,
  pkgs,
  config,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.services.ddccontrol;
in
{
  options.khanelinix.services.ddccontrol = {
    enable = lib.mkEnableOption "ddccontrol";
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
