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

  cfg = config.${namespace}.suites.desktop;
in
{
  options.${namespace}.suites.desktop = {
    enable = mkBoolOpt false "Whether or not to enable common desktop applications.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      barrier
      bitwarden
      bleachbit
      dropbox
      # TODO: remove override after https://github.com/NixOS/nixpkgs/pull/325740 is in unstable
      (dupeguru.override { python3Packages = pkgs.python311Packages; })
      filelight
      fontpreview
      gparted
      pkgs.${namespace}.pocketcasts
      realvnc-vnc-viewer
    ];
  };
}
