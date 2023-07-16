{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps.firefox;
in {
  options.khanelinix.apps.firefox = with types; {
    enable = mkBoolOpt false "Whether or not to enable Firefox.";
  };

  config = mkIf cfg.enable {
    # khanelinix.home = with inputs; {
    #   extraOptions = {
    #     programs.firefox = {
    #       enable = true;
    #       package = pkgs.firefox-devedition-bin;
    #
    #       profiles.${config.khanelinix.user.name} = {
    #         inherit (cfg) extraConfig userChrome settings;
    #         id = 0;
    #         name = config.khanelinix.user.name;
    #         extensions = with pkgs.nur.repos.rycee.firefox-addons; [
    #           sponsorblock
    #           ublock-origin
    #           bitwarden
    #           onepassword-password-manager
    #           darkreader
    #           stylus
    #           angular-devtools
    #           reduxdevtools
    #           tabcenter-reborn
    #           user-agent-string-switcher
    #         ];
    #       };
    #     };
    #   };
    # };

    environment.systemPackages = with pkgs; [
      firefox-devedition-bin
    ];
  };
}
