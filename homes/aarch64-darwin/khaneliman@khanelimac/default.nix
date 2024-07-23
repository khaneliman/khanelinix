{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkForce;
  inherit (lib.${namespace}) enabled disabled;
in
{
  khanelinix = {
    user = {
      enable = true;
      inherit (config.snowfallorg.user) name;
    };

    programs = {
      graphical = {
        bars = {
          sketchybar = enabled;
        };

        browsers = {
          firefox = {
            hardwareDecoding = true;
            settings = {
              "dom.ipc.processCount.webIsolated" = 9;
              "dom.maxHardwareConcurrency" = 16;
              "media.av1.enabled" = false;
              "media.ffvpx.enabled" = false;
              "media.hardware-video-decoding.force-enabled" = true;
              "media.hardwaremediakeys.enabled" = true;
              "media.navigator.mediadatadecoder_vpx_enabled" = true;
              "media.rdd-vpx.enabled" = false;
            };
          };
        };

        editors = {
          vscode = mkForce disabled;
        };
      };

      terminal = {
        tools = {
          ssh = {
            enable = true;

            authorizedKeys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpfTVxQKmkAYOrsnroZoTk0LewcBIC4OjlsoJY6QbB0"
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM7UBwfd7+K0mdkAIb2TE6RzMu6L4wZnG/anuoYqJMPB"
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFuMXeT21L3wnxnuzl0rKuE5+8inPSi8ca/Y3ll4s9pC"
            ];
          };
        };
      };
    };

    services = {
      sops = {
        enable = true;
        defaultSopsFile = lib.snowfall.fs.get-file "secrets/khanelimac/khaneliman/default.yaml";
        sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      };
    };

    suites = {
      business = enabled;
      common = enabled;
      desktop = enabled;
      development = {
        enable = true;

        nixEnable = true;
      };
      music = enabled;
      photo = enabled;
      social = enabled;
    };

    theme.catppuccin = enabled;
  };

  home.stateVersion = "21.11";
}
