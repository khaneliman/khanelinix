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

      # NOTE: https://davmail.sourceforge.net/serversetup.html
      settings = {
        # FIXME: doesn't work with interactive
        "davmail.mode" = "O365Manual";
        "davmail.url" = "https://outlook.office365.com";
      };
    };
  };
}
