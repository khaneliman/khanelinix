{
  lib,

  ...
}:
let
  inherit (lib) mkForce;
  inherit (lib.khanelinix) enabled disabled;
in
{
  imports = [ ./hardware.nix ];

  documentation.man.enable = mkForce true;

  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

  khanelinix = {
    archetypes = {
      wsl = enabled;
    };

    security = {
      # FIX: make gpg work on wsl
      gpg = mkForce disabled;
    };

    suites = {
      common = enabled;
      development = {
        enable = true;
        sqlEnable = true;
      };
    };

    theme = {
      gtk = enabled;
      qt = enabled;
    };

    user = {
      name = "nixos";
    };
  };

  system.stateVersion = "25.05";

  # networking.nameservers = lib.mkForce [
  #   "172.18.16.1"
  #   "172.18.118.101"
  #   "172.18.118.102"
  # ];
  networking.search = [
    "intranet.secura.net"
  ];
  # wsl.wslConf = {
  # network.generateResolvConf = false;
  # };
}
