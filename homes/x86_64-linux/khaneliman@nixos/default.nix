{ lib
, config
, ...
}:
with lib.internal; {
  khanelinix = {
    user = {
      enable = true;
      inherit (config.snowfallorg.user) name;
    };

    apps = { };

    cli-apps = {
      home-manager = enabled;
      neovim = enabled;
      zsh = enabled;
    };

    system = {
      xdg = enabled;
    };

    suites = {
      development = enabled;
    };

    tools = {
      direnv = enabled;
      git = enabled;
      ssh = enabled;
    };
  };

  home.stateVersion = "21.11";
}
