{
  config,
  lib,
  root,
  flake,
  ...
}:
let
  inherit (lib) mkForce;
  inherit (flake.inputs.self.lib.khanelinix) enabled disabled;
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
          thunderbird = {
            enable = true;
            extraAccounts =
              let
                # Not super secret, just doesn't need to be scraped so easily.
                outlook = flake.inputs.self.lib.khanelinix.decode "a2hhbmVsaW1hbjEyQG91dGxvb2suY29t";
                personal = flake.inputs.self.lib.khanelinix.decode "YXVzdGluLm0uaG9yc3RtYW5AZ21haWwuY29t";

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
        };

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
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEilFPAgSUwW3N7PTvdTqjaV2MD3cY2oZGKdaS7ndKB"
            ];
          };
        };
      };
    };

    services = {
      sops = {
        enable = true;
        defaultSopsFile = root + "/secrets/khanelimac/khaneliman/default.yaml";
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
      networking = enabled;
      photo = enabled;
      social = enabled;
    };

    theme.catppuccin = enabled;
  };

  home.stateVersion = "24.11";
}
