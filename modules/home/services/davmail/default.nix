{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.services.davmail;
  tokenFile = "${config.xdg.stateHome}/davmail/oauth-tokens.properties";
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
        # after auth, it stores the refresh token encrypted with that password.
        # Every localhost client for the same account must use the same password.
        "davmail.authentication" = "O365DeviceCode";
        "davmail.mode" = "O365EWS";
        "davmail.oauth.persistToken" = true;
        "davmail.oauth.tokenFilePath" = tokenFile;
      };
    };

    home.activation.davmailState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${lib.getExe' pkgs.coreutils "install"} -d -m 0700 ${lib.escapeShellArg (dirOf tokenFile)}
    '';
  };
}
