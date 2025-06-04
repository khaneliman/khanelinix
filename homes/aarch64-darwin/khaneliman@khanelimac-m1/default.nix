{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) enabled;
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
          ssh = enabled;
        };
      };
    };

    services = {
      sops = {
        enable = false;
        defaultSopsFile = lib.khanelinix.getFile "secrets/khanelimac/khaneliman/default.yaml";
        sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      };
    };

    suites = {
      common = enabled;
      development = {
        enable = true;
        nixEnable = true;
      };
      networking = enabled;
    };

    theme.catppuccin = enabled;
  };

  home.stateVersion = "24.11";
}
