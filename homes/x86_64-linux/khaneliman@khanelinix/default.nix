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
      helix = enabled;
      home-manager = enabled;
      neovim = enabled;
      spicetify = enabled;
      zsh = enabled;
    };

    tools = {
      direnv = enabled;
      git = enabled;
      ssh = enabled;
    };
  };
}
