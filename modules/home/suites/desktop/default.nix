{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkDefault mkIf;

  cfg = config.khanelinix.suites.desktop;
in
{
  options.khanelinix.suites.desktop = {
    enable = lib.mkEnableOption "common desktop applications";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      programs = {
        graphical = {
          bars = {
            sketchybar.enable = mkDefault pkgs.stdenv.hostPlatform.isDarwin;
          };
          browsers = {
            firefox = {
              enable = mkDefault true;
              extensions.settings = {
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
              };
            };
          };
        };
      };

      services = {
        jankyborders.enable = mkDefault pkgs.stdenv.hostPlatform.isDarwin;
        skhd.enable = mkDefault pkgs.stdenv.hostPlatform.isDarwin;
      };

      theme = {
        gtk.enable = mkDefault pkgs.stdenv.hostPlatform.isLinux;
        qt.enable = mkDefault pkgs.stdenv.hostPlatform.isLinux;
      };
    };

    home.packages =
      with pkgs;
      [
        meshcentral
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        appimage-run
        bitwarden
        bleachbit
        clac
        dropbox
        # FIXME: broken nixpkgs
        # dupeguru
        feh
        kdePackages.filelight
        fontpreview
        # FIXME: broken nixpkgs
        # input-leap
        kdePackages.ark
        kdePackages.gwenview
        realvnc-vnc-viewer
        rustdesk-flutter
      ];
  };
}
