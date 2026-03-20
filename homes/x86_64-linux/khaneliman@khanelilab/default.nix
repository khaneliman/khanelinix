{
  config,
  lib,

  ...
}:
let
  inherit (lib.khanelinix) enabled;
in
{
  khanelinix = {
    user = {
      enable = true;
      name = "khaneliman";
    };

    programs = {
      terminal = {
        tools = {
          git = enabled;
          ssh = enabled;
        };
      };
    };

    services = {
      sops = {
        enable = true;
        defaultSopsFile = lib.getFile "secrets/khanelilab/khaneliman/default.yaml";
        sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      };
    };

    system = {
      xdg = enabled;
    };

    suites = {
      common = enabled;
    };
  };

  sops.secrets = lib.mkIf config.khanelinix.services.sops.enable {
    nix = {
      sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
      path = "${config.home.homeDirectory}/.config/nix/nix.conf";
    };
  };

  home.stateVersion = "25.11";
}
