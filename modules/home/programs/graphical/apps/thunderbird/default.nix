{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkOpt;

  cfg = config.${namespace}.programs.graphical.apps.thunderbird;
in
{
  options.${namespace}.programs.graphical.apps.thunderbird = {
    enable = lib.mkEnableOption "thunderbird";
    accountsOrder = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Custom ordering of accounts.";
    };
    extraAccounts = lib.mkOption {
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

    accounts.email.accounts =
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
            realName = config.${namespace}.user.fullName;
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
                config.${namespace}.user.name
              ];
              settings = _id: {
              };
            };
          };
      in
      {
        "${config.${namespace}.user.email}" = mkEmailConfig {
          address = config.${namespace}.user.email;
          primary = true;
          flavor = "gmail.com";
        };
      }
      // lib.mapAttrs (_name: mkEmailConfig) cfg.extraAccounts;

    programs.thunderbird = {
      enable = true;
      package = pkgs.thunderbird-latest;

      profiles.${config.${namespace}.user.name} = {
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
