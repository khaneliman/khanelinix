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

    environments = {
      home-network = enabled;
    };

    programs = {
      terminal = {
        tools = {
          ssh = enabled;
        };
      };
    };

    services = {
      sops = {
        enable = false;
        defaultSopsFile = lib.getFile "secrets/khanelimac/khaneliman/default.yaml";
        sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      };
    };

    roles = {
      developer = enabled;
    };

    theme.catppuccin = enabled;
  };

  home.stateVersion = "25.11";
}
