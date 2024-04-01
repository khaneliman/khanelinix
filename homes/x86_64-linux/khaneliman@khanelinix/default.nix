{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) getExe;
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
      chromium = enabled;

      firefox = {
        gpuAcceleration = true;
        hardwareDecoding = true;
        settings = {
          # "dom.ipc.processCount.webIsolated" = 9;
          # "dom.maxHardwareConcurrency" = 16;
          "media.av1.enabled" = false;
          # "media.ffvpx.enabled" = false;
          # "media.hardware-video-decoding.force-enabled" = true;
          "media.hardwaremediakeys.enabled" = true;
        };
      };
    };

    cli-apps = {
      home-manager = enabled;
      spicetify = enabled;
      k9s = enabled;
    };

    desktop = {
      addons = {
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

      hyprland = {
        enable = true;
        appendConfig = /* bash */ ''
          exec-once = hyprctl setcursor ${config.khanelinix.desktop.addons.gtk.cursor.name} 32
        '';

        prependConfig = /* bash */ lib.concatStringsSep "\n" [
          "# See https://wiki.hyprland.org/Configuring/Monitors/"
          "monitor=DP-3,	3840x2160@60,	1420x0,	2"
          "monitor=DP-1,	5120x1440@120,	0x1080,	1"
          ""
          ("exec-once = ${getExe pkgs.xorg.xrandr} "
            + "--output XWAYLAND0 --primary --mode 1920x1080 --pos 1420x0 --rotate normal"
            + "--output XWAYLAND1 --mode 5120x1440 --pos 0x1080 --rotate normal")
          ""
          "workspace = 1, monitor:DP-3, persistent:true"
          "workspace = 2, monitor:DP-1, persistent:true, default:true"
          "workspace = 3, monitor:DP-1, persistent:true"
          "workspace = 4, monitor:DP-1, persistent:true"
          "workspace = 5, monitor:DP-1, persistent:true"
          "workspace = 6, monitor:DP-1, persistent:true"
          "workspace = 7, monitor:DP-1, persistent:true"
          "workspace = 8, monitor:DP-1, persistent:true"
          "workspace = 9, monitor:DP-1, persistent:true"
        ];
      };
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
      business = enabled;
      common = enabled;
      development = {
        enable = true;
        dockerEnable = true;
      };
      music = enabled;
      social = enabled;
      video = enabled;
    };

    tools = {
      git = {
        enable = true;

        includes = [
          {
            condition = "gitdir:/home/khaneliman/Documents/azure/DIB/";
            path = "${./git/dib-signing}";
          }
        ];
      };

      ssh = enabled;
    };
  };

  home.shellAliases = {
    nixcfg = "nvim ~/.config/.dotfiles/dots/nixos/flake.nix";
  };

  home.stateVersion = "21.11";
}


