{
  config,
  inputs,
  lib,
  system,
  pkgs,
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
                  # Disable heavy language servers not needed for work
                  lsp.servers = {
                    rust_analyzer.enable = mkForce false;
                    clangd.enable = mkForce false;
                  };

                  plugins = {
                    # NOTE: Disabling some plugins I won't need on work devices
                    avante.enable = mkForce false;
                    clangd-extensions.enable = mkForce false;
                    conform-nvim.settings.formatters = mkForce {
                      csharpier.command = lib.getExe pkgs.csharpier;
                      nixfmt.command = lib.getExe pkgs.nixfmt;
                    };
                    dap-go.enable = mkForce false;
                    dap-python.enable = mkForce false;
                    dap-ui.enable = mkForce false;
                    dap-virtual-text.enable = mkForce false;
                    dap.enable = mkForce false;
                    firenvim.enable = mkForce false;
                    lint.linters = {
                      clangtidy.cmd = mkForce null;
                      clippy.cmd = mkForce null;
                    };
                    neorg.enable = mkForce false;
                    neotest.enable = mkForce false;
                    windsurf-nvim.enable = mkForce false;
                    rustaceanvim.enable = mkForce false;
                    treesitter.grammarPackages = mkForce (
                      let
                        khanelivimConfig = inputs.khanelivim.nixvimConfigurations.${system}.khanelivim.config;

                        wslIncludedGrammars = [
                          "bash-grammar"
                          "c_sharp-grammar"
                          "diff-grammar"
                          "gitcommit-grammar"
                          "gitignore-grammar"
                          "javascript-grammar"
                          "json-grammar"
                          "markdown-grammar"
                          "nix-grammar"
                          "python-grammar"
                          "regex-grammar"
                          "typescript-grammar"
                          "yaml-grammar"
                        ];
                      in
                      lib.filter (
                        g: lib.elem g.pname wslIncludedGrammars
                      ) khanelivimConfig.plugins.treesitter.package.passthru.allGrammars
                    );
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

  programs = {
    opencode.settings = {
      lsp = {
        clangd.command = mkForce [ ];
        rust-analyzer.command = mkForce [ ];
      };
      formatter = mkForce {
        nixfmt.command = [ (lib.getExe pkgs.nixfmt) ];
        csharpier.command = [ (lib.getExe pkgs.csharpier) ];
      };
    };

    bat.extraPackages = mkForce (
      with pkgs.bat-extras;
      [
        batdiff
        batgrep
        batman
        batpipe
        batwatch
        # prettybat excluded - saves ~12GB in Rust/Clang toolchains
      ]
    );
  };

  home.stateVersion = "25.05";
}
