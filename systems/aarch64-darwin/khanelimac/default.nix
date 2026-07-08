{
  config,
  lib,
  ...
}:
let
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.user;
  hosts = import (lib.getFile "modules/common/programs/terminal/tools/ssh/hosts.nix");
  hostUserPublicKeys = lib.mapAttrsToList (_: host: host.userPublicKey) (
    lib.filterAttrs (_: host: host ? userPublicKey) hosts
  );
in
{
  khanelinix = {
    archetypes = {
      personal = enabled;
      workstation = enabled;
    };

    environments = {
      home-network = enabled;
    };

    nix = {
      enable = true;
      nix-rosetta-builder = {
        enable = true;
        cores = 4;
      };
      # useLix = true;
    };

    security = {
      sudo = enabled;
      sops = {
        enable = true;
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        defaultSopsFile = lib.getFile "secrets/khanelimac/default.yaml";
      };
    };

    services = {
      lumen = {
        enable = true;

        instances = {
          # Physical-display stream. Reuses the original config dir so existing
          # Moonlight pairings keep working.
          # Web UI: https://localhost:47990 (default base port 47989 + 1).
          desktop = {
            configDir = "/Users/khaneliman/.config/sunshine";
            virtualDisplay = false;
            sunshineName = "khanelimac";
            settings = {
              av1_mode = 1;
              hevc_mode = 0;
              max_bitrate = 0;
              vt_realtime = "enabled";
            };

            apps = [
              { name = "Desktop"; }
              {
                name = "Steam";
                detached = [ "/usr/bin/open -a Steam" ];
                "prep-cmd" = [
                  {
                    do = "";
                    undo = "/usr/bin/osascript -e 'tell application \"Steam\" to quit'";
                  }
                ];
              }
              {
                name = "Battle.net";
                detached = [ "/usr/bin/open -a 'Battle.net'" ];
                "prep-cmd" = [
                  {
                    do = "";
                    undo = "/usr/bin/osascript -e 'tell application \"Battle.net\" to quit'";
                  }
                ];
              }
              {
                name = "Roblox";
                detached = [ "/usr/bin/open -a Roblox" ];
                "prep-cmd" = [
                  {
                    do = "";
                    undo = "/usr/bin/osascript -e 'tell application \"Roblox\" to quit'";
                  }
                ];
              }
            ];
          };
        };
      };
      tailscale = enabled;
    };

    suites = {
      art = enabled;
      common = enabled;
      desktop = enabled;
      development = {
        enable = true;

        aiEnable = true;
      };
      games = enabled;
      music = enabled;
      networking = enabled;
      social = enabled;
      video = enabled;
      vm = enabled;
    };

    system.logging = enabled;

    tools.homebrew.masEnable = true;
  };

  services.karabiner-elements.enable = true;

  networking = {
    computerName = "Austins MacBook Pro";
    hostName = "khanelimac";
    localHostName = "khanelimac";

    knownNetworkServices = [
      "ThinkPad TBT 3 Dock"
      "Wi-Fi"
      "Thunderbolt Bridge"
    ];
  };

  nix.settings = {
    cores = 0;
    max-jobs = 5;
  };

  users.users.${cfg.name} = {
    openssh = {
      authorizedKeys.keys = hostUserPublicKeys ++ [
        # `austinserver hermes`
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG1MjYs1zQ6dxFyNwUTR/1K0QI65nuJ6h1xINWnQEUdy hermes-agent@austinserver"
      ];
    };
  };

  system = {
    primaryUser = "khaneliman";
    stateVersion = 7;
  };
}
