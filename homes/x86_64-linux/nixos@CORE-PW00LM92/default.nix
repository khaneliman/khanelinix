{ lib
, config
, ...
}:
let
  inherit (lib) mkForce;
  inherit (lib.internal) enabled disabled;
in
{
  khanelinix = {
    user = {
      enable = true;
      inherit (config.snowfallorg.user) name;
    };

    apps = {
      vscode = mkForce disabled;
    };

    cli-apps = {
      home-manager = enabled;
    };

    system = {
      xdg = enabled;
    };

    suites = {
      common = enabled;
      development = enabled;
    };

    tools = {
      git = {
        enable = true;
        wslAgentBridge = true;
        includes = [
          {
            condition = "gitdir:/mnt/c/";
            path = "${./git/windows-compat-config}";
          }
          {
            condition = "gitdir:/mnt/c/Users/Austin.Horstman/source/repos/DiB/";
            path = "${./git/dib-signing}";
          }
        ];
      };

      ssh = enabled;
    };
  };

  home.shellAliases = {
    nixcfg = "nvim ~/khanelinix/flake.nix";
  };

  home.stateVersion = "23.11";
}
