{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib.khanelinix) decode enabled;
  wallpaperCfg = config.khanelinix.theme.wallpaper;
  wallpaperPath = name: lib.khanelinix.theme.wallpaperPath { inherit config pkgs name; };
  wallpaperPaths = names: lib.khanelinix.theme.wallpaperPaths { inherit config pkgs names; };

  # Not super secret, just doesn't need to be scraped so easily.
  primaryGoogle = decode "a2hhbmVsaW1hbjEyQGdtYWlsLmNvbQ==";
  outlook = decode "a2hhbmVsaW1hbjEyQG91dGxvb2suY29t";
  personal = decode "YXVzdGluLm0uaG9yc3RtYW5AZ21haWwuY29t";
  work = decode "YXVzdGluLmhvcnN0bWFuQG5yaS1uYS5jb20=";
  googleCalendarCollections = [
    {
      name = decode "SG9saWRheXMgaW4gVW5pdGVkIFN0YXRlcw==";
      remote = decode "Y2xuMnN0YmpjNGhtZ3JyY2Q1aTYydWEwY3RwNnV0Ymc1cHIyc29yMWRoaW1zcDMxZThuNmVycmZjdG02YWJqM2R0bWdAdmlydHVhbA==";
      local = decode "aG9saWRheXMtdW5pdGVkLXN0YXRlcw==";
    }
    {
      name = decode "UHJpbWFyeQ==";
      remote = primaryGoogle;
      local = decode "cHJpbWFyeQ==";
    }
    {
      name = decode "R1RPIFRhc2tz";
      remote = decode "aWN1ZXNxNjlwNzFibjg5MzFvdDRiYmdqZzRAZ3JvdXAuY2FsZW5kYXIuZ29vZ2xlLmNvbQ==";
      local = decode "Z3RvLXRhc2tz";
    }
    {
      name = decode "RmFtaWx5";
      remote = decode "ZmFtaWx5MDE1MzE2MjQ5NDY3NjkzNjMyMzRAZ3JvdXAuY2FsZW5kYXIuZ29vZ2xlLmNvbQ==";
      local = decode "ZmFtaWx5";
    }
    {
      name = decode "TWljaGVsbGUgSA==";
      remote = decode "c2hlbGJlZTMzNzNAZ21haWwuY29t";
      local = decode "bWljaGVsbGUtaA==";
    }
  ];
in
{
  # Host input profile: Kinesis Advantage360 Pro split keyboard. Keep bind and
  # workflow choices ergonomic for thumb clusters, home-row access, and hardware
  # layers/macros instead of dense same-hand modifier chords.
  khanelinix = {
    packageProfile = "standard";

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
              WFClient = {
                AllowAudioInput = "True";
                HDXH264InputEnabled = "True";
                ToolbarVersion = 0;
              };
            };
          };
          thunderbird = {
            accountsOrder = [
              primaryGoogle
              personal
              outlook
              work
            ];
            extraCalendarAccounts = {
              "Birthdays" = {
                url = "https://apidata.googleusercontent.com/caldav/v2/c5i68sj5edpm4rrfdchm6rreehgm6t3j81jn4rrle0n7cbj3c5m6arj4c5p2sprfdtjmop9ecdnmq%40virtual/events/";
                type = "caldav";
                color = "#92e1c0";
              };
              "Family" = {
                url = "https://apidata.googleusercontent.com/caldav/v2/family01531624946769363234%40group.calendar.google.com/events/";
                type = "caldav";
                color = "#9a9cff";
              };
              "Michelle Z" = {
                url = "https://apidata.googleusercontent.com/caldav/v2/shelbee3373%40gmail.com/events/";
                type = "caldav";
                color = "#9a9cff";
              };
              "Milwaukee Bucks".enable = false;
            };
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
                # DavMail encrypts the shared OAuth token with this local bridge
                # password. Thunderbird's saved localhost credentials must match it.
                passwordCommand = [
                  (lib.getExe' pkgs.coreutils "cat")
                  config.sops.secrets."davmail/work-password".path
                ];
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
            resetTimeFormat = "local";
          };
        };

        browsers = {
          firefox = {
            extensions.installMethod = "policy";
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
            permissions.enforce = true;

            settings = {
              monitor = [
                {
                  output = "DP-3";
                  mode = "3840x2160@60";
                  position = "1280x0";
                  scale = 1.5;
                  # Troubleshooting Hyprland/AMDGPU DPMS wake crashes: keep
                  # 10-bit disabled to avoid HDR/wide-color monitor paths.
                  # bitdepth = 10;
                }
                {
                  output = "DP-1";
                  mode = "5120x1440@120";
                  position = "0x1440";
                  scale = 1;
                  vrr = 2;
                  # Troubleshooting Hyprland/AMDGPU DPMS wake crashes: keep
                  # always-on VRR and 10-bit disabled while testing stability.
                  # vrr = 1;
                  # bitdepth = 10;
                }
              ];

              workspace_rule = [
                {
                  workspace = "1";
                  monitor = "DP-3";
                  persistent = true;
                  default = true;
                }
                {
                  workspace = "2";
                  monitor = "DP-1";
                  persistent = true;
                  default = true;
                }
                {
                  workspace = "3";
                  monitor = "DP-1";
                  persistent = true;
                }
                {
                  workspace = "4";
                  monitor = "DP-1";
                  persistent = true;
                }
                {
                  workspace = "5";
                  monitor = "DP-1";
                  persistent = true;
                }
                {
                  workspace = "6";
                  monitor = "DP-1";
                  persistent = true;
                }
                {
                  workspace = "7";
                  monitor = "DP-1";
                  persistent = true;
                }
                {
                  workspace = "8";
                  monitor = "DP-1";
                  persistent = true;
                }
                {
                  workspace = "9";
                  monitor = "DP-1";
                  persistent = true;
                }
              ];
            };

            startupCommands = [
              "hyprctl setcursor ${config.khanelinix.theme.gtk.cursor.name} ${toString config.khanelinix.theme.gtk.cursor.size}"
            ];
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
        editors = {
          neovim.extraProfiles = [
            "minimal"
            "basic"
            "full"
            "debug"
          ];
        };

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
          sesh = enabled;
          ssh = enabled;
          tmux = enabled;
        };
      };
    };

    services = {
      cliproxyapi.enable = true;

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

      rnnoise = {
        enable = true;
        echoCancel = {
          enable = true;
          captureNode = "alsa_input.usb-Blue_Microphones_Yeti_Stereo_Microphone_LT_191128065321F39907D0_111000-00.analog-stereo";
        };
      };

      sops = {
        enable = true;
        defaultSopsFile = lib.getFile "secrets/khanelinix/khaneliman/default.yaml";
        sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      };

      vdirsyncer = {
        google = {
          enable = true;
          collections = googleCalendarCollections;
        };
        davmail.enable = true;
      };
    };

    system = {
      xdg = enabled;
    };

    roles = {
      desktop = enabled;
      developer = enabled;
      gamer = enabled;
    };

    suites = {
      development = {
        dockerEnable = true;
        gameEnable = true;
        kubernetesEnable = true;
        sqlEnable = true;
      };

      emulation.enable = false;
    };

    theme = {
      tokyonight = enabled;
      stylix = enabled;
    };
  };

  sops.secrets = lib.mkIf config.khanelinix.services.sops.enable {
    "davmail/work-password" = {
      sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
    };
    nix = {
      sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
      path = "${config.home.homeDirectory}/.config/nix/nix.conf";
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
    "/nix/store"
  ];

  # Neo G9
  xresources.properties."Xft.dpi" = "108";

  home.stateVersion = "26.05";
}
