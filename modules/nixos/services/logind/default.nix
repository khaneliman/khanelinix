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
      logind.settings.Login = {
        # Detached SSH sessions, including tmux, must survive logout.
        KillUserProcesses = lib.mkDefault false;
      };
    };
  };
}
