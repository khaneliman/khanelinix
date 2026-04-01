{
  config,
  lib,

  ...
}:
let
  inherit (lib.khanelinix) enabled;
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
        apps = {
          thunderbird =
            let
              # Not super secret, just doesn't need to be scraped so easily.
              outlook = lib.khanelinix.decode "a2hhbmVsaW1hbjEyQG91dGxvb2suY29t";
              personal = lib.khanelinix.decode "YXVzdGluLm0uaG9yc3RtYW5AZ21haWwuY29t";
            in
            {
              accountsOrder = [
                "khaneliman12@gmail.com"
                personal
                outlook
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
              };
            };
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
          ssh = enabled;
          tmux = enabled;
        };
      };
    };

    services = {
      sops = {
        enable = true;
        defaultSopsFile = lib.getFile "secrets/khanelimac/khaneliman/default.yaml";
        sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      };
    };

    roles = {
      desktop = enabled;
      developer = enabled;
      creator = enabled;
    };

    suites.development = {
      dockerEnable = true;
      gameEnable = true;
    };

    theme.tokyonight = enabled;
  };

  programs.mcp.servers.filesystem.args = [
    config.home.homeDirectory
    "${config.home.homeDirectory}/Documents"
    "${config.home.homeDirectory}/khanelinix"
    "${config.home.homeDirectory}/github"
    "/nix/store"
  ];

  sops.secrets = lib.mkIf config.khanelinix.services.sops.enable {
    nix = {
      sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
      path = "${config.home.homeDirectory}/.config/nix/nix.conf";
    };
  };

  home.stateVersion = "25.11";
}
