{
  config,
  lib,
  osConfig ? { },
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    ;

  cfg = config.khanelinix.programs.terminal.tools.opencode;
  ollamaEnabled =
    (config.services.ollama.enable or false) || (osConfig.services.ollama.enable or false);

  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib pkgs; };
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
      }
      // lib.optionalAttrs config.services.exo.enable {
        opencode-exo = ''f(){ model="$1"; shift; opencode --model "exo/$model" "$@"; }; f'';
        opencode-exo-coder = "opencode --model exo/mlx-community/Qwen3-Coder-Next-4bit";
        opencode-exo-gpt-oss = "opencode --model exo/mlx-community/gpt-oss-20b-MXFP4-Q8";
        opencode-exo-qwen = "opencode --model exo/mlx-community/Qwen3.6-35B-A3B-5bit";
      }
      // lib.optionalAttrs ollamaEnabled {
        opencode-ollama = ''f(){ model="$1"; shift; opencode --model "ollama/$model" "$@"; }; f'';
        opencode-ollama-agent = "opencode --model ollama/glm-4.7-flash";
        opencode-ollama-coder = "opencode --model ollama/qwen3-coder:30b";
        opencode-ollama-gpt-oss = "opencode --model ollama/gpt-oss:20b";
        opencode-ollama-qwen = "opencode --model ollama/qwen3.6:27b";
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
        inherit (aiTools.opencode) skills;

        context = builtins.readFile aiTools.base;
      };
  };
}
