{ config, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.security.clamav;
in
{
  options.khanelinix.security.clamav = {
    enable = mkEnableOption "default clamav configuration";
  };

  config = mkIf cfg.enable {
    services.clamav = {
      daemon = {
        enable = true;
      };

      fangfrisch = {
        enable = true;
      };

      scanner = {
        enable = true;
      };

      updater = {
        enable = true;
      };
    };
  };
}
