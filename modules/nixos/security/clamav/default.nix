{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.${namespace}.security.clamav;
in
{
  options.${namespace}.security.clamav = {
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
