{
  lib,

  ...
}:
let
  inherit (lib.khanelinix) enabled disabled;
in
{
  khanelinix = {
    user = {
      enable = true;
      name = "bruddy";
    };

    environments = {
      home-network = enabled;
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

        desktop-environment.gnome = {
          enable = true;
          shell.favorite-apps = [
            "org.gnome.Nautilus.desktop"
            "org.gnome.Console.desktop"
            "firefox-devedition.desktop"
            "steam.desktop"
            "org.vinegarhq.Sober.desktop"
          ];
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
          jujutsu.enable = false;
          topgrade.enable = false;

          git = {
            enable = true;
          };

          run-as-service = enabled;
          ssh = enabled;
        };
      };
    };

    services = {
      # sops = {
      #   enable = true;
      #   defaultSopsFile = lib.getFile "secrets/khanelinix/khaneliman/default.yaml";
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

    theme = {
      catppuccin = enabled;
      stylix = enabled;
    };
  };

  home.stateVersion = "25.11";
}
