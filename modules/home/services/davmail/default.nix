{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.${namespace}.services.davmail;
in
{
  options.${namespace}.services.davmail = {
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
