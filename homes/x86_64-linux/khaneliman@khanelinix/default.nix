{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib.khanelinix) decode enabled;
  wallpaperCfg = config.khanelinix.theme.wallpaper;
  wallpaperPaths = names: lib.khanelinix.theme.wallpaperPaths { inherit config pkgs names; };
  workGitIdentity = pkgs.writeText "git-work-identity" ''
    [user]
      email = ${work}
  '';

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
  imports = [ ../../identity.nix ];
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
                # Legacy toolbar: the enhanced toolbar crashes wfica with a
                # BadWindow race. If that recurs, disable the connection bar.
                ToolbarVersion = 0;
              };
            };
          };
          krita = enabled;
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
          waybar = {
            enableDebug = false;
            # enableInspect = true;
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

            startupCommands = [
              "hyprctl setcursor ${config.khanelinix.theme.gtk.cursor.name} ${toString config.khanelinix.theme.gtk.cursor.size}"
            ];
          };

          niri = {
            enable = true;

            settings = {
              xwayland-satellite = {
                enable = true;
                path = lib.getExe pkgs.xwayland-satellite;
              };
            };
          };

          sway = enabled;
        };
      };

      terminal = {
        editors = {
          neovim = {
            opencodeModel = "llama-swap/qwen3-coder-30b";
            extraProfiles = [
              "minimal"
              "basic"
              "full"
              "debug"
            ];
          };
        };

        emulators.limux = enabled;

        tools = {
          claude-code.quotaWarmup.enable = true;
          git = {
            enable = true;

            includes = [
              {
                # NOTE: include is inert until work repos live in ~/work.
                condition = "gitdir:~/work/";
                path = workGitIdentity;
              }
            ];
          };

          herdr = enabled;
          run-as-service = enabled;
          sesh = enabled;
          ssh = enabled;
          tmux = enabled;
        };
      };
    };

    services = {
      hyprpaper.wallpapers = wallpaperPaths wallpaperCfg.list;

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
      display.layout = {
        # Keep Hyprland's 10-bit color disabled while troubleshooting DPMS wake crashes.
        outputs = [
          {
            name = "DP-3";
            mode = {
              width = 3840;
              height = 2160;
              refresh = 60;
            };
            position = {
              x = 1420;
              y = 0;
            };
            scale = 2;
            hyprland = {
              position = {
                x = 1280;
                y = 0;
              };
              scale = 1.5;
            };
            workspaces = [ 1 ];
            bar = "condensed";
            wallpaper = "primary";
          }
          {
            name = "DP-1";
            mode = {
              width = 5120;
              height = 1440;
              refresh = 120;
            };
            position = {
              x = 0;
              y = 1080;
            };
            hyprland = {
              position = {
                x = 0;
                y = 1440;
              };
              # Avoid always-on VRR while troubleshooting DPMS wake crashes.
              vrr = 2;
            };
            niri.focusAtStartup = true;
            workspaces = lib.range 2 9;
            bar = "fullSize";
            wallpaper = "secondary";
          }
        ];
        swayUnassignedWorkspaces = [ 9 ];
      };
      xdg = enabled;
    };

    roles = {
      desktop = enabled;
      developer = enabled;
      gamer = enabled;
    };

    suites = {
      development = {
        azureEnable = true;
        dotnetEnable = true;
        # FIXME: Keep this aligned with the system setting until Podman
        # Desktop's pnpm/Node build no longer makes rebuilds prohibitively slow.
        # dockerEnable = true;
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

  programs = {
    t3code.clientSettings = lib.mkIf config.programs.t3code.enable {
      loadBalancingWeights."9543d727-e5f3-416d-8b29-7b09efc9d529" = 100;
    };

    mcp.servers.filesystem.args = [
      config.home.homeDirectory
      "${config.home.homeDirectory}/Documents"
      "${config.home.homeDirectory}/khanelinix"
      "${config.home.homeDirectory}/Documents/github"
      "/nix/store"
    ];
  };

  # Lets the phone prefer a direct LAN route over Tailscale at home.
  khanelinix.programs.terminal.tools.t3code.lan = true;

  khanelinix.programs.terminal.tools.mcp.blender.enable = true;
  khanelinix.programs.terminal.tools.mcp.firefox.enable = true;
  khanelinix.programs.terminal.tools.mcp.freecad.enable = true;

  # Neo G9
  xresources.properties."Xft.dpi" = "108";

  home.stateVersion = "26.05";
}
