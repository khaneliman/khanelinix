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

    suites.common = enabled;

    programs = {
      terminal = {
        tools = {
          lazygit = enabled;
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

    theme.catppuccin = enabled;
  };

  home.shellAliases = {
    lg = "lazygit";
  };

  home.stateVersion = "25.11";
}
