{
  config,
  lib,

  ...
}:
let
  cfg = config.khanelinix.security.sudo;
in
{
  options.khanelinix.security.sudo = {
    enable = lib.mkEnableOption "sudo support";
  };

  config = lib.mkIf cfg.enable {
    security = {
      pam.services = {
        sudo_local = {
          reattach = true;
          touchIdAuth = true;
        };
      };
      sudo.extraConfig = "Defaults    timestamp_timeout=5";
    };
  };
}
