{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.services.logind;
in
{
  options.khanelinix.services.logind = {
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
