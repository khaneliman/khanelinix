{
  config,
  root,
  khanelinix-lib,
  ...
}:
let
  inherit (khanelinix-lib) enabled;
in
{
  khanelinix = {
    user = {
      enable = true;
      inherit (config.khanelinix.user) name;
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
        defaultSopsFile = root + "/secrets/khanelinix/khaneliman/default.yaml";
        sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      };
    };

    system = {
      xdg = enabled;
    };

    suites = {
      common = enabled;
      development = enabled;
    };
  };

  home.stateVersion = "21.11";
}
