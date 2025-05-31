{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.programs.graphical.browsers.firefox;
in
{
  options.khanelinix.programs.graphical.browsers.firefox = {
    extensions = {
      packages = mkOpt (with lib.types; listOf package) (with pkgs.firefox-addons; [
        angular-devtools
        auto-tab-discard
        bitwarden
        # NOTE: annoying new page and permissions
        # bypass-paywalls-clean
        darkreader
        firefox-color
        firenvim
        frankerfacez
        onepassword-password-manager
        react-devtools
        reduxdevtools
        sponsorblock
        stylus
        ublock-origin
        user-agent-string-switcher
      ]) "Extensions to install";

      settings = mkOpt (with lib.types; attrsOf anything) {
        "uBlock0@raymondhill.net" = {
          # Home-manager skip collision check
          force = true;
          settings = {
            selectedFilterLists = [
              "easylist"
              "easylist-annoyances"
              "easylist-chat"
              "easylist-newsletters"
              "easylist-notifications"
              "fanboy-cookiemonster"
              "ublock-badware"
              "ublock-cookies-easylist"
              "ublock-filters"
              "ublock-privacy"
              "ublock-quick-fixes"
              "ublock-unbreak"
            ];
          };
        };
      } "Settings to apply to the extensions.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.firefox.profiles.${config.khanelinix.user.name}.extensions = {
      inherit (cfg.extensions) packages settings;
      force = cfg.extensions.settings != { };
    };
  };
}
