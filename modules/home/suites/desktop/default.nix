{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkDefault mkIf;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.desktop;
in
{
  options.${namespace}.suites.desktop = {
    enable = lib.mkEnableOption "common desktop applications";
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
        dupeguru
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
