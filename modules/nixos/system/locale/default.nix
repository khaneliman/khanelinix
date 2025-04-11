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
      extraLocaleSettings =
        let
          localeCategories = [
            "LANG"
            "LANGUAGE"
            "LC_ADDRESS"
            "LC_COLLATE"
            "LC_CTYPE"
            "LC_IDENTIFICATION"
            "LC_MEASUREMENT"
            "LC_MESSAGES"
            "LC_MONETARY"
            "LC_NAME"
            "LC_NUMERIC"
            "LC_PAPER"
            "LC_TELEPHONE"
            "LC_TIME"
          ];
        in
        lib.genAttrs localeCategories (_: config.i18n.defaultLocale);
      supportedLocales = [
        "C.UTF-8/UTF-8"
        "en_US.UTF-8/UTF-8"
      ];
    };
  };
}
