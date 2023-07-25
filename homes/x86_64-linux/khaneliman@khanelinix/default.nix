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

    apps = {
      zathura = enabled;
      thunderbird = enabled;
    };

    cli-apps = {
      helix = enabled;
      home-manager = enabled;
      neovim = enabled;
      spicetify = enabled;
      zsh = enabled;
    };

    desktop = {
      addons = {
        swayidle = enabled;
      };

      hyprland = enabled;
    };

    system = {
      xdg = enabled;
    };

    services = {
      mpd = {
        musicDirectory = "nfs://austinserver.local/mnt/user/data/media/music";
      };
    };

    suites = {
      music = enabled;
    };

    tools = {
      direnv = enabled;
      git = enabled;
      ssh = enabled;
    };
  };

  home.stateVersion = "21.11";
}
