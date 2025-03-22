{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkForce;

  cfg = config.${namespace}.system.locale;
in
{
  options.${namespace}.system.locale = {
    enable = lib.mkEnableOption " manage locale settings";
  };

  config = mkIf cfg.enable {
    console = {
      font = "Lat2-Terminus16";
      keyMap = mkForce "us";
    };

    environment.variables = {
      LOCALE_ARCHIVE = "/run/current-system/sw/lib/locale/locale-archive";
    };

    i18n = {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = config.i18n.defaultLocale;
        LC_IDENTIFICATION = config.i18n.defaultLocale;
        LC_MEASUREMENT = config.i18n.defaultLocale;
        LC_MONETARY = config.i18n.defaultLocale;
        LC_NAME = config.i18n.defaultLocale;
        LC_NUMERIC = config.i18n.defaultLocale;
        LC_PAPER = config.i18n.defaultLocale;
        LC_TELEPHONE = config.i18n.defaultLocale;
        LC_TIME = config.i18n.defaultLocale;
      };
      supportedLocales = [
        "en_US.UTF-8/UTF-8"
      ];
    };
  };
}
