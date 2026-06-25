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
        # after auth, it stores the encrypted refresh token in tokenFile.
        "davmail.mode" = "O365DeviceCode";
        "davmail.oauth.persistToken" = true;
        "davmail.oauth.tokenFilePath" = tokenFile;
      };
    };

    home.activation.davmailState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${lib.getExe' pkgs.coreutils "mkdir"} -p ${lib.escapeShellArg (dirOf tokenFile)}
    '';
  };
}
