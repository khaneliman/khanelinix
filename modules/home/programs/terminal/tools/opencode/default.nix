{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption mapAttrs;

  cfg = config.khanelinix.programs.terminal.tools.opencode;

  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib; };
  agentConfigLib = import ./agent-config.nix { inherit lib; };

  # Build OpenCode agent configurations from raw agent data
  buildAgentConfigs =
    agents:
    mapAttrs (
      name: agentText:
      let
        description = aiTools.opencode.extractDescription agentText;
        prompt = aiTools.opencode.extractPrompt agentText;
        config = agentConfigLib.generateAgentConfig name;
      in
      config
      // {
        inherit prompt;
        description = if description != null then description else "AI agent: ${name}";
      }
    ) agents;
in
{
  imports = [
    ./formatters.nix
    ./lsp.nix
    ./mcp.nix
    ./permission.nix
    ./provider.nix
  ];

  options.khanelinix.programs.terminal.tools.opencode = {
    enable = mkEnableOption "OpenCode configuration";
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;

      settings = {
        theme = "opencode";
        model = "anthropic/claude-sonnet-4-5";
        autoshare = false;
        autoupdate = false;

        # Agent configurations with model, tools, and permissions
        agent = buildAgentConfigs aiTools.opencode.agents;
      };

      inherit (aiTools.opencode) agents commands;

      rules = builtins.readFile (lib.getFile "modules/common/ai-tools/base.md");
    };
  };
}
