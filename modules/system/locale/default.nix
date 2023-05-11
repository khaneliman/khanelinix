{ options
, config
, pkgs
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.system.locale;
in
{
  options.khanelinix.system.locale = with types; {
    enable = mkBoolOpt false "Whether or not to manage locale settings.";
  };

  config = mkIf cfg.enable {
    environment.variables = {
      # Set locale archive variable in case it isn't being set properly
      LOCALE_ARCHIVE = "/run/current-system/sw/lib/locale/locale-archive";
    };

    i18n.defaultLocale = "en_US.UTF-8";

    console = {
      keyMap = mkForce "us";
      font = "Lat2-Terminus16";
    };
  };
}
