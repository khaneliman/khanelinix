{ config, lib, ... }:
let
  inherit (lib.internal) enabled;
in
{
  khanelinix = {
    user = {
      enable = true;
      inherit (config.snowfallorg.user) name;
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
      git = enabled;
      ssh = enabled;
    };
  };

  home.stateVersion = "21.11";
}
