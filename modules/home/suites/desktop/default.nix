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
    remoteDesktopEnable = lib.mkEnableOption "remote desktop applications";
    fileManagementEnable = lib.mkEnableOption "file management applications";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      programs = {
        graphical = {
          bars = {
            sketchybar.enable = mkDefault pkgs.stdenv.hostPlatform.isDarwin;
          };
          wms = {
            aerospace.enable = mkDefault pkgs.stdenv.hostPlatform.isDarwin;
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
        skhd.enable = mkDefault false;
      };

      theme = {
        gtk.enable = mkDefault pkgs.stdenv.hostPlatform.isLinux;
        qt.enable = mkDefault pkgs.stdenv.hostPlatform.isLinux;
      };
    };

    home.packages =
      with pkgs;
      [
        clac
        feh
      ]
      ++ lib.optionals cfg.remoteDesktopEnable [
        input-leap
        meshcentral
        realvnc-vnc-viewer
      ]
      ++ lib.optionals cfg.fileManagementEnable [
        bleachbit
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux (
        [
          appimage-run
          # FIXME: remove xdotool hard dependency
          fontpreview
        ]
        ++ lib.optionals cfg.remoteDesktopEnable [
          rustdesk-flutter
        ]
        ++ lib.optionals cfg.fileManagementEnable [
          dropbox
          # FIXME: broken nixpkgs
          # dupeguru
          kdePackages.filelight
          kdePackages.ark
          kdePackages.gwenview
        ]
      );

    targets.darwin = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      copyApps.enable = true;
      linkApps.enable = false;
    };
  };
}
