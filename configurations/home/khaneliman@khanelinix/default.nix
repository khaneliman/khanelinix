{
  config,
  lib,
  pkgs,
  root,
  khanelinix-lib,
  self,
  system,
  ...
}:
let
  inherit (lib) getExe;
  inherit (khanelinix-lib) enabled;
in
{
  khanelinix = {
    user = {
      enable = true;
      inherit (config.snowfallorg.user) name;
    };

    programs = {
      graphical = {
        addons.looking-glass-client = enabled;
        apps = {
          thunderbird = {
            enable = true;
            extraAccounts =
              let
                # Not super secret, just doesn't need to be scraped so easily.
                outlook = khanelinix-lib.decode "a2hhbmVsaW1hbjEyQG91dGxvb2suY29t";
                personal = khanelinix-lib.decode "YXVzdGluLm0uaG9yc3RtYW5AZ21haWwuY29t";

              in
              {
                ${outlook} = {
                  address = outlook;
                  flavor = "outlook.office365.com";
                };
                ${personal} = {
                  address = personal;
                  flavor = "gmail.com";
                };
              };
          };
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
            # enableDebug = true;

            appendConfig = # bash
              ''
                exec-once = hyprctl setcursor ${config.khanelinix.theme.gtk.cursor.name} ${builtins.toString config.khanelinix.theme.gtk.cursor.size}
              '';

            prependConfig = # bash
              lib.concatStringsSep "\n" [
                "# See https://wiki.hyprland.org/Configuring/Monitors/"
                # "monitor=DP-3,	3840x2160@60,	1420x0,	2, bitdepth, 10"
                # "monitor=DP-1,	5120x1440@120,	0x1080,	1, bitdepth, 10"
                "monitor=DP-3,	3840x2160@60,	1420x0,	2"
                "monitor=DP-1,	5120x1440@120,	0x1080,	1"
                ""
                (lib.concatStringsSep " " [
                  "exec-once = ${getExe pkgs.xorg.xrandr}"
                  "--output XWAYLAND0 --primary --mode 1920x1080 --pos 1420x0 --rotate normal"
                  "--output XWAYLAND1 --mode 5120x1440 --pos 0x1080 --rotate normal"
                ])
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

              workspaceOutputAssign = [
                {
                  workspace = "1";
                  output = "DP-3";
                }
                {
                  workspace = "2";
                  output = "DP-1";
                }
                {
                  workspace = "3";
                  output = "DP-1";
                }
                {
                  workspace = "4";
                  output = "DP-1";
                }
                {
                  workspace = "5";
                  output = "DP-1";
                }
                {
                  workspace = "6";
                  output = "DP-1";
                }
                {
                  workspace = "7";
                  output = "DP-1";
                }
                {
                  workspace = "8";
                  output = "DP-1";
                }
              ];
            };
          };
        };
      };

      terminal = {
        tools = {
          git = {
            enable = true;

            includes = [
            ];
          };

          run-as-service = enabled;

          ssh = {
            enable = true;

            authorizedKeys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpfTVxQKmkAYOrsnroZoTk0LewcBIC4OjlsoJY6QbB0"
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM7UBwfd7+K0mdkAIb2TE6RzMu6L4wZnG/anuoYqJMPB"
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJAZIwy7nkz8CZYR/ZTSNr+7lRBW2AYy1jw06b44zaID" # Khanelimac
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBG8l3jQ2EPLU+BlgtaQZpr4xr97n2buTLAZTxKHSsD" # Khaneliman@khanelimac
            ];
          };
        };
      };
    };

    services = {
      hyprpaper = {
        monitors = [
          {
            name = "DP-3";
            wallpaper = "${self.packages.${system}.wallpapers}/share/wallpapers/cat_pacman.png";
          }
          {
            name = "DP-1";
            wallpaper = "${self.packages.${system}.wallpapers}/share/wallpapers/cat-sound.png";
          }
        ];

        wallpapers = [
          "${self.packages.${system}.wallpapers}/share/wallpapers/buttons.png"
          "${self.packages.${system}.wallpapers}/share/wallpapers/cat_pacman.png"
          "${self.packages.${system}.wallpapers}/share/wallpapers/cat-sound.png"
          "${self.packages.${system}.wallpapers}/share/wallpapers/flatppuccin_macchiato.png"
          "${self.packages.${system}.wallpapers}/share/wallpapers/hashtags-black.png"
          "${self.packages.${system}.wallpapers}/share/wallpapers/hashtags-new.png"
          "${self.packages.${system}.wallpapers}/share/wallpapers/hearts.png"
          "${self.packages.${system}.wallpapers}/share/wallpapers/tetris.png"
        ];
      };

      mpd = {
        musicDirectory = "nfs://austinserver.local/mnt/user/data/media/music";
      };

      rnnoise = enabled;

      sops = {
        enable = true;
        defaultSopsFile = root + "/secrets/khanelinix/khaneliman/default.yaml";
        sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      };
    };

    system = {
      xdg = enabled;
    };

    suites = {
      art = enabled;
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
      networking = enabled;
      photo = enabled;
      social = enabled;
      video = enabled;
    };

    theme.catppuccin = enabled;
  };

  home.stateVersion = "21.11";
}
