{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.services.davmail;
in
{
  options.khanelinix.services.davmail = {
    enable = mkEnableOption "davmail";
  };

  config = mkIf cfg.enable {
    services.davmail = {
      enable = true;
      imitateOutlook = true;

      # NOTE: https://davmail.sourceforge.net/serversetup.html
      settings = {
        "davmail.disableGuiNotifications" = true;
        # Thunderbird supplies a saved local password. DavMail prints the
        # Microsoft device login URL/code to `journalctl --user -u davmail.service -f`;
        # after auth, it stores the refresh token in ~/.local/state/davmail-tokens.
        "davmail.mode" = "O365DeviceCode";
      };
    };
  };
}
