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

  khanelinix = {
    archetypes = {
      wsl = enabled;
    };

    security = {
      # FIX: make gpg work on wsl
      gpg = mkForce disabled;
      sops = {
        enable = true;
        defaultSopsFile = lib.getFile "secrets/CORE/default.yaml";
      };
    };

    suites = {
      common = enabled;
      development = {
        enable = true;
      };
    };

    user = {
      name = "nixos";
    };
  };

  system.stateVersion = "26.05";

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
