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

  system.stateVersion = "25.11";

  # networking.nameservers = lib.mkForce [
  #   "172.18.16.1"
  #   "172.18.118.101"
  #   "172.18.118.102"
  # ];
  networking.search = [
    "intranet.secura.net"
  ];

  environment.shellInit = ''
    if [ -n "$OPENAI_SECURA_KEY" ]; then
      export OPENAI_API_KEY="$OPENAI_SECURA_KEY"
    fi
  '';

  # wsl.wslConf = {
  # network.generateResolvConf = false;
  # };
}
