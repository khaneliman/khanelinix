{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkForce;
  inherit (lib.khanelinix) enabled;
in
{
  khanelinix = {
    user = {
      enable = true;
      name = "khaneliman";
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
                    neotest.enable = mkForce false;
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
            wslGitCredentialManagerPath = ''/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe'';
            includes = [
              {
                condition = "gitdir:/mnt/c/";
                path = "${./git/windows-compat-config}";
              }
            ];
          };
          gh = {
            gitCredentialHelper.hosts = [
              "https://core-bts-02@dev.azure.com"
              "https://github.com/SECURAInsurance"
            ];
          };

          ssh = enabled;
        };
      };
    };

    services = {
      sops = {
        # enable = true;
        defaultSopsFile = lib.getFile "secrets/CORE/nixos/default.yaml";
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
        aiEnable = true;
      };
    };

    theme.catppuccin = enabled;
  };

  home.stateVersion = "25.05";
}
