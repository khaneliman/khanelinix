{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.apps.thunderbird;
in
{
  options.khanelinix.apps.thunderbird = {
    enable = mkBoolOpt false "Whether or not to enable thunderbird.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      birdtray
      davmail
      thunderbird
    ];

    khanelinix.home.extraOptions = {
      accounts.email.accounts = {
        "${config.khanelinix.user.email}" = {
          address = config.khanelinix.user.email;
          realName = config.khanelinix.user.fullName;
          flavor = "gmail.com";
          primary = true;
        };
      };

      programs.thunderbird = {
        enable = true;
        package = pkgs.thunderbird;

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

          userChrome = ''
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
  };
}
