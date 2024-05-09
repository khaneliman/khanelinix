{ config, lib, ... }:
let
  inherit (lib) mkForce;
  inherit (lib.internal) enabled disabled;
in
{
  khanelinix = {
    user = {
      enable = true;
      inherit (config.snowfallorg.user) name;
    };

    programs = {
      graphical = {
        editors = {
          vscode = mkForce disabled;
        };
      };

      terminal = {
        emulators = {
          wezterm = mkForce disabled;
        };

        tools = {
          git = {
            enable = true;
            wslAgentBridge = true;
            wslGitCredentialManagerPath = ''/mnt/c/Users/Austin.Horstman/AppData/Local/Programs/Git/mingw64/bin/git-credential-manager.exe'';
            includes = [
              {
                condition = "gitdir:/mnt/c/";
                path = "${./git/windows-compat-config}";
              }
              {
                condition = "gitdir:/mnt/c/source/repos/DiB/";
                path = "${./git/dib-signing}";
              }
            ];
          };

          home-manager = enabled;
          k9s = enabled;
          ssh = enabled;
        };
      };
    };

    services = {
      sops = {
        enable = true;
        defaultSopsFile = ../../../secrets/CORE/nixos/default.yaml;
        sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      };
    };

    system = {
      xdg = enabled;
    };

    suites = {
      common = enabled;
      development = {
        enable = true;
        dockerEnable = true;
      };
    };
  };

  sops.secrets.kubernetes = {
    path = "${config.home.homeDirectory}/.kube/config";
  };

  home.stateVersion = "23.11";
}
