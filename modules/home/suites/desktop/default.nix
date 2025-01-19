{
  config,
  lib,
  pkgs,
  khanelinix-lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt;

  cfg = config.khanelinix.suites.desktop;
in
{
  options.khanelinix.suites.desktop = {
    enable = mkBoolOpt false "Whether or not to enable common desktop applications.";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        meshcentral
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [
        appimage-run
        bitwarden
        bleachbit
        clac
        dropbox
        dupeguru
        feh
        filelight
        fontpreview
        gparted
        input-leap
        kdePackages.ark
        kdePackages.gwenview
        realvnc-vnc-viewer
        rustdesk-flutter
      ];
  };
}
