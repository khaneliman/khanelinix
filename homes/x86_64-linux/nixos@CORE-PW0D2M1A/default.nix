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

        editors = {
          neovim = {
            enable = true;
            extraModules = [
              {
                config = {
                  plugins = {
                    # NOTE: Disabling some plugins I won't need on work devices
                    avante.enable = mkForce false;
                    windsurf-nvim.enable = mkForce false;
                    firenvim.enable = mkForce false;
                    neorg.enable = mkForce false;
                  };
                };
              }
            ];
          };
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
