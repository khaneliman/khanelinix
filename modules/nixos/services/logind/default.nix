{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.${namespace}.services.logind;
in
{
  options.${namespace}.services.logind = {
    enable = mkEnableOption "logind";
  };

  config = mkIf cfg.enable {
    services = {
      logind = {
        killUserProcesses = true;
      };
    };
  };
}
