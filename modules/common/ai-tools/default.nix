{ lib, ... }:

let
  aiCommands = import ./commands.nix { inherit lib; };
  aiAgents = import ./agents.nix { inherit lib; };
  base = ./base.md;
  skillsDir = ./skills;
  skills = lib.mapAttrs (name: _: skillsDir + "/${name}") (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir skillsDir)
  );

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
    inherit skillsDir;
  };

  geminiCli = {
    commands = aiCommands.toGeminiCommands;
    agents = convertAgentsToGemini aiAgents.agents;
    inherit skills;
  };

  codex = {
    inherit skillsDir;
  };

  opencode = {
    commands = aiCommands.toOpenCodeMarkdown;
    inherit (aiAgents) agents;
    renderAgents = aiAgents.toOpenCodeMarkdown;
  };

  inherit base skills skillsDir;

  mergeCommands = existingCommands: newCommands: existingCommands // newCommands;
}
