{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) mkBoolOpt mkOpt;

  cfg = config.khanelinix.programs.graphical.apps.thunderbird;
in
{
  options.khanelinix.programs.graphical.apps.thunderbird = {
    enable = mkBoolOpt false "Whether or not to enable thunderbird.";
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

    home.packages = lib.optionals pkgs.stdenv.isLinux (
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
            realName = config.khanelinix.user.fullName;
            thunderbird = {
              enable = true;
              profiles = [
                config.khanelinix.user.name
              ];
              settings = id: {
                "mail.server.server_${id}.authMethod" = 10;
                "mail.server.server_${id}.is_gmail" = lib.mkIf (flavor == "gmail.com") true;
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
      // lib.mapAttrs (_name: mkEmailConfig) cfg.extraAccounts;

    programs.thunderbird = {
      enable = true;
      package = if pkgs.stdenv.isDarwin then pkgs.emptyDirectory else pkgs.thunderbird-latest;
      # yeah, yeah...
      darwinSetupWarning = false;

      profiles.${config.khanelinix.user.name} = {
        isDefault = true;

        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "layers.acceleration.force-enabled" = true;
          "gfx.webrender.all" = true;
          "gfx.webrender.enabled" = true;
          "svg.context-properties.content.enabled" = true;
          "browser.display.use_system_colors" = true;
          "browser.theme.dark-toolbar-theme" = true;
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
