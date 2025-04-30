{
  config,
  lib,
  namespace,
  ...
}:
let
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
          thunderbird =
            let
              # Not super secret, just doesn't need to be scraped so easily.
              outlook = lib.${namespace}.decode "a2hhbmVsaW1hbjEyQG91dGxvb2suY29t";
              personal = lib.${namespace}.decode "YXVzdGluLm0uaG9yc3RtYW5AZ21haWwuY29t";
            in
            {
              accountsOrder = [
                "khaneliman12@gmail.com"
                personal
                outlook
              ];
              extraAccounts = {
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
      };

      terminal = {
        tools = {
          ssh = {
            enable = true;
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

        aiEnable = true;
        dockerEnable = true;
        gameEnable = true;
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
