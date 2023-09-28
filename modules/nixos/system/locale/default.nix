{ config
, lib
, ...
}:
let
  inherit (lib) mkIf mkForce;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.system.locale;
in
{
  options.khanelinix.system.locale = {
    enable = mkBoolOpt false "Whether or not to manage locale settings.";
  };

  config = mkIf cfg.enable {
    environment.variables = {
      # Set locale archive variable in case it isn't being set properly
      LOCALE_ARCHIVE = "/run/current-system/sw/lib/locale/locale-archive";
    };

    i18n.defaultLocale = "en_US.UTF-8";

    console = {
      font = "Lat2-Terminus16";
      keyMap = mkForce "us";
    };
  };
}
