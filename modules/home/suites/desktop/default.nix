{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkDefault mkIf;
  inherit (lib.${namespace}) enabled mkBoolOpt;

  cfg = config.${namespace}.suites.desktop;
in
{
  options.${namespace}.suites.desktop = {
    enable = mkBoolOpt false "Whether or not to enable common desktop applications.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      programs = {
        graphical = {
          browsers = {
            firefox = mkDefault enabled;
          };
        };
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
        dupeguru
        feh
        kdePackages.filelight
        fontpreview
        gparted
        input-leap
        kdePackages.ark
        kdePackages.gwenview
        realvnc-vnc-viewer
        # FIXME:
        # rustdesk-flutter
      ];
  };
}
