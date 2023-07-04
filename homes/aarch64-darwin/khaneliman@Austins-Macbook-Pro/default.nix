{
  lib,
  config,
  ...
}:
with lib.internal; {
  khanelinix = {
    user = {
      enable = true;
      inherit (config.snowfallorg.user) name;
    };

    cli-apps = {
      zsh = enabled;
      neovim = enabled;
      home-manager = enabled;
    };

    tools = {
      git = enabled;
      direnv = enabled;
    };
  };

  home.stateVersion = "22.11";
}
