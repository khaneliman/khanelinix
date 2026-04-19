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
    ./oh-my-openagent.nix
    ./permission.nix
    ./provider.nix
  ];

  options.khanelinix.programs.terminal.tools.opencode = {
    enable = mkEnableOption "OpenCode configuration";
  };

  config = mkIf cfg.enable {
    home.shellAliases =
      let
        refactorerModel = aiTools.agents.refactorer.model.opencode;
      in
      {
        opencode-coding = "opencode --model openai/gpt-5.3-codex-spark";
        opencode-deep = "opencode --model ${refactorerModel}";
        opencode-nano = "opencode --model openai/gpt-5.4-nano";
        opencode-research = "opencode --agent refactorer";
      };

    programs.opencode =
      let
        aiToolAgents = import (lib.getFile "modules/common/ai-tools/agents.nix") { inherit lib; };
        aiToolCommands = import (lib.getFile "modules/common/ai-tools/commands.nix") { inherit lib; };
        refactorerModel = aiTools.agents.refactorer.model.opencode;
      in
      {
        enable = true;

        enableMcpIntegration =
          let
            mcpModuleEnabled = config.khanelinix.programs.terminal.tools.mcp.enable or false;
          in
          mkIf mcpModuleEnabled true;

        settings = {
          model = refactorerModel;
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
              model = refactorerModel;
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
            # Support background shell commands
            "opencode-pty@latest"
            # Enhanced agent orchestration and plugin workflow
            "oh-my-openagent@latest"
          ];
        };

        tui = {
          theme = mkDefault "opencode";
        };

        commands = lib.mapAttrs (
          _: command: aiToolCommands.renderOpenCodeMarkdown command
        ) aiTools.commands;
        agents = lib.mapAttrs (_: agent: aiToolAgents.renderOpenCodeAgent agent) aiTools.agents;
        skills = aiTools.skillsDir;

        context = builtins.readFile aiTools.base;
      };
  };
}
