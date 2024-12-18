{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.graphical.apps.thunderbird;
in
{
  options.${namespace}.programs.graphical.apps.thunderbird = {
    enable = mkBoolOpt false "Whether or not to enable thunderbird.";
  };

  config = mkIf cfg.enable {

    home.packages = lib.optionals pkgs.stdenv.isLinux (
      with pkgs;
      [
        birdtray
        davmail
      ]
    );

    # TODO: set up accounts
    accounts.email.accounts = {
      "${config.${namespace}.user.email}" = {
        address = config.${namespace}.user.email;
        realName = config.${namespace}.user.fullName;
        flavor = "gmail.com";
        primary = true;
        thunderbird = {
          enable = true;
          profiles = [
            config.${namespace}.user.name
          ];
          settings = id: {
            "mail.server.server_${id}.is_gmail" = true;
            "mail.server.server_${id}.authMethod" = 10;
          };
        };
      };
    };

    programs.thunderbird = {
      enable = true;
      package = lib.mkIf pkgs.stdenv.isDarwin pkgs.emptyDirectory;
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
        # TODO: set up accounts
      };
    };
  };
}
