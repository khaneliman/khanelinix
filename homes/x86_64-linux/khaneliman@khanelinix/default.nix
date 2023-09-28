{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib.internal) enabled;
in
{
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
        # waybar.debug = true;
        hyprpaper = {
          monitors = [
            { name = "DP-3"; wallpaper = "${pkgs.khanelinix.wallpapers}/share/wallpapers/cat_pacman.png"; }
            { name = "DP-1"; wallpaper = "${pkgs.khanelinix.wallpapers}/share/wallpapers/cat-sound.png"; }
          ];

          wallpapers = [
            "${pkgs.khanelinix.wallpapers}/share/wallpapers/buttons.png"
            "${pkgs.khanelinix.wallpapers}/share/wallpapers/cat_pacman.png"
            "${pkgs.khanelinix.wallpapers}/share/wallpapers/cat-sound.png"
            "${pkgs.khanelinix.wallpapers}/share/wallpapers/flatppuccin_macchiato.png"
            "${pkgs.khanelinix.wallpapers}/share/wallpapers/hashtags-black.png"
            "${pkgs.khanelinix.wallpapers}/share/wallpapers/hashtags-new.png"
            "${pkgs.khanelinix.wallpapers}/share/wallpapers/hearts.png"
            "${pkgs.khanelinix.wallpapers}/share/wallpapers/tetris.png"
          ];
        };
      };

      hyprland = enabled;
    };

    security = {
      sops = {
        enable = true;
        defaultSopsFile = ../../../secrets/khanelinix/khaneliman/default.yaml;
        sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      };
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
