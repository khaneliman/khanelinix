{ lib, ... }:

let
  aiCommands = import ./commands.nix { inherit lib; };
  aiAgents = import ./agents.nix { inherit lib; };

  convertAgentsToGemini =
    agents:
    lib.mapAttrs (name: agent: {
      prompt = agent.content;
      description = agent.description or "AI agent: ${name}";
    }) agents;

in
{
  claudeCode = {
    commands = aiCommands.toClaudeMarkdown;
    agents = aiAgents.toClaudeMarkdown;
  };

  geminiCli = {
    commands = aiCommands.toGeminiCommands;
    agents = convertAgentsToGemini aiAgents.agents;
  };

  opencode = {
    commands = aiCommands.toOpenCodeMarkdown;
    inherit (aiAgents) agents;
    renderAgents = aiAgents.toOpenCodeMarkdown;
  };

  mergeCommands = existingCommands: newCommands: existingCommands // newCommands;
}
