{
  config,
  lib,
  namespace,
  osConfig,
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

          ssh = enabled;
        };
      };
    };

    services = {
      sops = {
        enable = true;
        defaultSopsFile = lib.snowfall.fs.get-file "secrets/CORE/nixos/default.yaml";
        sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      };
    };

    system = {
      xdg = enabled;
    };

    suites = {
      business = enabled;
      common = enabled;
      development = {
        enable = true;
        dockerEnable = true;
        kubernetesEnable = true;
      };
    };

    theme.catppuccin = enabled;
  };

  sops.secrets = lib.mkIf osConfig.${namespace}.security.sops.enable {
    kubernetes = {
      path = "${config.home.homeDirectory}/.kube/config";
    };
  };

  home.stateVersion = "23.11";
}
