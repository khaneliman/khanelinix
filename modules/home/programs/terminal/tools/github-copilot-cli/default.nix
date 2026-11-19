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
  lspCatalog = import (lib.getFile "modules/common/ai-tools/lsp-catalog.nix") {
    inherit lib pkgs;
    userName = config.khanelinix.user.name;
  };
  lspServers =
    lib.mapAttrs
      (
        _: server:
        removeAttrs server [ "extensions" ]
        // {
          fileExtensions = builtins.listToAttrs server.extensions;
        }
      )
      (
        lib.getAttrs [
          "basedpyright"
          "bashls"
          "clangd"
          "csharp"
          "emmylua-ls"
          "fish-lsp"
          "gopls"
          "jsonls"
          "marksman"
          "nixd"
          "ruff"
          "rust-analyzer"
          "taplo"
          "typescript"
          "yamlls"
        ] lspCatalog
      );
  posixTokenExports =
    lib.optionalString
      ((config.khanelinix.services.sops.enable or false) && config.sops.secrets ? "github/copilot-token")
      ''
        if [ -f ${config.sops.secrets."github/copilot-token".path} ]; then
          COPILOT_GITHUB_TOKEN="$(cat ${config.sops.secrets."github/copilot-token".path})"
          export COPILOT_GITHUB_TOKEN
        fi
      '';
  fishTokenExports =
    lib.optionalString
      ((config.khanelinix.services.sops.enable or false) && config.sops.secrets ? "github/copilot-token")
      /* fish */ ''
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
    home.shellAliases = {
      copilot-unsafe = "copilot --mode autopilot --yolo";
    };

    programs = {
      github-copilot-cli = {
        enable = true;
        mutableSettings = true;

        enableMcpIntegration = mkIf mcpModuleEnabled true;

        settings = {
          model = "gpt-6.2-sol";
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
        };

        inherit (aiTools.githubCopilotCli)
          agents
          context
          skills
          ;

        lspServers = lspServers // {
          clangd = removeAttrs lspServers.clangd [ "initializationOptions" ];
          gopls = lspServers.gopls // {
            fileExtensions = lib.mapAttrs (_: _: "go") lspServers.gopls.fileExtensions;
          };
          marksman = lspServers.marksman // {
            fileExtensions = {
              ".md" = "markdown";
              ".mdx" = "mdx";
            };
          };
        };
      };
      bash.initExtra = posixTokenExports;
      fish.shellInit = fishTokenExports;
      zsh.initContent = posixTokenExports;
    };

  };
}
