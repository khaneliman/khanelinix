{
  config,
  lib,

  ...
}:
let

  cfg = config.khanelinix.security.pam;
in
{
  options.khanelinix.security.pam = {
    enable = lib.mkEnableOption "pam";
  };

  config = lib.mkIf cfg.enable {
    security.pam = {
      sshAgentAuth.enable = true;
      services = {
        # Only enable gnome-keyring for display manager login to avoid conflicts
        sddm = lib.mkIf config.services.displayManager.sddm.enable {
          enableGnomeKeyring = true;
        };
      };
      loginLimits = [
        {
          domain = "*";
          item = "nofile";
          type = "-";
          value = "524288";
        }
      ];
    };
  };
}
