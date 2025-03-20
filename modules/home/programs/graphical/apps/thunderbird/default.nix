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
              ]) null "Email flavor";
            };
          };
        in
        lib.types.attrsOf accountType;
      default = null;
      description = "Extra email accounts to configure.";
    };
  };

  config = mkIf cfg.enable {

    home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux (
      with pkgs;
      [
        birdtray
        davmail
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
            inherit address primary flavor;
            realName = config.${namespace}.user.fullName;
            thunderbird = {
              enable = true;
              profiles = [
                config.${namespace}.user.name
              ];
              settings = id: {
                "mail.server.server_${id}.authMethod" = 10;
                "mail.server.server_${id}.is_gmail" = lib.mkIf (flavor == "gmail.com") true;
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
      package =
        if pkgs.stdenv.hostPlatform.isDarwin then pkgs.emptyDirectory else pkgs.thunderbird-latest;
      # yeah, yeah...
      darwinSetupWarning = false;

      profiles.${config.${namespace}.user.name} = {
        isDefault = true;

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
