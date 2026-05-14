{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;

  cfg = config.khanelinix.programs.terminal.tools.github-copilot-cli;

  mcpModuleEnabled = config.khanelinix.programs.terminal.tools.mcp.enable or false;
  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib; };
  posixTokenExports = lib.optionalString (config.khanelinix.services.sops.enable or false) ''
    if [ -f ${config.sops.secrets."github/copilot-token".path} ]; then
      COPILOT_GITHUB_TOKEN="$(cat ${config.sops.secrets."github/copilot-token".path})"
      export COPILOT_GITHUB_TOKEN
    fi
  '';
  fishTokenExports = lib.optionalString (config.khanelinix.services.sops.enable or false) /* fish */ ''
    if test -f ${config.sops.secrets."github/copilot-token".path}
      set -gx COPILOT_GITHUB_TOKEN (cat ${config.sops.secrets."github/copilot-token".path})
    end
  '';
in
{
  options.khanelinix.programs.terminal.tools.github-copilot-cli = {
    enable = mkEnableOption "GitHub Copilot CLI configuration";
  };

  config = mkIf cfg.enable {
    programs = {
      github-copilot-cli = {
        enable = true;

        enableMcpIntegration = mkIf mcpModuleEnabled true;

        settings = {
          model = "gpt-5.4";
          effortLevel = "high";
          theme = "dark";
          banner = "once";
          renderMarkdown = true;
          autoUpdate = false;
          includeCoAuthoredBy = false;
          respectGitignore = true;
          enabledFeatureFlags = {
            QUEUED_COMMANDS = true;
          };

          trusted_folders =
            let
              documentsPath =
                if config.xdg.userDirs.enable then
                  config.xdg.userDirs.documents
                else
                  config.home.homeDirectory + lib.optionalString pkgs.stdenv.hostPlatform.isLinux "/Documents";

              trustedGithubProjects = [
                "home-manager"
                "khanelivim"
                "nixpkgs"
                "nixvim"
                "waybar"
              ];
            in
            [
              "${config.home.homeDirectory}/khanelinix"
            ]
            ++ map (project: "${documentsPath}/github/${project}") trustedGithubProjects;
        };

        inherit (aiTools.githubCopilotCli)
          agents
          context
          skills
          ;

        lspServers = {
          nixd = {
            command = lib.getExe pkgs.nixd;
            fileExtensions = {
              ".nix" = "nix";
            };
            initializationOptions = {
              formatting.command = [ (lib.getExe pkgs.nixfmt) ];
            };
          };

          emmylua-ls = {
            command = lib.getExe pkgs.emmylua-ls;
            fileExtensions = {
              ".lua" = "lua";
            };
            initializationOptions.Lua = {
              diagnostics.globals = [
                "vim"
                "Sbar"
                "spoon"
              ];
              workspace.library = [
                "/nix/store/*/share/lua/5.1"
                "/etc/profiles/per-user/${config.khanelinix.user.name}/share/lua/5.1"
              ];
            };
          };

          basedpyright = {
            command = lib.getExe' pkgs.basedpyright "basedpyright-langserver";
            args = [ "--stdio" ];
            fileExtensions = {
              ".py" = "python";
              ".pyi" = "python";
              ".pyw" = "python";
            };
          };

          ruff = {
            command = lib.getExe pkgs.ruff;
            args = [ "server" ];
            fileExtensions = {
              ".py" = "python";
              ".pyi" = "python";
              ".pyw" = "python";
            };
          };

          bashls = {
            command = lib.getExe pkgs.bash-language-server;
            args = [ "start" ];
            fileExtensions = {
              ".bash" = "shellscript";
              ".sh" = "shellscript";
            };
          };

          clangd = {
            command = lib.getExe' pkgs.clang-tools "clangd";
            args = [
              "--background-index"
              "--clang-tidy"
              "--header-insertion=iwyu"
              "--completion-style=detailed"
              "--function-arg-placeholders"
              "--fallback-style=llvm"
            ];
            fileExtensions = {
              ".c" = "c";
              ".c++" = "cpp";
              ".cc" = "cpp";
              ".cpp" = "cpp";
              ".cxx" = "cpp";
              ".h" = "c";
              ".h++" = "cpp";
              ".hh" = "cpp";
              ".hpp" = "cpp";
              ".hxx" = "cpp";
            };
          };

          fish-lsp = {
            command = lib.getExe pkgs.fish-lsp;
            fileExtensions = {
              ".fish" = "fish";
            };
          };

          typescript = {
            command = lib.getExe pkgs.typescript-language-server;
            args = [ "--stdio" ];
            fileExtensions = {
              ".cjs" = "javascript";
              ".cts" = "typescript";
              ".js" = "javascript";
              ".jsx" = "javascriptreact";
              ".mjs" = "javascript";
              ".mts" = "typescript";
              ".ts" = "typescript";
              ".tsx" = "typescriptreact";
            };
          };

          gopls = {
            command = lib.getExe pkgs.gopls;
            fileExtensions = {
              ".go" = "go";
              ".mod" = "go";
              ".sum" = "go";
            };
          };

          rust-analyzer = {
            command = lib.getExe pkgs.rust-analyzer;
            fileExtensions = {
              ".rs" = "rust";
            };
          };

          csharp = {
            command = lib.getExe pkgs.roslyn-ls;
            fileExtensions = {
              ".cs" = "csharp";
              ".csx" = "csharp";
              ".cake" = "csharp";
            };
          };

          marksman = {
            command = lib.getExe pkgs.marksman;
            fileExtensions = {
              ".md" = "markdown";
              ".mdx" = "mdx";
            };
          };

          yamlls = {
            command = lib.getExe pkgs.yaml-language-server;
            args = [ "--stdio" ];
            fileExtensions = {
              ".yaml" = "yaml";
              ".yml" = "yaml";
            };
          };

          jsonls = {
            command = lib.getExe' pkgs.vscode-langservers-extracted "vscode-json-language-server";
            args = [ "--stdio" ];
            fileExtensions = {
              ".json" = "json";
              ".jsonc" = "jsonc";
            };
          };

          taplo = {
            command = lib.getExe pkgs.taplo;
            args = [
              "lsp"
              "stdio"
            ];
            fileExtensions = {
              ".toml" = "toml";
            };
          };
        };
      };
      bash.initExtra = posixTokenExports;
      fish.shellInit = fishTokenExports;
      zsh.initContent = posixTokenExports;
    };

    sops.secrets = lib.mkIf (config.khanelinix.services.sops.enable or false) {
      "github/copilot-token" = {
        sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/.config/copilot/token";
      };
    };
  };
}
