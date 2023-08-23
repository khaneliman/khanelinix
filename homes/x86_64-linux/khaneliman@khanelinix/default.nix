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

    apps = {
      zathura = enabled;
      thunderbird = enabled;
    };

    cli-apps = {
      home-manager = enabled;
      spicetify = enabled;
    };

    desktop = {
      addons = {
        swayidle = enabled;
        waybar.debug = true;
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
      common = enabled;
      development = enabled;
      music = enabled;
      social = enabled;
    };

    tools = {
      git = enabled;
      ssh = enabled;
    };
  };

  home.shellAliases = {
    nixcfg = "nvim ~/.config/.dotfiles/dots/nixos/flake.nix";
  };

  home.stateVersion = "21.11";
}
