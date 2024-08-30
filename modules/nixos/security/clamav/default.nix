{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.security.clamav;
in
{
  options.${namespace}.security.clamav = {
    enable = lib.mkEnableOption "default clamav configuration";
  };

  config = lib.mkIf cfg.enable {
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
