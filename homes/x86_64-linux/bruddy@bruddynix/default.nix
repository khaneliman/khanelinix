{
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) enabled disabled;
in
{
  khanelinix = {
    user = {
      enable = true;
      name = "bruddy";
    };

    programs = {
      graphical = {
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
      };

      terminal = {
        # No need for all these on his computer
        emulators = {
          alacritty.enable = false;
          kitty.enable = false;
          wezterm.enable = false;
        };

        media = {
          ncmpcpp = disabled;
        };

        shell.nushell.enable = false;

        tools = {
          # No need for all these on his computer
          carapace.enable = false;
          fup-repl.enable = false;
          jujutsu.enable = false;
          topgrade.enable = false;

          git = {
            enable = true;
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
      mpd = {
        musicDirectory = "nfs://austinserver.local/mnt/user/data/media/music";
      };

      # sops = {
      #   enable = true;
      #   defaultSopsFile = lib.snowfall.fs.get-file "secrets/khanelinix/khaneliman/default.yaml";
      #   sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      # };
    };

    system = {
      xdg = enabled;
    };

    suites = {
      common = enabled;
      desktop = enabled;

      development = {
        enable = true;

        gameEnable = true;
        nixEnable = true;
      };

      emulation = enabled;
      games = enabled;
      networking = enabled;
    };

    theme.catppuccin = enabled;
  };

  home.stateVersion = "24.11";
}
