{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkForce;
  inherit (lib.${namespace}) enabled;
in
{
  khanelinix = {
    user = {
      enable = true;
      name = "nixos";
    };

    programs = {
      graphical = {
        editors = {
          # TODO: WSL warns preferring windows VS Code with remote dev
          vscode.enable = false;
        };
      };
      terminal = {
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
            wslGitCredentialManagerPath = ''/mnt/c/Users/au09163/AppData/Local/Programs/Git/mingw64/bin/git-credential-manager.exe'';
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
        # enable = true;
        defaultSopsFile = lib.khanelinix.getFile "secrets/CORE/nixos/default.yaml";
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
      };
    };

    theme.catppuccin = enabled;
  };

  home.stateVersion = "25.05";
}
