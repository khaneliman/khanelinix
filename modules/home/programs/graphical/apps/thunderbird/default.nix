{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.programs.graphical.apps.thunderbird;
in
{
  options.khanelinix.programs.graphical.apps.thunderbird = {
    enable = lib.mkEnableOption "thunderbird";
    accountsOrder = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Custom ordering of accounts.";
    };
    extraCalendarAccounts = lib.mkOption {
      type =
        let
          accountType = lib.types.submodule {
            options = {
              url = mkOpt lib.types.str null "Calendar url";
              type = mkOpt (lib.types.enum [
                "caldav"
                "http"
              ]) null "Calendar flavor";
              color = mkOpt lib.types.str null "color";
            };
          };
        in
        lib.types.attrsOf accountType;
      default = {
        "Milwaukee Bucks" = {
          url = "https://apidata.googleusercontent.com/caldav/v2/jeb1pn12iqgftnq21ae2qjljetlr43cv%40import.calendar.google.com/events/";
          type = "caldav";
          color = "#05491C";
        };
        "US Holidays" = {
          url = "https://apidata.googleusercontent.com/caldav/v2/cln2stbjc4hmgrrcd5i62ua0ctp6utbg5pr2sor1dhimsp31e8n6errfctm6abj3dtmg%40virtual/events/";
          type = "caldav";
          color = "#92cfe1";
        };
        "Green Bay Packers" = {
          url = "https://sports.yahoo.com/nfl/teams/gnb/ical.ics";
          type = "http";
          color = "#F9BC12";
        };
      };
      description = "Extra calendar accounts to configure.";
    };
    extraEmailAccounts = lib.mkOption {
      type =
        let
          accountType = lib.types.submodule {
            options = {
              address = mkOpt lib.types.str null "Email address";
              flavor = mkOpt (lib.types.enum [
                "plain"
                "gmail.com"
                "runbox.com"
                "fastmail.com"
                "yandex.com"
                "outlook.office365.com"
                "davmail"
              ]) null "Email flavor";
            };
          };
        in
        lib.types.attrsOf accountType;
      default = { };
      description = "Extra email accounts to configure.";
    };
  };

  config = mkIf cfg.enable {

    home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux (
      with pkgs;
      [
        birdtray
      ]
    );

    accounts = {
      calendar.accounts =
        let
          mkCalendarConfig =
            {
              url,
              type,
              color ? "#9a9cff",
            }:
            {
              remote = {
                inherit type url;
                userName = config.khanelinix.user.email;
              };
              local = {
                inherit color;
              };
              thunderbird = {
                enable = true;
                profiles = [
                  config.khanelinix.user.name
                ];
                inherit color;
              };
            };
        in
        {
          "${config.khanelinix.user.email}" = {
            remote = {
              type = "caldav";
              url = "https://apidata.googleusercontent.com/caldav/v2/khaneliman12%40gmail.com/events/";
              userName = config.khanelinix.user.email;
            };
            primary = true;
            thunderbird = {
              enable = true;
              profiles = [
                config.khanelinix.user.name
              ];
              color = "#16a765";
            };
          };
        }
        // lib.mapAttrs (_name: mkCalendarConfig) cfg.extraCalendarAccounts;
      email.accounts =
        let
          mkEmailConfig =
            {
              address,
              primary ? false,
              flavor,
            }:
            {
              inherit address primary;
              flavor = if (flavor == "davmail") then "plain" else flavor;
              realName = config.khanelinix.user.fullName;
              userName = lib.mkIf (flavor == "davmail") address;
              imap = lib.mkIf (flavor == "davmail") {
                host = "localhost";
                port = 1143;
                tls = {
                  enable = false;
                  useStartTls = false;
                };
              };
              smtp = lib.mkIf (flavor == "davmail") {
                host = "localhost";
                port = 1025;
                tls = {
                  enable = false;
                  useStartTls = false;
                };
              };
              thunderbird = {
                enable = true;
                profiles = [
                  config.khanelinix.user.name
                ];
                settings = _id: {
                };
              };
            };
        in
        {
          "${config.khanelinix.user.email}" = mkEmailConfig {
            address = config.khanelinix.user.email;
            primary = true;
            flavor = "gmail.com";
          };
        }
        // lib.mapAttrs (_name: mkEmailConfig) cfg.extraEmailAccounts;
    };

    programs.thunderbird = {
      enable = true;
      package = pkgs.thunderbird-latest;

      profiles.${config.khanelinix.user.name} = {
        isDefault = true;

        inherit (cfg) accountsOrder;

        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "layers.acceleration.force-enabled" = true;
          "gfx.webrender.all" = true;
          "gfx.webrender.enabled" = true;
          "svg.context-properties.content.enabled" = true;
          "browser.display.use_system_colors" = true;
          "browser.theme.dark-toolbar-theme" = true;
          "mailnews.default_sort_type" = 18;
          "mailnews.default_sort_order" = 2;
        };

        userChrome = # css
          ''
            #spacesToolbar,
            #agenda-container,
            #agenda,
            #agenda-toolbar,
            #mini-day-box
            {
              background-color: #24273a !important;
            }
          '';

        # TODO: Bundle extensions
      };
    };
  };
}
