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
        "davmail.mode" = "O365Interactive";
      };
    };
  };
}
