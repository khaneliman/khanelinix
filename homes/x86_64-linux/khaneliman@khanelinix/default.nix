{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) getExe;
  inherit (lib.${namespace}) enabled;
in
{
  khanelinix = {
    user = {
      enable = true;
      inherit (config.snowfallorg.user) name;
    };

    programs = {
      graphical = {
        apps = {
          thunderbird = enabled;
          zathura = enabled;
        };

        bars = {
          waybar = {
            fullSizeOutputs = [ "DP-1" ];
            condensedOutputs = [ "DP-3" ];
          };
        };

        browsers = {
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

        wms = {
          hyprland = {
            enable = true;
            enableDebug = true;

            appendConfig = # bash
              ''
                exec-once = hyprctl setcursor ${config.${namespace}.theme.gtk.cursor.name} 32
              '';

            prependConfig = # bash
              lib.concatStringsSep "\n" [
                "# See https://wiki.hyprland.org/Configuring/Monitors/"
                "monitor=DP-3,	3840x2160@60,	1420x0,	2"
                "monitor=DP-1,	5120x1440@120,	0x1080,	1"
                ""
                (
                  "exec-once = ${getExe pkgs.xorg.xrandr} "
                  + "--output XWAYLAND0 --primary --mode 1920x1080 --pos 1420x0 --rotate normal"
                  + "--output XWAYLAND1 --mode 5120x1440 --pos 0x1080 --rotate normal"
                )
                ""
                "workspace = 1, monitor:DP-3, persistent:true, default:true"
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

          sway = {
            enable = true;

            settings = {
              output = {
                "DP-3" = {
                  resolution = "3840x2160";
                  position = "1420,0";
                  scale = "2";
                };
                "DP-1" = {
                  resolution = "5120x1440";
                  position = "0,1080";
                };
              };
            };
          };
        };
      };

      terminal = {
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

          run-as-service = enabled;
          ssh = enabled;
        };
      };
    };

    services = {
      hyprpaper = {
        monitors = [
          {
            name = "DP-3";
            wallpaper = "${pkgs.${namespace}.wallpapers}/share/wallpapers/cat_pacman.png";
          }
          {
            name = "DP-1";
            wallpaper = "${pkgs.${namespace}.wallpapers}/share/wallpapers/cat-sound.png";
          }
        ];

        wallpapers = [
          "${pkgs.${namespace}.wallpapers}/share/wallpapers/buttons.png"
          "${pkgs.${namespace}.wallpapers}/share/wallpapers/cat_pacman.png"
          "${pkgs.${namespace}.wallpapers}/share/wallpapers/cat-sound.png"
          "${pkgs.${namespace}.wallpapers}/share/wallpapers/flatppuccin_macchiato.png"
          "${pkgs.${namespace}.wallpapers}/share/wallpapers/hashtags-black.png"
          "${pkgs.${namespace}.wallpapers}/share/wallpapers/hashtags-new.png"
          "${pkgs.${namespace}.wallpapers}/share/wallpapers/hearts.png"
          "${pkgs.${namespace}.wallpapers}/share/wallpapers/tetris.png"
        ];
      };

      mpd = {
        musicDirectory = "nfs://austinserver.local/mnt/user/data/media/music";
      };

      rnnoise = enabled;

      sops = {
        enable = true;
        defaultSopsFile = lib.snowfall.fs.get-file "secrets/khanelinix/khaneliman/default.yaml";
        sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      };
    };

    system = {
      xdg = enabled;
    };

    suites = {
      business = enabled;
      common = enabled;
      desktop = enabled;

      development = {
        enable = true;

        dockerEnable = true;
        gameEnable = true;
        kubernetesEnable = true;
        nixEnable = true;
        sqlEnable = true;
      };

      emulation = enabled;
      games = enabled;
      music = enabled;
      photo = enabled;
      social = enabled;
      video = enabled;
    };

    theme.catppuccin = enabled;
  };

  home.stateVersion = "21.11";
}
