{ lib, ... }:

let
  aiCommands = import ./commands.nix { inherit lib; };
  aiAgents = import ./agents.nix { inherit lib; };

  convertCommandsToGemini =
    commands:
    lib.mapAttrs (name: prompt: {
      inherit prompt;
      description =
        let
          lines = lib.splitString "\n" prompt;
          descLine = lib.findFirst (line: lib.hasPrefix "description:" line) "" lines;
        in
        if descLine != "" then
          lib.removePrefix "description: " (lib.trim descLine)
        else
          "AI command: ${name}";
    }) commands;

  convertAgentsToGemini =
    agents:
    lib.mapAttrs (name: agent: {
      prompt = agent.content;
      description = agent.description or "AI agent: ${name}";
    }) agents;

in
{
  claudeCode = {
    commands = aiCommands;
    agents = aiAgents.toClaudeMarkdown;
  };

  geminiCli = {
    commands = convertCommandsToGemini aiCommands;
    agents = convertAgentsToGemini aiAgents.agents;
  };

  opencode = {
    commands = aiCommands;
    inherit (aiAgents) agents;
    renderAgents = aiAgents.toOpenCodeMarkdown;
  };

  mergeCommands = existingCommands: newCommands: existingCommands // newCommands;
}
