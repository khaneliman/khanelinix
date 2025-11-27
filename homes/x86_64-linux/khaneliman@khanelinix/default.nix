{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) getExe;
  inherit (lib.khanelinix) enabled;
in
{
  home.packages = [
    # NOTE: annoyingly need to download separately and prefetch hash manually
    pkgs.citrix_workspace
  ];

  khanelinix = {
    user = {
      enable = true;
      name = "khaneliman";
    };

    environments = {
      home-network = enabled;
    };

    programs = {
      graphical = {
        addons.looking-glass-client = enabled;
        apps = {
          thunderbird =
            let
              # Not super secret, just doesn't need to be scraped so easily.
              outlook = lib.khanelinix.decode "a2hhbmVsaW1hbjEyQG91dGxvb2suY29t";
              personal = lib.khanelinix.decode "YXVzdGluLm0uaG9yc3RtYW5AZ21haWwuY29t";
              work = lib.khanelinix.decode "YXVzdGluLmhvcnN0bWFuQG5yaS1uYS5jb20=";
            in
            {
              accountsOrder = [
                "khaneliman12@gmail.com"
                personal
                outlook
                work
              ];
              extraEmailAccounts = {
                ${outlook} = {
                  address = outlook;
                  flavor = "outlook.office365.com";
                };
                ${personal} = {
                  address = personal;
                  flavor = "gmail.com";
                };
                ${work} = {
                  address = work;
                  flavor = "davmail";
                };
              };
            };
          zathura = enabled;
        };

        bars = {
          ashell = {
            fullSizeOutputs = [ "DP-1" ];
            condensedOutputs = [ "DP-3" ];
          };
          waybar = {
            enableDebug = false;
            # enableInspect = true;
            fullSizeOutputs = [ "DP-1" ];
            condensedOutputs = [ "DP-3" ];
          };
        };

        browsers = {
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
            enableDebug = false;

            appendConfig = /* bash */ ''
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
                  "--output DP-3 --mode 1920x1080 --pos 1420x0 --rotate normal"
                  "--output DP-1 --primary --mode 5120x1440 --pos 0x1080 --rotate normal"
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
          claude-code.mcpServers.filesystem.directories = [
            "${config.home.homeDirectory}/khanelinix"
            "${config.home.homeDirectory}/Documents/github"
          ];

          git = {
            enable = true;

            includes = [
            ];
          };
          gh = {
            gitCredentialHelper.hosts = lib.mkOptionDefault [
              "https://core-bts-02@dev.azure.com"
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
            wallpaper = "${pkgs.khanelinix.wallpapers}/share/wallpapers/cat_pacman.png";
          }
          {
            name = "DP-1";
            wallpaper = "${pkgs.khanelinix.wallpapers}/share/wallpapers/cat-sound.png";
          }
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

      rnnoise = enabled;

      sops = {
        enable = true;
        defaultSopsFile = lib.getFile "secrets/khanelinix/khaneliman/default.yaml";
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

        aiEnable = true;
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

    theme = {
      catppuccin = enabled;
      stylix = enabled;
    };
  };

  # Configure monitors independently and override module default
  programs.hyprlock.settings.background = lib.mkForce (
    let
      mkBackground = monitor: wallpaper: {
        inherit monitor;
        brightness = "0.817200";
        color = lib.mkDefault "rgba(25, 20, 20, 1.0)";
        path = "${pkgs.khanelinix.wallpapers}/share/wallpapers/${wallpaper}";
        blur_passes = 3;
        blur_size = 8;
        contrast = "0.891700";
        noise = "0.011700";
        vibrancy = "0.168600";
        vibrancy_darkness = "0.050000";
      };
    in
    [
      (mkBackground "DP-1" "cat_pacman.png")
      (mkBackground "DP-3" "tetris.png")
    ]
  );

  # Neo G9
  xresources.properties."Xft.dpi" = "108";

  home.stateVersion = "21.11";
}
