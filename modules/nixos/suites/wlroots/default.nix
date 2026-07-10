{
  config,
  lib,

  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.suites.wlroots;
in
{
  options.khanelinix.suites.wlroots = {
    enable = lib.mkEnableOption "common wlroots configuration";
  };

  config = mkIf cfg.enable {
    nix.settings = {
      substituters = [ "https://nixpkgs-wayland.cachix.org" ];
      trusted-public-keys = [
        "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      ];
    };

    khanelinix = {
      services = {
        seatd = mkDefault enabled;
      };
    };
    programs = {
      xwayland.enable = mkDefault true;

      wshowkeys = {
        enable = mkDefault true;
        package = pkgs.wshowkeys;
      };
    };
  };
}
