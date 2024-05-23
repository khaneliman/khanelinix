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
    home.packages = with pkgs; [
      birdtray
      davmail
      thunderbird
    ];

    # TODO: set up accounts
    accounts.email.accounts = {
      "${config.${namespace}.user.email}" = {
        address = config.${namespace}.user.email;
        realName = config.${namespace}.user.fullName;
        flavor = "gmail.com";
        primary = true;
      };
    };

    programs.thunderbird = {
      enable = true;
      package = pkgs.thunderbird;

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
