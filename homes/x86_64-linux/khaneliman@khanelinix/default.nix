{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) getExe;
  inherit (lib.khanelinix) enabled;
  wallpaperCfg = config.khanelinix.theme.wallpaper;
  wallpaperPath = name: lib.khanelinix.theme.wallpaperPath { inherit config pkgs name; };
  wallpaperPaths = names: lib.khanelinix.theme.wallpaperPaths { inherit config pkgs names; };
in
{
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
          citrix-workspace = {
            enable = true;
            settings = {
              # Enable webcam background blur/effects for VDA vt0-it-47-d000
              vt0-it-47-d000.HDXWebCamEnableBackgndEffectPerVDA = "True";
            };
          };
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

            settings = {
              monitorv2 = [
                {
                  output = "DP-3";
                  mode = "3840x2160@60";
                  position = "1420x0";
                  scale = 2;
                  bitdepth = 10;
                }
                {
                  output = "DP-1";
                  mode = "5120x1440@120";
                  position = "0x1080";
                  scale = 1;
                  vrr = 1;
                  bitdepth = 10;
                }
              ];

              exec-once = [
                (lib.concatStringsSep " " [
                  "${getExe pkgs.xorg.xrandr}"
                  "--output DP-3 --mode 1920x1080 --pos 1420x0 --rotate normal"
                  "--output DP-1 --primary --mode 5120x1440 --pos 0x1080 --rotate normal"
                ])
                "hyprctl setcursor ${config.khanelinix.theme.gtk.cursor.name} ${toString config.khanelinix.theme.gtk.cursor.size}"
              ];

              workspace = [
                "1, monitor:DP-3, persistent:true, default:true"
                "2, monitor:DP-1, persistent:true, default:true"
                "3, monitor:DP-1, persistent:true"
                "4, monitor:DP-1, persistent:true"
                "5, monitor:DP-1, persistent:true"
                "6, monitor:DP-1, persistent:true"
                "7, monitor:DP-1, persistent:true"
                "8, monitor:DP-1, persistent:true"
                "9, monitor:DP-1, persistent:true"
              ];
            };
          };

          niri = {
            enable = true;

            settings = {
              outputs = {
                "DP-3" = {
                  name = "DP-3";
                  mode = {
                    width = 3840;
                    height = 2160;
                    refresh = 60.0;
                  };
                  position = {
                    x = 1420;
                    y = 0;
                  };
                  scale = 2.0;
                };

                "DP-1" = {
                  name = "DP-1";
                  mode = {
                    width = 5120;
                    height = 1440;
                    refresh = 120.0;
                  };
                  position = {
                    x = 0;
                    y = 1080;
                  };
                  scale = 1.0;
                  focus-at-startup = true;
                };
              };

              workspaces = {
                "1" = {
                  open-on-output = "DP-3";
                };
              }
              // lib.genAttrs (map toString (lib.range 2 9)) (_: {
                open-on-output = "DP-1";
              });

              xwayland-satellite = {
                enable = true;
                path = lib.getExe pkgs.xwayland-satellite;
              };
            };
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
            wallpaper = wallpaperPath wallpaperCfg.primary;
          }
          {
            name = "DP-1";
            wallpaper = wallpaperPath wallpaperCfg.secondary;
          }
        ];

        wallpapers = wallpaperPaths wallpaperCfg.list;
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
      tokyonight = enabled;
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
        path = wallpaperPath wallpaper;
        blur_passes = 3;
        blur_size = 8;
        contrast = "0.891700";
        noise = "0.011700";
        vibrancy = "0.168600";
        vibrancy_darkness = "0.050000";
      };
    in
    [
      (mkBackground "DP-1" wallpaperCfg.secondary)
      (mkBackground "DP-3" wallpaperCfg.primary)
    ]
  );

  programs.mcp.servers.filesystem.args = [
    config.home.homeDirectory
    "${config.home.homeDirectory}/Documents"
    "${config.home.homeDirectory}/khanelinix"
    "${config.home.homeDirectory}/Documents/github"
  ];

  # Neo G9
  xresources.properties."Xft.dpi" = "108";

  home.stateVersion = "25.11";
}
