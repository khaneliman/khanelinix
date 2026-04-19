{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkDefault mkIf mkEnableOption;

  cfg = config.khanelinix.programs.terminal.tools.opencode;

  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib; };
in
{
  imports = [
    ./formatters.nix
    ./lsp.nix
    ./permission.nix
    ./provider.nix
  ];

  options.khanelinix.programs.terminal.tools.opencode = {
    enable = mkEnableOption "OpenCode configuration";
  };

  config = mkIf cfg.enable {
    home.shellAliases = {
      opencode-coding = "opencode --model openai/gpt-5.3-codex-spark";
      opencode-deep = "opencode --model openai/gpt-5.4";
      opencode-nano = "opencode --model openai/gpt-5.4-nano";
      opencode-research = "opencode --agent refactorer";
    };

    programs.opencode = {
      enable = true;

      enableMcpIntegration =
        let
          mcpModuleEnabled = config.khanelinix.programs.terminal.tools.mcp.enable or false;
        in
        mkIf mcpModuleEnabled true;

      settings = {
        model = "openai/gpt-5.4";
        share = "manual";
        autoupdate = false;
        small_model = "openai/gpt-5.3-codex-spark";
        default_agent = "refactorer";
        compaction = {
          auto = true;
          prune = true;
          reserved = 20000;
        };
        command = {
          quick = {
            template = "Make fast, minimal edits and keep responses concise.";
            model = "openai/gpt-5.3-codex-spark";
            agent = "refactorer";
            subtask = true;
          };
          research = {
            template = "Do deliberate analysis before edits, include caveats and verification steps.";
            model = "openai/gpt-5.4";
            agent = "refactorer";
          };
          nano = {
            template = "Keep each action minimal and targeted for small-surface modifications.";
            model = "openai/gpt-5.4-nano";
            agent = "refactorer";
            subtask = true;
          };
        };

        plugin = [
          # Support google account auth
          "opencode-gemini-auth@latest"
          # Dynamic context pruning
          "@tarquinen/opencode-dcp@latest"
          # Support background shell commands
          "opencode-pty@latest"
          #
          "oh-my-openagent@latest"
        ];
      };

      tui = {
        theme = mkDefault "opencode";
      };

      inherit (aiTools.opencode) commands;
      agents = aiTools.opencode.renderAgents;
      skills = lib.getFile "modules/common/ai-tools/skills";

      context = builtins.readFile (lib.getFile "modules/common/ai-tools/base.md");
    };
  };
}
