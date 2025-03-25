{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.${namespace}.services.davmail;
in
{
  options.${namespace}.services.davmail = {
    enable = mkEnableOption "davmail";
  };

  config = mkIf cfg.enable {
    services.davmail = {
      enable = true;
    };
  };
}
